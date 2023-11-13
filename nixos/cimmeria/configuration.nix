{ self, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      "${self}/nixos/common/nix.nix"
      "${self}/nixos/common/desktop"

      ./borgmatic.nix
      ./wireguard.nix

      "${self}/nixos/common/desktop/projects/android.nix"
      "${self}/nixos/common/desktop/projects/3d-print.nix"
    ];

  personal.user = "bct";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cimmeria";
  networking.firewall.enable = false;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  hardware.firmware = with pkgs; [
    # I'm not sure this is necessary. I added it when I was debugging audio
    # (total silence, ultimately caused by Windows "fast boot"), and I don't
    # feel like testing without it at the moment.
    sof-firmware
  ];

  services.udev.extraRules = ''
    # Suspend the system when battery level drops to 5% or lower
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl suspend"

    # USBtinyISP: https://learn.adafruit.com/usbtinyisp/avrdude
    SUBSYSTEMS=="usb", ATTR{product}=="USBtiny", ATTR{idVendor}=="1781", ATTR{idProduct}=="0c9f", GROUP="users", MODE="0666"

    # Give the "video" group access to the backlight
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
  '';

  # power management
  services.tlp.enable = true;

  services.syncthing = {
    enable = true;
    user = "bct";
    dataDir = "/home/bct";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
