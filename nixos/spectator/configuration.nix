# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

{ inputs, outputs, lib, config, pkgs, ... }: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    ../users.nix
    ./home-assistant.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
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

  networking.hostName = "spectator";

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

  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Preserve space by sacrificing history
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  boot.tmp.cleanOnBoot = true;

  # add some swap to try to speed up nixos-rebuild
  swapDevices = [ { device = "/var/lib/swapfile"; size = 1*1024; } ];

  time.timeZone = "America/Edmonton";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    libraspberrypi
    git
    tmux

    rtl-sdr
    rtlamr
    rtlamr-collect
  ];

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable the firewall altogether.
  networking.firewall.enable = false;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      bct = import ../../home-manager/base;
    };
  };

  users.groups.rtlamr = {};

  users.users = {
    rtlamr = {
      isSystemUser = true;
      group = "rtlamr";
    };
  };

  systemd.services.rtlamr-collect = {
    description = "RTLAMR Collector";
    environment = {
      RTLAMR_FORMAT = "json";
      RTLAMR_MSGTYPE = "scm";
      RTLAMR_SERVER = "watcher.domus.diffeq.com:1234";
      RTLAMR_FILTERID= "40010397,41946625";

      # COLLECT_LOGLEVEL = "Debug";
      COLLECT_INFLUXDB_HOSTNAME = "http://db.domus.diffeq.com:8086/";
      # TODO: figure out how to put this in agenix
      COLLECT_INFLUXDB_TOKEN = "rtlamr:Too8OhCh";
      COLLECT_INFLUXDB_ORG = "arbitrary";
      COLLECT_INFLUXDB_BUCKET = "rtlamr";
      COLLECT_INFLUXDB_MEASUREMENT = "utilities";
    };

    wantedBy = ["multi-user.target"];

    serviceConfig = {
      WorkingDirectory = "/run/rtlamr-collect";
      RuntimeDirectory = "rtlamr-collect";
      ExecStart = ''/bin/sh -c "${pkgs.rtlamr}/bin/rtlamr | ${pkgs.rtlamr-collect}/bin/rtlamr-collect"'';
      Restart = "always";
      RestartSec = "30";
      User = "rtlamr";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
