args@{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ../common/nix.nix
    ../common/headless.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "23.05";
}
