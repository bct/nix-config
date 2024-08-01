{ inputs, pkgs, ... }:

let
  system = pkgs.system;
  immich-nixpkgs = inputs.nixpkgs-jvanbruegge;
  immich-pkgs = immich-nixpkgs.legacyPackages.${system};
in {
  imports = [
    "${immich-nixpkgs}/nixos/modules/services/web-apps/immich.nix"
  ];

  config = {
    services.immich = {
      enable = true;
      package = immich-pkgs.immich;

      openFirewall = true;
      host = "0.0.0.0";

      # avoid conflict with redis-nitter
      redis.port = 6380;
    };
  };
}
