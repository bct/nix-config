{ self, ... }:

{
  imports =
    [
      ./hardware-configuration.nix

      "${self}/nixos/common/nix.nix"
      "${self}/nixos/common/desktop"
    ];

  personal.user = "bct";

  # grub seems to be the best way to dual-boot windows
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;

    # by default we'll boot into windows.
    extraEntriesBeforeNixOS = true;

    # this is copy/pasted from the grub.cfg produced by "useOSProber".
    # useOSProber = true;
    extraEntries = ''
      menuentry 'Windows Boot Manager (on /dev/sdb1)' --class windows --class os --id 'osprober-efi-E8E1-DD32' {
        insmod part_gpt
        insmod fat
        set root='hd1,gpt1'
        search --no-floppy --fs-uuid --set=root --hint-ieee1275='ieee1275//disk@0,gpt1' --hint-bios=hd1,gpt1 --hint-efi=hd1,gpt1 --hint-baremetal=ahci1,gpt1  E8E1-DD32
        chainloader /efi/Microsoft/Boot/bootmgfw.efi
      }
    '';
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 15;

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
