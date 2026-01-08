{
  self,
  ...
}:
{
  imports = [
    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./hardware-configuration.nix
    ./zfs.nix
  ];

  # Legacy boot
  boot.loader.grub.device = "/dev/disk/by-id/wwn-0x500a0751e13d89b2"; # /dev/sda

  time.timeZone = "Etc/UTC";

  networking.hostName = "mi-go";
  networking.useNetworkd = true;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmvKCDSnW1IWz/qZAfw8HCdsEEKCNtD4gJXmuKM9pkg";

  system.stateVersion = "25.11";
}
