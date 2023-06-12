{ lib, pkgs, rpiBoard, ... }:

assert lib.asserts.assertOneOf "rpiBoard" rpiBoard [
  "3b+"
];

# TODO: figure out how to use rpiBoard to set attrs

{
  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;

  # if you have a Raspberry Pi 2 or 3, pick this:
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # A bunch of boot parameters needed for optimal runtime on RPi 3b+
  boot.kernelParams = ["cma=256M"];
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 3;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.raspberryPi.firmwareConfig = ''
    gpu_mem=256
  '';

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
