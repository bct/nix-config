{ inputs, config, ... }:

{
  system.stateVersion = "24.11";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.tandoor-recipes = {
    enable = true;
    extraConfig = {
      # https://docs.tandoor.dev/system/configuration/#gunicorn-media
      GUNICORN_MEDIA = "1";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."recipes.domus.diffeq.com" = {
      useACMEHost = "recipes.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.tandoor-recipes.port}";
    };
  };
}
