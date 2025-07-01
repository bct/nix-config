{ self, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "25.05";

  microvm = {
    vcpu = 1;
    mem = 1536;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-bookmarks--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "bookmarks" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.karakeep = {
    enable = true;
    extraEnvironment = {
      NEXTAUTH_URL = "https://bookmarks.domus.diffeq.com/";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."bookmarks.domus.diffeq.com" = {
      useACMEHost = "bookmarks.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:3000";
    };
  };
}
