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
    "${self}/nixos/modules/microvm-host"
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

  # addresses for guests (microvms and libvirt VMs); see nixos/modules/guest-network.
  diffeq.guestNetwork.subnetPrefix = "192.168.201";

  diffeq.microvms = {
    enable = true;
    waitForZfs = true;
    uplinkInterface = "enp8s0";
    guestsDir = ./guests;

    # to generate a machineId:
    #
    #   ruby -r securerandom -e 'puts SecureRandom.hex'
    #
    guests = {
      borg = {
        hostName = "borg";
        address = "192.168.201.2";
        machineId = "a2717cf46338fdb456749d51d6611e16";
      };

      git = {
        hostName = "git";
        address = "192.168.201.4";
        machineId = "1e64c3582fc0370de9a282455d58a192";
      };

      media = {
        hostName = "media";
        address = "192.168.201.1";
        machineId = "8115ded7ebad02ebc1f9541f1fd63312";
      };

      syncthing = {
        hostName = "syncthing";
        address = "192.168.201.5";
        machineId = "f4132f22d27e1890a42b3c1970e3eaac";
      };
    };
  };

  fileSystems."/home" = {
    fsType = "none";
    device = "/mnt/bulk/home/";
    options = [
      "bind"
      "x-systemd.requires=/mnt/bulk/home"
    ];
  };

  home-manager.users.bct = {
    personal.enableFancyShell = true;
  };

  system.stateVersion = "25.11";
}
