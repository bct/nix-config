{
  self,
  inputs,
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "26.05";

  imports = [
    "${self}/nixos/modules/lego-proxy-client"

    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/stump.nix"
  ];

  services.stump = {
    enable = true;
    package = pkgs.unstable.stump;
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "stump" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.caddy = {
    enable = true;
    virtualHosts."stump.domus.diffeq.com" = {
      useACMEHost = "stump.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.stump.port}";
    };
  };
}
