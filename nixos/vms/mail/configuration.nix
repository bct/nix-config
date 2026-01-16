# see yuggoth/nixvirt.nix for memory & CPU settings.
{ self, ... }:
{
  imports = [
    "${self}/nixos/vms/common/qemu-vm.nix"
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./borgmatic.nix
    ./getmail.nix
    ./mail.nix
    ./mua.nix

    "${self}/nixos/modules/lego-proxy-client"
  ];

  time.timeZone = "Etc/UTC";

  networking.hostName = "mail";

  fileSystems."/var" = {
    device = "/dev/vdb";
    fsType = "ext4";
  };

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILEDJ/PBvmIgMx3eSKWNX+I7iJBh9GXgs5N/il5oZWgm";

  system.stateVersion = "24.05";
}
