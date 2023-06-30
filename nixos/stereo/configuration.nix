args@{ inputs, outputs, lib, config, pkgs, options, ... }: {
  imports = [
    ../users.nix
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # fix for kernel build failure:
      #
      #     modprobe: FATAL: Module ahci not found in directory
      #
      # https://github.com/NixOS/nixpkgs/issues/154163
      (final: super: {
        makeModulesClosure = x:
          super.makeModulesClosure (x // { allowMissing = true; });
      })

      # fdtoverlay does not support the DTS overlay file I'm using below
      # (it exits with FDT_ERR_NOTFOUND)
      # https://github.com/raspberrypi/firmware/issues/1718
      #
      # we'll use dtmerge instead.
      # https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/pkgs-overlays.nix
      (_final: prev: {
        deviceTree.applyOverlays = prev.callPackage ./apply-overlays-dtmerge.nix { };
      })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  networking.hostName = "stereo";

  networking.networkmanager = {
    enable = true;
    unmanaged = ["wlan0"];
  };

  time.timeZone = "America/Edmonton";

  environment.systemPackages = with pkgs; [
    vim
    git
    tmux

    alsa-utils
    cifs-utils
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  networking.firewall.enable = false;

  # do not allow /etc/passwd & /etc/group to be edited outside configuration.nix
  users.mutableUsers = false;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      bct = import ../../home-manager/base;
    };
  };

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;

   # We need to use the vendor kernel, mainline doesn't have a driver for the HifiBerry DAC+.
  boot.kernelPackages = pkgs.linuxPackages_rpi3;

  # The vendor kernel won't boot if this module loads:
  # https://github.com/NixOS/nixpkgs/issues/200326
  #
  # Fortunately I don't need wifi.
  boot.blacklistedKernelModules = [ "brcmfmac" ];

  # A bunch of boot parameters needed for optimal runtime on RPi 3b+
  boot.kernelParams = ["cma=256M"];
  boot.loader.raspberryPi.version = 3;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware.enableRedistributableFirmware = true;

  # add some swap to try to speed up nixos-rebuild
  swapDevices = [ { device = "/var/lib/swapfile"; size = 1*1024; } ];

  hardware.deviceTree = {
    enable = true;
    overlays = [
      {
        name = "hifiberry-dacplus";
        dtsFile = ./hifiberry-dacplus-overlay.dts;
      }
    ];
  };

  # grant myself access to the sound card.
  users.users.bct.extraGroups = ["audio"];

  services.gonic = {
    enable = true;
    settings = {
      listen-addr = "0.0.0.0:4747";
      cache-path = "/var/cache/gonic";

      music-path = ["/mnt/beets"];
      podcast-path = "/var/empty";
      scan-interval = 60; # minutes
    };
  };

  fileSystems."/mnt/beets" = {
    device = "//mi-go.domus.diffeq.com/beets";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},guest"];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
