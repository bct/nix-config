{
  inputs,
  config,
  pkgs,
  ...
}:
{
  system.stateVersion = "26.05";

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/stump.nix"
  ];

  networking.firewall.allowedTCPPorts = [ config.services.stump.port ];

  services.stump = {
    enable = true;
    package = pkgs.unstable.stump;
  };

  # TODO: hook up acme

  # services.lego-proxy-client = {
  #   enable = true;
  #   domains = [ "stump" ];
  #   group = "caddy";
  # };
  #
  # services.caddy = {
  #   enable = true;
  #   virtualHosts."stump.domus.diffeq.com" = {
  #     useACMEHost = "stump.domus.diffeq.com";
  #     extraConfig = "reverse_proxy localhost:${toString config.services.stump.port}";
  #   };
  # };
}
