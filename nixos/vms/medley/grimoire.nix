{ self, config, ... }:
{
  imports = [ "${self}/nixos/modules/grimoire" ];

  services.grimoire = {
    enable = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts."grimoire.domus.diffeq.com" = {
      useACMEHost = "grimoire.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.grimoire.port}";
    };
  };
}
