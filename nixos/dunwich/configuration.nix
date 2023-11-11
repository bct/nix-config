{ self, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      "${self}/nixos/common/nix.nix"
      "${self}/nixos/common/desktop"

      ./packages.nix
    ];

  personal.user = "brendan";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "dunwich";
  networking.firewall.enable = false;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # power management
  services.tlp.enable = true;

  sound.extraConfig = ''
    defaults.pcm.!card 1
  '';

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
