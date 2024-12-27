{ self, inputs, lib, config, pkgs, ... }:

let
  paperless-nixpkgs = inputs.nixpkgs-unstable;
in {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
    "${paperless-nixpkgs}/nixos/modules/services/misc/paperless.nix"
  ];

  disabledModules = [ "services/misc/paperless.nix" ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 2;
    mem = 2560;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  services.paperless = {
    enable = true;
    mediaDir = "/mnt/paperless/media";
    consumptionDir = "/mnt/paperless/consume";
    environmentFile = config.age.secrets.paperless-env.path;

    settings = {
      PAPERLESS_DBHOST = "db.domus.diffeq.com";
    };

    package = pkgs.paperless-ngx;
  };

  # can't have a private network if we need to talk to the database.
  systemd.services.paperless-consumer.serviceConfig.PrivateNetwork = lib.mkForce false;
  systemd.services.paperless-scheduler.serviceConfig.PrivateNetwork = lib.mkForce false;

  age.secrets = {
    fs-mi-go-paperless = {
      rekeyFile = ../../../../secrets/fs/mi-go-paperless.age;
    };

    lego-proxy-paperless = {
      generator.script = "ssh-ed25519-pubkey";
      rekeyFile = ../../../../secrets/lego-proxy/paperless.age;
      owner = "acme";
      group = "acme";
    };

    paperless-env = {
      rekeyFile = ./secrets/paperless-env.age;
      owner = config.services.paperless.user;
    };
  };

  fileSystems."/mnt/paperless" = {
    device = "//mi-go.domus.diffeq.com/paperless";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},cifsacl,uid=${config.services.paperless.user},credentials=${config.age.secrets.fs-mi-go-paperless.path}"];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "paperless.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-paperless.path; }
    ];
    group = "caddy";
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    virtualHosts."paperless.domus.diffeq.com" = {
      useACMEHost = "paperless.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.paperless.port}";
    };
  };
}
