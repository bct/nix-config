{ self, inputs, config, pkgs, ... }:
let
  x86Pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
in {
  imports = [
    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"

    "${self}/nixos/hardware/raspberry-pi"

    ./hardware-configuration.nix
  ];

  networking.hostName = "writer";
  networking.wireless.enable = true;

  # the systemd.network configuration is responsible for controlling DHCP.
  networking.useDHCP = false;

  systemd.network = {
    enable = true;

    networks."10-wlan" = {
      matchConfig.Type = "wlan";
      networkConfig.DHCP = "yes";
    };
  };

  # avoid writing logs to disk, try to save the SD card
  services.journald.extraConfig = ''
    Storage=volatile
  '';

  time.timeZone = "America/Edmonton";

  # samsung drivers do not include ARM support
  boot.binfmt.emulatedSystems = [ "i386-linux" "x86_64-linux" ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  services.printing = {
    enable = true;
    drivers = [ x86Pkgs.samsung-unified-linux-driver_1_00_37 ];
    logLevel = "debug";

    # printer sharing
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "Samsung_SCX-3405W";
        location = "Library";
        deviceUri = "usb://Samsung/SCX-3400%20Series?serial=Z6U8B8KCAB00S7A&interface=1";
        model = "Samsung_SCX-3400_Series.ppd.gz";
      }
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "24.11";
}
