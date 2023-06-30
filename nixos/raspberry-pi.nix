{ lib, pkgs, rpiBoard, ... }:

assert lib.asserts.assertOneOf "rpiBoard" rpiBoard [
  "3b"
  "3b+"
];

# TODO: figure out how to use rpiBoard to set attrs

{
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.enableRedistributableFirmware = true;

  # add some swap to try to speed up nixos-rebuild
  swapDevices = [ { device = "/var/lib/swapfile"; size = 1*1024; } ];

  # Preserve space by sacrificing history
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  boot.tmp.cleanOnBoot = true;

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];
}
