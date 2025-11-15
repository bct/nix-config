{ ... }: let
  port = 3000;
in {
  services.karakeep = {
    enable = true;
    extraEnvironment = {
      NEXTAUTH_URL = "https://bookmarks.domus.diffeq.com/";
      PORT = toString port;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."bookmarks.domus.diffeq.com" = {
      useACMEHost = "bookmarks.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString port}";
    };
  };
}
