{ ... }:

{
  disko.devices = {
    disk.nvme = {
      device = "/dev/nvme0n1";
      type = "disk";

      content = {
        type = "gpt";

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

          # LVM physical volume for virtual group "fastpool"
          primary = {
            size = "100%";
            content = {
              type = "lvm_pv";
              vg = "fastpool";
            };
          };
        };
      };
    };

    # LVM virtual group that lives on the NVME disk.
    lvm_vg.fastpool = {
      type = "lvm_vg";
      lvs = {
        swap = {
          size = "16G";
          content = {
            type = "swap";
            discardPolicy = "both";
          };
        };

        host-root = {
          name = "nixos";
          size = "40G";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };

        db-var = {
          name = "db-var";
          size = "16G";
          content = {
            type = "filesystem";
            format = "ext4";
          };
        };

        mail-var = {
          name = "mail-var";
          size = "32G";
          content = {
            type = "filesystem";
            format = "ext4";
          };
        };
      };
    };
  };

  # make LVM disks accessible to microvms
  # to look up the properties used here:
  #     udevadm info --query=all --name=/dev/dm-2
  services.udev.extraRules = ''
    ENV{DM_VG_NAME}=="fastpool" ENV{DM_LV_NAME}=="db-var" OWNER="microvm"
    ENV{DM_VG_NAME}=="fastpool" ENV{DM_LV_NAME}=="mail-var" OWNER="microvm"
  '';
}
