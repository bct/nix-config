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

    ./accounts.nix
    ./hardware-configuration.nix
    ./microvm-host.nix
    ./nixvirt.nix
    ./samba.nix
    ./zfs.nix
  ];

  # Legacy boot
  boot.loader.grub.device = "/dev/disk/by-id/wwn-0x500a0751e13d89b2"; # /dev/sda

  time.timeZone = "Etc/UTC";

  networking.hostName = "mi-go";
  networking.useNetworkd = true;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmvKCDSnW1IWz/qZAfw8HCdsEEKCNtD4gJXmuKM9pkg";

  mi-go.microvms = {
    interfaceToBridge = "enp8s0";

    # to generate a machineId:
    #
    #   ruby -r securerandom -e 'puts SecureRandom.hex'
    #
    # to choose a MAC address:
    # Locally administered have one of 2/6/A/E in the second nibble.
    guests = {
      borg = {
        hostName = "borg";
        tapInterfaceMac = "02:00:00:00:01:02";
        machineId = "a2717cf46338fdb456749d51d6611e16";
      };

      git = {
        hostName = "git";
        tapInterfaceMac = "02:00:00:00:01:04";
        machineId = "1e64c3582fc0370de9a282455d58a192";
      };

      media = {
        hostName = "media";
        tapInterfaceMac = "02:00:00:00:01:01";
        machineId = "8115ded7ebad02ebc1f9541f1fd63312";
      };

      syncthing = {
        hostName = "syncthing";
        tapInterfaceMac = "02:00:00:00:01:05";
        machineId = "f4132f22d27e1890a42b3c1970e3eaac";
      };

      torrent = {
        hostName = "torrent";
        tapInterfaceMac = "02:00:00:00:01:03";
        machineId = "e015e63485604a4efda43823812f3dcd";
      };
    };
  };

  system.stateVersion = "25.11";
}
