{ ... }: {
  # this is very similar to vultr
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.availableKernelModules = [ "ahci" "virtio_pci" "xhci_pci" "sr_mod" "virtio_blk" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enp0s4";
      networkConfig.DHCP = "yes";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
