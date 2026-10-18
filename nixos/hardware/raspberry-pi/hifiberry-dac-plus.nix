{ ... }:

# Quirks: we need to use the vendor kernel, mainline doesn't have a driver for the HifiBerry DAC+.
#
# Requires nixos-raspberrypi's bootloader, which lets the firmware apply the overlay via config.txt.
{
  hardware.alsa.enablePersistence = true;
  environment.etc."asound.conf".text = ''
    defaults.pcm.!card 1
    defaults.ctl.!card 1
  '';

  hardware.raspberry-pi.config.all.dt-overlays.hifiberry-dacplus = {
    enable = true;
    params = { };
  };

  # The vendor kernel won't boot if this module loads:
  # https://github.com/NixOS/nixpkgs/issues/200326
  #
  # Fortunately I don't need wifi.
  boot.blacklistedKernelModules = [ "brcmfmac" ];
}
