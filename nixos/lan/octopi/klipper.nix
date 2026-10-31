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
      ''

        ### Include: klipper.ini
      ''
      (builtins.readFile ./klipper.ini)
      ''

        ### Include: mainsail.cfg
      ''
      (builtins.readFile ./mainsail.cfg)
      # ''
      #
      #   ### Macros
      #   [gcode_macro END_PRINT]
      #   gcode:
      #     # Turn off bed, extruder, and fan
      #     M140 S0
      #     M104 S0
      #     M106 S0
      #     # Move nozzle away from print while retracting
      #     G91
      #     G1 Z10 E-5 F300
      #     G90
      #     G1 X10 Y300 F3000
      #     # Disable steppers
      #     M84
      # ''
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

  # klippy logs a "Stats" line every second; drop those before they reach the journal.
  systemd.services.klipper.serviceConfig.LogFilterPatterns = "~^INFO:root:Stats ";

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

      # push notifications via ntfy.sh (moonraker uses apprise for this)
      "notifier print_done" = {
        url = "ntfys://ntfy.sh/doog4maechoh";
        events = "complete, error, cancelled";
        title = "Octopi: print {event_name}";
        body = "{event_args[1].filename}";
      };
    };
  };

  services.mainsail = {
    enable = true;

    # default is 10MB which is easy to exceed.
    nginx.extraConfig = ''
      client_max_body_size 100m;
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    config.services.moonraker.port
  ];
}
