{ self, inputs, outputs, lib, ... }: {
  imports = [
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/common/node-exporter.nix"

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

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVYcCxqBIE6ppS6n7VQb3Qs4w1gEYtNhTdKu+21XO82";

  yuggoth.microvms = {
    interfaceToBridge = "enp5s0f0";

    # to generate a machineId:
    #
    #   ruby -r securerandom -e 'puts SecureRandom.hex'
    #
    # to choose a MAC address:
    # Locally administered have one of 2/6/A/E in the second nibble.
    guests = {
      abrado = {
        hostName = "abrado";
        tapInterfaceMac = "02:00:00:00:00:08";
        machineId = "6b044915f8a8c5a6c0e9b5401d9778cf";
      };

      db = {
        hostName = "db";
        tapInterfaceMac = "02:00:00:00:00:07";
        machineId = "2e9cd72837fcd95c103ac6f4bdeb726a";
      };

      grafana = {
        hostName = "grafana";
        tapInterfaceMac = "02:00:00:00:00:06";
        machineId = "d2bf3078fe2744f57398cc02476228f9";
      };

      immich = {
        hostName = "immich";
        tapInterfaceMac = "02:00:00:00:00:09";
        machineId = "538b82e19deee1b600027ea47fe3e8dc";
      };

      mail = {
        hostName = "mail";
        tapInterfaceMac = "02:00:00:00:00:11";
        machineId = "b1d942ead0d9d6afb175cedf4e416d22";
      };

      miniflux = {
        hostName = "miniflux";
        tapInterfaceMac = "02:00:00:00:00:01";
        machineId = "b42e25167b6bc7ca726ea9f41ce5ffcb";
      };

      paperless = {
        hostName = "paperless";
        tapInterfaceMac = "02:00:00:00:00:10";
        machineId = "4e792125b5445ffd50e474ad64f5d30b";
      };

      prometheus = {
        hostName = "prometheus";
        tapInterfaceMac = "02:00:00:00:00:03";
        machineId = "6621b60f7f7ac43dca44e143eb0578a8";
      };

      spectator = {
        hostName = "spectator";
        tapInterfaceMac = "02:00:00:00:00:04";
        machineId = "08e6532eedca9b41586bd21b881c6bbf";
      };

      torrent-scraper = {
        hostName = "torrent-scraper";
        tapInterfaceName = "vm-torrent-scra"; # <= 15 chars
        tapInterfaceMac = "02:00:00:00:00:02";
        machineId = "e5b7d8199d4a4a34fb6748faef793248";
      };

      lego-proxy = {
        hostName = "lego-proxy";
        tapInterfaceMac = "02:00:00:00:00:05";
        machineId = "0c309b2d738728317e0dbc9725a64dc1";
      };
    };
  };

  # grant qemu access to the devices that will be passed through to microvms
  services.udev.extraRules = ''
    # RTL2838UHIDIR
    # Realtek Semiconductor Corp. RTL2838 DVB-T
    SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="2838", GROUP="kvm"

    # Sonoff Zigbee 3.0 USB Dongle Plus
    # Silicon Labs CP210x UART Bridge
    SUBSYSTEM=="usb", ATTR{idVendor}=="10c4", ATTR{idProduct}=="ea60", GROUP="kvm"
  '';

  system.stateVersion = "24.05";
}
