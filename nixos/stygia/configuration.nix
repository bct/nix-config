{ self, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      "${self}/nixos/common/nix.nix"
      "${self}/nixos/common/desktop"

      "${self}/nixos/common/desktop/projects/3d-print.nix"
    ];

  personal.user = "bct";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "stygia";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.sane.brscan4 = {
    enable = true;
    netDevices = {
      office1 = {
        ip = "192.168.4.246";
        model = "DCP-L2550DW";
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
