{ self, config, ... }:
let
  jellyfinPort = 8096;
in
{
  # this is a container rather than a VM because it makes it easy to share the host's GPU.

  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  age.secrets = {
    # TODO: have this use a separate SMB user?
    fs-mi-go-torrent-scraper = {
      # username: torrent-scraper
      rekeyFile = config.diffeq.secretsPath + /fs/mi-go-torrent-scraper.age;
    };
  };

  fileSystems."/mnt/video" = {
    device = "//mi-go.domus.diffeq.com/video";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

        # the defaults of a CIFS mount are not documented anywhere that I can see.
        # you can run "mount" after mounting to see what options were actually used.
        # cifsacl is required for the server-side permissions to show up correctly.
      in
      [
        "${automount_opts},ro,cifsacl,credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"
      ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "jellyfin" ];
    group = "caddy";
  };
  #
  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.domus.diffeq.com" = {
      useACMEHost = "jellyfin.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString jellyfinPort}";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  systemd.services."container@jellyfin".requires = [
    "microvm@db.service"
    "microvm@lego-proxy.service"
  ];

  containers.jellyfin = {
    autoStart = true;

    # user namespacing is enabled and the UID/GID range is automatically chosen, so that
    # no overlapping UID/GID ranges are assigned to multiple containers.
    privateUsers = "pick";

    allowedDevices = [
      {
        node = "/dev/dri/renderD128";
        modifier = "rw";
      }
    ];

    bindMounts = {
      "/dev/dri/renderD128" = {
        hostPath = "/dev/dri/renderD128";
        isReadOnly = false;
      };

      "/mnt/video" = {
        hostPath = "/mnt/video";
        isReadOnly = true;
      };
    };

    config =
      { ... }:
      {
        system.stateVersion = "25.11";

        hardware.graphics.enable = true;

        services.jellyfin = {
          enable = true;
          openFirewall = false;
        };
      };
  };
}
