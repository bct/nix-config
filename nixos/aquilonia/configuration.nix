{ self, pkgs, ... }:

{
  imports =
    [
      "${self}/nixos/common/agenix-rekey.nix"

      "${self}/nixos/common/nix.nix"
      "${self}/nixos/common/desktop"

      "${self}/nixos/modules/wireguard-via-wgsd.nix"

      ./hardware-configuration.nix

      ./borgmatic.nix
      ./framework.nix

      "${self}/nixos/common/desktop/projects/android.nix"
      "${self}/nixos/common/desktop/projects/3d-print.nix"
    ];

  personal.user = "bct";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKG0UT1vOHAbi9Rosdsu/ckvredKsdZ+vsAE9uLU1JNM";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "aquilonia";
  networking.firewall.enable = false;

  services.wireguard-via-wgsd.address = "192.168.8.18/32";

  nix.settings = {
    # don't garbage collect outputs that are only needed at build-time
    keep-outputs = true;

    # don't garbage collect intermediate derivations
    keep-derivations = true;
  };

  # Enable touchpad support (enabled by default in most desktopManager).
  services.libinput.enable = true;

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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.xpadneo.enable = true;

  services.trezord.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      JustWorksRepairing = "confirm";
    };
  };

  # required for Yubikey's CCID/PIV mode
  services.pcscd.enable = true;

  hardware.sane.brscan4 = {
    enable = true;
    netDevices = {
      office1 = {
        ip = "192.168.4.246";
        model = "DCP-L2550DW";
      };
    };
  };

  # TODO: disable me
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ "bct" ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
