{ self, config, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 2;
    mem = 4096;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-immich--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  age.secrets = {
    fs-mi-go-immich = {
      rekeyFile = ../../../../secrets/fs/mi-go-immich.age;
    };

    immich-env = {
      rekeyFile = ./secrets/immich-env.age;
      owner = config.services.immich.user;
      group = config.services.immich.group;
    };

    lego-proxy-immich = {
      generator.script = "ssh-ed25519-pubkey";
      rekeyFile = ../../../../secrets/lego-proxy/immich.age;
      owner = "acme";
      group = "acme";
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "immich.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-immich.path; }
    ];
    group = "caddy";
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  fileSystems."/mnt/photos" = {
    device = "//mi-go.domus.diffeq.com/photos";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},cifsacl,uid=${config.services.immich.user},credentials=${config.age.secrets.fs-mi-go-immich.path}"];
  };

  services.immich = {
    enable = true;
    package = pkgs.immich;

    host = "127.0.0.1";

    mediaLocation = "/mnt/photos/immich";
    secretsFile = config.age.secrets.immich-env.path;

    database = {
      # use a remote postgres server
      enable = false;
      host = "db.domus.diffeq.com";
      port = 5432;
      user = "immich";
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];

  services.caddy = {
    enable = true;
    virtualHosts."immich.domus.diffeq.com" = {
      useACMEHost = "immich.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.immich.port}";
    };
  };
}
