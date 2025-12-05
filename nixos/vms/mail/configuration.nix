# see yuggoth/nixvirt.nix for memory & CPU settings.
{ self, inputs, ... }:
let
  nixpkgs = inputs.nixpkgs;
in
{
  imports = [
    "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"

    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./hardware-configuration.nix

    ./mail.nix

    "${self}/nixos/modules/lego-proxy-client"
  ];

  # https://github.com/nix-community/nixos-generators/blob/master/formats/qcow.nix
  boot.growPartition = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.timeout = 0;

  time.timeZone = "Etc/UTC";

  networking.hostName = "mail";

  fileSystems."/var" = {
    device = "/dev/vdb";
    fsType = "ext4";
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEDJ/PBvmIgMx3eSKWNX+I7iJBh9GXgs5N/il5oZWgm";

  system.stateVersion = "24.05";
}
