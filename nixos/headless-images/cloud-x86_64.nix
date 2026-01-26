{ ... }:
{
  imports = [
    ../common/nix.nix
    ../common/headless.nix
  ];

  # installation images might benefit from documentation
  documentation.nixos.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";
}
