args@{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ../common/nix.nix
    ../common/headless.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "23.05";

  # add some swap to try to speed up nixos-rebuild
  swapDevices = [ { device = "/var/lib/swapfile"; size = 1*1024; } ];
}
