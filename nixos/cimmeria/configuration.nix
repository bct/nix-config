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

  # Enable printer discovery.
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

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

  # "For the sandboxed apps to work correctly, desktop integration portals need to be installed."
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bct = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "networkmanager" "video" ];
    packages = with pkgs; [
      chromium
      mpv
      epdfview
      libreoffice

      cura5
      freecad

      ansible

      # for "strings"
      binutils
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget

    home-manager

    sshfs
    exfat
    ntfs3g
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

  # automount removeable storage
  services.devmon.enable = true;
  programs.udevil.enable = true;

  networking.firewall.enable = false;

  environment.variables.EDITOR = "vim";

  # power management
  services.tlp.enable = true;

  services.borgmatic = {
    enable = true;
    settings = {
      location.source_directories = [
        "/home"
      ];

      location.repositories = [
        "ssh://borg@borg.domus.diffeq.com/srv/borg/cimmeria/"
      ];

      location.exclude_patterns = [
        "/home/*/.cache"
        "/home/bct/videos"
      ];

      # TODO: move this into age?
      storage.ssh_command = "ssh -i /root/.ssh/borg";

      retention = {
        keep_daily = 14;
        keep_weekly = 8;
        keep_monthly = 12;
        keep_yearly = 1;
      };

      hooks.ntfy = {
        topic = "doog4maechoh";
        finish = {
          title = "[cimmeria] borgmatic finished";
          message = "Your backup has finished.";
          priority = "default";
          tags = "kissing_heart,borgmatic";
        };
        fail = {
          title = "[cimmeria] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
        };

        # List of monitoring states to ping fore. Defaults to pinging for failure only.
        states = ["finish" "fail"];
      };
    };
  };

  # use emulation to compile aarch64 packages
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
