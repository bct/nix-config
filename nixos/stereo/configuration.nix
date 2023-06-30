args@{ inputs, outputs, lib, config, pkgs, options, ... }: {
  imports = [
    ../common/nix.nix
    ../common/headless.nix

    ./hardware-configuration.nix
  ];

  nixpkgs = {
    overlays = [
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
  };

  networking.hostName = "stereo";

  networking.networkmanager = {
    enable = true;
    unmanaged = ["wlan0"];
  };

  time.timeZone = "America/Edmonton";

  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  networking.firewall.enable = false;

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

   # We need to use the vendor kernel, mainline doesn't have a driver for the HifiBerry DAC+.
  boot.kernelPackages = pkgs.linuxPackages_rpi3;

  # The vendor kernel won't boot if this module loads:
  # https://github.com/NixOS/nixpkgs/issues/200326
  #
  # Fortunately I don't need wifi.
  boot.blacklistedKernelModules = [ "brcmfmac" ];

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

  sound.enable = true;
  sound.extraConfig = ''
    defaults.pcm.!card 1
    defaults.ctl.!card 1
  '';

  services.gonic = {
    enable = true;
    settings = {
      listen-addr = "0.0.0.0:4747";
      cache-path = "/var/cache/gonic";

      music-path = ["/mnt/beets"];
      podcast-path = "/var/empty";
      scan-interval = 60; # minutes

      jukebox-enabled = true;
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
