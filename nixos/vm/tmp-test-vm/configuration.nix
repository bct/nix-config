{ self, config, lib, libC, pkgs, ... }:

let
  inherit (config.networking) hostName;

  net = "lan";

  macAddress =
    let
      hash = builtins.hashString "md5" "1-${net}-${hostName}";
      c = off: builtins.substring off 2 hash;
    in
      "${builtins.substring 0 1 hash}2:${c 2}:${c 4}:${c 6}:${c 8}:${c 10}";
in {
  imports = [
    "${self}/nixos/common/headless.nix"
  ];

  services.getty.autologinUser = "root";

  microvm = {
    vcpu = 1;
    mem = 512;

    interfaces = [
      {
        type = "tap";
        id = builtins.substring 0 15 "vm-${net}-${hostName}";
        mac = macAddress;
      }
    ];

    volumes = [
      {
        image = "root.img";
        mountPoint = "/";
        size = 8192;
      }
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = "tmp-test-vm";

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };

  system.stateVersion = "24.11";
}
