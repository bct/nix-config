{ ... }:

{
  disko.devices = {
    disk.instance-storage = {
      device = "/dev/vda";
      type = "disk";

      content = {
        type = "gpt";

        # https://github.com/nix-community/nixos-anywhere-examples/blob/main/disk-config.nix
        partitions = {
         boot = {
            size = "1M";
            type = "EF02"; # for grub MBR
            priority = 1; # Needs to be first partition
          };

          # UEFI boot partition
          ESP = {
            type = "EF00";
            size = "500M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            name = "nixos";
            end = "-4G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };

          swap = {
            size = "100%";
            content = {
              type = "swap";
              discardPolicy = "both";
            };
          };
        };
      };
    };
  };
}
