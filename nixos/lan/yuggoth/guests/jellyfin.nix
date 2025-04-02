{ self, config, lib, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 4;
    mem = 8192;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-jellyfin--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.domus.diffeq.com" = {
      useACMEHost = "jellyfin.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:8096";
    };
  };

  fileSystems."/mnt/video" = {
    device = "//mi-go.domus.diffeq.com/video";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},ro,cifsacl,uid=${config.services.jellyfin.user},credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"];
  };

  age.secrets = {
    fs-mi-go-torrent-scraper = {
      # username: torrent-scraper
      rekeyFile = ../../../../secrets/fs/mi-go-torrent-scraper.age;
    };
  };
}
