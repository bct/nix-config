{ inputs, lib, config, pkgs, ... }: {
  services.home-assistant = {
    enable = true;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    extraComponents = [
      "default_config"
      "met"
      "mqtt"
      "backup"

      "octoprint"
      "kodi"
      "volumio"
      "openweathermap"

      # Zigbee
      "zha"

      # Printer
      "syncthru"
      "ipp"
    ];

    extraPackages = python3Packages: with python3Packages; [
      # enable a mysql connector that allows us to store the db password in a file
      mysqlclient
    ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      recorder = {
        # commit less frequently to reduce wear on the SD card
        commit_interval = 30;

        # keep data around for longer
        purge_keep_days = 30;
      };
    };
  };

  services.mosquitto = {
    enable = true;

    listeners = [
      {
        users = {
          hass = {
            password = "hass";
          };
          octopi = {
            password = "octopi";
          };
        };
      }
    ];
  };

  services.borgmatic = {
    enable = true;

    settings = {
      location = {
        source_directories = [
          "/var/lib/hass"
        ];

        repositories = [
          "ssh://borg@borg.domus.diffeq.com/srv/borg/spectator/"
        ];
      };

      retention = {
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        keep_yearly = 1;
      };
    };
  };
}
