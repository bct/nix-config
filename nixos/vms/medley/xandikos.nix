{ config, ... }:
{
  # caldav / carddav
  services.xandikos = {
    enable = true;
    port = 9898;
    extraOptions = [
      "--autocreate"
      "--defaults"
    ];
  };

  # TODO: auth
  services.caddy = {
    enable = true;
    virtualHosts."dav.domus.diffeq.com" = {
      useACMEHost = "dav.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.xandikos.port}";
    };
  };
}
