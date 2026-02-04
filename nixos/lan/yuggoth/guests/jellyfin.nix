{ self, config, ... }:
let
  jellyfinPort = 8096;
in
{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
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

    devices = [
      # # sudo lshw -C display
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.0";
      #   #path = "vendorid=0x1002,productid=0x15d8";
      # }
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.1";
      # }
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.6";
      # }
    ];
  };

  age.secrets = {
    fs-mi-go-torrent-scraper = {
      # username: torrent-scraper
      rekeyFile = config.diffeq.secretsPath + /fs/mi-go-torrent-scraper.age;
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      "jellyfin"
      "seerr"
    ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  networking.firewall.interfaces."wt0".allowedTCPPorts = [
    jellyfinPort
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = false;
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = false;
  };

  services.caddy = {
    enable = true;
    virtualHosts."jellyfin.domus.diffeq.com" = {
      useACMEHost = "jellyfin.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString jellyfinPort}";
    };
    virtualHosts."seerr.domus.diffeq.com" = {
      useACMEHost = "seerr.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.jellyseerr.port}";
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
        "${automount_opts},ro,cifsacl,uid=${config.services.jellyfin.user},credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"
      ];
  };

  services.netbird.clients.default = {
    port = 51820;
    name = "netbird";
    interface = "wt0";
    hardened = true;
  };
}
