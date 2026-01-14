{ ... }:
let
  port = 4000;
in
{
  # TODO: mariadb
  # https://github.com/louislam/uptime-kuma/wiki/Environment-Variables#mariadb-environment-variables
  services.uptime-kuma = {
    enable = true;
    settings = {
      PORT = toString port;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."uptime.domus.diffeq.com" = {
      useACMEHost = "uptime.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString port}";
    };
  };
}
