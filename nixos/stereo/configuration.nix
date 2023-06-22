# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)

args@{ inputs, outputs, lib, config, pkgs, options, ... }: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    ../users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager

    (import ../raspberry-pi.nix (args // {rpiBoard = "3b";}))
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

  networking.hostName = "stereo";

  networking.networkmanager = {
    enable = true;
    unmanaged = ["wlan0"];
  };

  time.timeZone = "America/Edmonton";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    git
    tmux

    cifs-utils
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

  # do not allow /etc/passwd & /etc/group to be edited outside configuration.nix
  users.mutableUsers = false;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      # Import your home-manager configuration
      bct = import ../../home-manager/base;
    };
  };

  services.gonic = {
    enable = true;
    settings = options.services.gonic.settings.default // {
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
