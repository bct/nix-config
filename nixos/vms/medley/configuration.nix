{ self, inputs, pkgs, ... }: let
  nixpkgs = inputs.nixpkgs;
in {
  imports = [
    "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./hardware-configuration.nix
    ./homepage.nix
  ];

  # https://github.com/nix-community/nixos-generators/blob/master/formats/qcow.nix
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.timeout = 0;

  time.timeZone = "Etc/UTC";

  networking.hostName = "medley";

  system.stateVersion = "25.05";
}
