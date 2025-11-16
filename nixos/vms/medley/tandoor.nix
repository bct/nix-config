{ config, ... }: {
  services.tandoor-recipes = {
    enable = true;
    extraConfig = {
      # https://docs.tandoor.dev/system/configuration/#gunicorn-media
      GUNICORN_MEDIA = "1";
    };
  };

  # ExecStartPre often hits the default 90s timeout
  systemd.services.tandoor-recipes.serviceConfig.TimeoutStartSec = 180;

  services.caddy = {
    enable = true;
    virtualHosts."recipes.domus.diffeq.com" = {
      useACMEHost = "recipes.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.tandoor-recipes.port}";
    };
  };
}
