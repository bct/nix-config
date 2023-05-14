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

        db_url = "mysql://home_assistant@db.domus.diffeq.com/home_assistant?charset=utf8mb4&read_default_file=/run/agenix/home-assistant-my-cnf";
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

  age.secrets = {
    home-assistant-my-cnf = {
      file = ../../secrets/home-assistant-my-cnf.age;
      owner = "hass";
      group = "hass";
      mode = "600";
    };
  };
}
