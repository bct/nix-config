# see mi-go/nixvirt.nix for memory & CPU settings.
{ self, ... }:
{
  imports = [
    "${self}/nixos/vms/common/qemu-vm.nix"
    "${self}/nixos/common/agenix-rekey.nix"

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    "${self}/nixos/modules/lego-proxy-client"
  ];

  time.timeZone = "Etc/UTC";

  networking.hostName = "ranger";

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTNt/y26ZktCI1KNHV0eWhpP8uiDBoNh5sy0lxPLewj";

  system.stateVersion = "25.11";
}
