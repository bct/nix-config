{ self, inputs, outputs, lib, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default

    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix
    ./disk-config.nix

    ./microvm-host.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Etc/UTC";

  networking.hostName = "yuggoth";
  networking.useNetworkd = true;

  age.rekey = {
    masterIdentities = ["/home/bct/.ssh/id_rsa"];
    storageMode = "local";
    localStorageDir = ../../.. + "/secrets/rekeyed/yuggoth";
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVYcCxqBIE6ppS6n7VQb3Qs4w1gEYtNhTdKu+21XO82";
  };

  yuggoth.microvms = {
    interfaceToBridge = "enp5s0f0";

    # to generate a machineId:
    #
    #   ruby -r securerandom -e 'puts SecureRandom.hex'
    #
    # to choose a MAC address:
    # Locally administered have one of 2/6/A/E in the second nibble.
    guests = {
      miniflux = {
        hostName = "miniflux";
        tapInterfaceMac = "02:00:00:00:00:01";
        machineId = "b42e25167b6bc7ca726ea9f41ce5ffcb";
      };

      prometheus = {
        hostName = "prometheus";
        tapInterfaceMac = "02:00:00:00:00:03";
        machineId = "6621b60f7f7ac43dca44e143eb0578a8";
      };

      rtorrent = {
        hostName = "rtorrent";
        tapInterfaceMac = "02:00:00:00:00:04";
        machineId = "9448935ef2c6845cd2298c883fa10734";
      };

      torrent-scraper = {
        hostName = "torrent-scraper";
        tapInterfaceName = "vm-torrent-scra"; # <= 15 chars
        tapInterfaceMac = "02:00:00:00:00:02";
        machineId = "e5b7d8199d4a4a34fb6748faef793248";
      };
    };
  };

  system.stateVersion = "24.05";
}
