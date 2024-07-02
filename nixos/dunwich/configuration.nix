{ self, pkgs, config, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      "${self}/nixos/common/nix.nix"
      "${self}/nixos/common/desktop"

      "${self}/nixos/modules/wireguard-via-wgsd.nix"
    ];

  personal.user = "brendan";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dunwich";
  networking.firewall.enable = false;

  services.wireguard-via-wgsd.address = "192.168.8.18/32";

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # power management
  services.tlp.enable = true;

  hardware.pulseaudio.enable = true;
  sound.extraConfig = ''
    defaults.pcm.!card 1
    defaults.ctl.!card 1
  '';

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 64 * 1024; # 64GB
    }
  ];

  # the root disk
  boot.resumeDevice = "/dev/disk/by-uuid/8a1d945c-dff0-4e0f-88f4-3df8bd66f874";
  boot.kernelParams = [
    "resume=UUID=8a1d945c-dff0-4e0f-88f4-3df8bd66f874"
    # the first row of the "physical_offset" column in `sudo filefrag -v /swapfile`
    "resume_offset=196800512"
  ];


  services.udev.extraRules = ''
    # Suspend the system when battery level drops to 5% or lower
    SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", ATTR{capacity}=="[0-5]", RUN+="${pkgs.systemd}/bin/systemctl suspend"

    # Give the "video" group access to the backlight
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
  '';

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = true;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of x
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    prime = {
      # "reverse PRIME".
      # The Intel/AMD GPU will be used for all rendering, while enabling output
      # to displays attached only to the NVIDIA GPU without a multiplexer.
      #
      # Note that this configuration will only be successful when a display
      # manager for which the services.xserver.displayManager.setupCommands
      # option is supported is used.
      #
      # this should allow both the laptop screen and an external monitor to be
      # used.
      reverseSync.enable = true;

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  networking.hosts = {
    "127.0.0.1" = [
      "bagel.local.artificial.agency"
      "admin.local.artificial.agency"
      "dashboard.local.artificial.agency"
    ];
  };

  virtualisation.docker = {
    enable = true;
  };

  users.users.${config.personal.user} = {
    extraGroups = [ "docker" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
