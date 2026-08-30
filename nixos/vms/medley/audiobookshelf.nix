{ config, ... }: {
  services.audiobookshelf = {
    enable = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts."audiobooks.domus.diffeq.com" = {
      useACMEHost = "audiobooks.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.audiobookshelf.port}";
    };
  };
}
