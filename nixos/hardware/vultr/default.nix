{ config, lib, ... }:

{
  options = {
    hardware.vultr = {
      useSwapFile = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "set up a 1GB swapfile (/var/lib/swapfile)";
      };

      setUpDisk = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "configure filesystems and grub device?";
      };
    };
  };

  config = {
    boot.loader.grub.device = lib.mkIf config.hardware.vultr.setUpDisk "/dev/vda";

    boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "sr_mod" "virtio_blk" ];

    fileSystems = lib.mkIf config.hardware.vultr.setUpDisk {
        "/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
    };

    swapDevices = lib.mkIf config.hardware.vultr.useSwapFile [ { device = "/var/lib/swapfile"; size = 1*1024; } ];

    networking.useNetworkd = true;

    systemd.network = {
      enable = true;

      networks."10-lan" = {
        matchConfig.Name = "ens3";
        networkConfig.DHCP = "yes";
      };
    };

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    virtualisation.hypervGuest.enable = true;
  };
}
