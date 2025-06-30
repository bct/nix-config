{ self, config, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "25.05";

  microvm = {
    vcpu = 1;
    mem = 1024;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-books--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "books" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.calibre-web = {
    enable = true;
    openFirewall = false;
  };

  services.caddy = {
    enable = true;
    virtualHosts."books.domus.diffeq.com" = {
      useACMEHost = "books.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.calibre-web.listen.port}";
    };
  };
}
