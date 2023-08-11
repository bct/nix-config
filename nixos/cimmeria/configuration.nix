{ self, config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      "${self}/nixos/common/nix.nix"
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "cimmeria";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Edmonton";

  i18n.defaultLocale = "en_CA.UTF-8";
  console.keyMap = "dvorak";

  services.xserver.enable = true;
  services.xserver.layout = "dvorak";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  sound.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  services.xserver.displayManager.defaultSession = "default";
  services.xserver.displayManager.session = [
    {
      manage = "desktop";
      name = "default";
      start = ''exec $HOME/.xsession'';
    }
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bct = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "networkmanager" "video" ];
    packages = with pkgs; [
      chromium
      mpv

      cura
      freecad
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget

    home-manager

    sshfs
  ];

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


  networking.firewall.enable = false;

  environment.variables.EDITOR = "vim";

  # power management
  services.tlp.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
