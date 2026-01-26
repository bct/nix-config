{
  ...
}:
{
  imports = [
    ../common/nix.nix
    ../common/headless.nix
  ];

  # installation images might benefit from documentation
  documentation.nixos.enable = true;

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.11";

  # add some swap to try to speed up nixos-rebuild
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 1 * 1024;
    }
  ];
}
