{
  pkgs,
  lib,
  config,
  ...
}:
{
  users.users.klipper = {
    isSystemUser = true;
    group = "klipper";
  };
  users.groups.klipper = { };

  services.klipper = {
    enable = true;
    user = "klipper";
    group = "klipper";

    settings = {
      mcu = {
        serial = "/dev/serial/by-id/usb-Klipper_stm32g0b1xx_49000A000150414D39343620-if00";
      };
    };
    extraSettings = lib.concatStringsSep "\n" [
      (builtins.readFile ./klipper.ini)
      (builtins.readFile ./mainsail.cfg)
    ];
    firmwares = {
      # nix build .#nixosConfigurations.octopi.config.services.klipper.firmwares.skr-mini-e3-v3.package
      # copy result/firmware.bin to the printer's SD card.
      skr-mini-e3-v3 = {
        enable = true;
        enableKlipperFlash = false;
        configFile = ./firmware.ini;
        # this might be irrelevant since it can't flash directly.
        serial = "/dev/serial/by-id/usb-Klipper_stm32g0b1xx_49000A000150414D39343620-if00";
      };
    };
  };

  services.moonraker = {
    enable = true;
    # so that we can access Klipper's API socket
    group = config.services.klipper.group;

    address = "0.0.0.0";

    # TODO: ldap?
    settings = {
      authorization = {
        # Trusted clients are given full access to the API.
        trusted_clients = [
          "127.0.0.1"
          "192.168.4.0/24"
        ];

        cors_domains = [
          "http://octopi.domus.diffeq.com"
          "https://octopi.domus.diffeq.com"
        ];
      };

      # enable octoprint compatibility
      octoprint_compat = { };
    };
  };

  services.mainsail = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    config.services.moonraker.port
  ];
}
