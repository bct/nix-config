{ ... }:

{
  disko.devices = {
    disk.nvme = {
      device = "/dev/nvme0n1";
      type = "disk";

      content = {
        type = "gpt";

        # https://github.com/nix-community/nixos-anywhere-examples/blob/main/disk-config.nix
        partitions = {
          # UEFI boot partition
          ESP = {
            type = "EF00";
            size = "512M";
            priority = 1; # Make this the first partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };

          root = {
            name = "nixos";
            end = "-16G";
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
