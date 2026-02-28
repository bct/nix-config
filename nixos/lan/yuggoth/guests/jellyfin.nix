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

  # hardware.enableRedistributableFirmware = true;
  # hardware.graphics = {
  #   enable = true;
  # };

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
      # give the GPU to jellyfin for efficient transcoding.
      # GPU identified with: sudo lshw -C display

      # # we need to pass through everything in IOMMU Group 1
      # # as determined by https://github.com/neg-serg/ls-iommu
      # # VGA compatible controller [0300] Advanced Micro Devices, Inc. [AMD/ATI] Picasso/Raven 2 [Radeon Vega Series / Radeon Vega Mobile Series] [1002:15d8] (rev da)
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.0";
      # }
      # # Audio device [0403] Advanced Micro Devices, Inc. [AMD/ATI] Raven/Raven2/Fenghuang HDMI/DP Audio Controller [1002:15de]
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.1";
      # }
      # # Encryption controller [1080] Advanced Micro Devices, Inc. [AMD] Raven/Raven2/FireFlight/Renoir/Cezanne Platform Security Processor [1022:15df]
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.2";
      # }
      # # USB controller [0c03] Advanced Micro Devices, Inc. [AMD] Raven USB 3.1 [1022:15e0]
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.3";
      # }
      # # USB controller [0c03] Advanced Micro Devices, Inc. [AMD] Raven USB 3.1 [1022:15e1]
      # {
      #   bus = "pci";
      #   path = "0000:0b:00.4";
      # }
      # # Audio device [0403] Advanced Micro Devices, Inc. [AMD] Ryzen HD Audio Controller
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
