{ self, inputs, pkgs, ... }: {
  imports = [
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/common/node-exporter.nix"

    ./hardware-configuration.nix
    ./disk-config.nix

    ./microvm-host.nix
    ./nixvirt.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # attempt to work around issues with cold boot
  # (stuck at EFI stub, "measured initrd data into pcr 9")
  # 6.12.39 works, 6.12.41 does not?
  boot.kernelPackages = pkgs.linuxPackages_latest;

  time.timeZone = "Etc/UTC";

  networking.hostName = "yuggoth";
  networking.useNetworkd = true;

  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFVYcCxqBIE6ppS6n7VQb3Qs4w1gEYtNhTdKu+21XO82";

  services.prometheus.exporters.node.enabledCollectors = [ "hwmon" ];

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
        requires = ["microvm@db.service"];
        startDelay = 60;
      };

      books = {
        hostName = "books";
        tapInterfaceMac = "02:00:00:00:00:16";
        machineId = "4335d74e7a5b1743ec13ad4d7b8241be";
        requires = ["microvm@lego-proxy.service"];
        startDelay = 60;
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
        requires = ["microvm@db.service" "microvm@lego-proxy.service"];
        startDelay = 60;
      };

      immich = {
        hostName = "immich";
        tapInterfaceMac = "02:00:00:00:00:09";
        machineId = "538b82e19deee1b600027ea47fe3e8dc";
        requires = ["microvm@db.service" "microvm@lego-proxy.service"];
        startDelay = 120;
      };

      jellyfin = {
        hostName = "jellyfin";
        tapInterfaceMac = "02:00:00:00:00:13";
        machineId = "099112cbbe05544a6240c797d4c83e7a";
        requires = ["microvm@db.service" "microvm@lego-proxy.service"];
        startDelay = 120;
      };

      lubelogger = {
        hostName = "lubelogger";
        tapInterfaceMac = "02:00:00:00:00:14";
        machineId = "136934c3334f852e7e2a506bc5484a2b";
        requires = ["microvm@db.service" "microvm@lego-proxy.service"];
        startDelay = 60;
      };

      mail = {
        hostName = "mail";
        tapInterfaceMac = "02:00:00:00:00:11";
        machineId = "b1d942ead0d9d6afb175cedf4e416d22";
        requires = ["microvm@lego-proxy.service"];
      };

      paperless = {
        hostName = "paperless";
        tapInterfaceMac = "02:00:00:00:00:10";
        machineId = "4e792125b5445ffd50e474ad64f5d30b";
        requires = ["microvm@db.service" "microvm@lego-proxy.service"];
        startDelay = 120;
      };

      prometheus = {
        hostName = "prometheus";
        tapInterfaceMac = "02:00:00:00:00:03";
        machineId = "6621b60f7f7ac43dca44e143eb0578a8";
      };

      shell-of-the-old = {
        hostName = "shell-of-the-old";
        tapInterfaceName = "vm-shell-of-the"; # <= 15 chars
        tapInterfaceMac = "02:00:00:00:00:12";
        machineId = "5c5ab3a55d2518c2ab823096462194e4";
        restartIfChanged = false;
        requires = ["microvm@lego-proxy.service"];
      };

      spectator = {
        hostName = "spectator";
        tapInterfaceMac = "02:00:00:00:00:04";
        machineId = "08e6532eedca9b41586bd21b881c6bbf";
        startDelay = 120;
      };

      torrent-scraper = {
        hostName = "torrent-scraper";
        tapInterfaceName = "vm-torrent-scra"; # <= 15 chars
        tapInterfaceMac = "02:00:00:00:00:02";
        machineId = "e5b7d8199d4a4a34fb6748faef793248";
        requires = ["microvm@db.service" "microvm@lego-proxy.service"];
        startDelay = 60;
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
