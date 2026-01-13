{
  config,
  lib,
  pkgs,
  ...
}:

# https://wiki.nixos.org/wiki/ZFS
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  # Note this might jump back and forth as kernels are added or removed.
  boot.kernelPackages = latestKernelPackage;

  boot.supportedFilesystems = [ "zfs" ];

  # required for zfs. generated with:
  #     head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "48d29ee6";

  # import & mount our pool.
  # alternatively we could use ZFS "legacy" mountpoints and and "fileSystems".
  boot.zfs.extraPools = [ "bulk" ];

  services.zfs.autoScrub = {
    enable = true;
  };
}
