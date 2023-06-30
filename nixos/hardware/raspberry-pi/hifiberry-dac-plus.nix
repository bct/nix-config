{ pkgs, ... }:

{
  sound.enable = true;
  sound.extraConfig = ''
    defaults.pcm.!card 1
    defaults.ctl.!card 1
  '';

   # We need to use the vendor kernel, mainline doesn't have a driver for the HifiBerry DAC+.
  boot.kernelPackages = pkgs.linuxPackages_rpi3;

  hardware.deviceTree = {
    enable = true;
    overlays = [
      {
        name = "hifiberry-dacplus";
        dtsFile = ./hifiberry-dacplus-overlay.dts;
      }
    ];
  };

  # The vendor kernel won't boot if this module loads:
  # https://github.com/NixOS/nixpkgs/issues/200326
  #
  # Fortunately I don't need wifi.
  boot.blacklistedKernelModules = [ "brcmfmac" ];

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

      # fdtoverlay does not support the DTS overlay file I'm using above
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
}
