{ ... }:

# "ZFS often does not support the latest Kernel versions. It is recommended to use an LTS Kernel version whenever possible; the NixOS default Kernel is generally suitable."
# https://wiki.nixos.org/wiki/ZFS
{
  boot.supportedFilesystems = [ "zfs" ];

  # required for zfs. generated with:
  #     head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "48d29ee6";

  boot.zfs = {
    forceImportRoot = false;

    # import & mount our pool.
    # alternatively we could use ZFS "legacy" mountpoints and "fileSystems".
    extraPools = [ "bulk" ];
  };

  services.zfs = {
    autoScrub = {
      enable = true;
    };

    zed.settings = {
      ZED_NOTIFY_VERBOSE = true;
      ZED_NTFY_TOPIC = "doog4maechoh";
      ZED_NTFY_URL = "https://ntfy.sh";
    };
  };
}
