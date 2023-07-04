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
      "dlna_dmr"
      "openweathermap"
      "esphome"

      # Zigbee
      "zha"

      # Printer
      "syncthru"
      "ipp"
    ];

    # the nixpkgs version of yarl segfaults on arm. fix taken from:
    # https://github.com/gaelreyrol/nixos-config/commit/90d44c0dffab34edbf5fa45f6371749476a7cb9d
    package = pkgs.home-assistant.override {
      # https://github.com/NixOS/nixpkgs/pull/234880
      packageOverrides = self: super: {
        aiohttp = super.aiohttp.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [
            (pkgs.fetchpatch {
              url = "https://github.com/aio-libs/aiohttp/commit/7dcc235cafe0c4521bbbf92f76aecc82fee33e8b.patch";
              hash = "sha256-ZzhlE50bmA+e2XX2RH1FuWQHZIAa6Dk/hZjxPoX5t4g=";
            })
          ];
        });
        uvloop = super.uvloop.overridePythonAttrs (oldAttrs: {
          disabledTestPaths = oldAttrs.disabledTestPaths ++ [
            "tests/test_regr1.py"
          ];
        });
        yarl = super.yarl.overrideAttrs (oldAttrs: rec {
          version = "1.9.2";
          src = pkgs.fetchPypi {
            inherit (oldAttrs) pname;
            inherit version;
            hash = "sha256-BKudS59YfAbYAcKr/pMXt3zfmWxlqQ1ehOzEUBCCNXE=";
          };
          disabledTests = [ ];
        });
        snitun = super.snitun.overridePythonAttrs (oldAtts: {
          doCheck = false;
        });
        zigpy-znp = super.zigpy-znp.overridePythonAttrs (oldAtts: {
          doCheck = false;
        });
      };
    };

    extraPackages = python3Packages: with python3Packages; [
      # enable a mysql connector that allows us to store the db password in a file
      mysqlclient
    ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      homeassistant = {
        time_zone = "America/Edmonton";
        country = "CA";
      };

      recorder = {
        # commit less frequently to reduce wear on the SD card
        commit_interval = 30;

        # keep data around for longer
        purge_keep_days = 30;

        db_url = "mysql://home_assistant@db.domus.diffeq.com/home_assistant?charset=utf8mb4&read_default_file=${config.age.secrets.home-assistant-my-cnf.path}";
      };

      "automation ui" = "!include automations.yaml";
      "script ui" = "!include scripts.yaml";

      rest_command = {
        stereo_power_toggle = {
          url = "http://stereo.domus.diffeq.com:4646/ssap/power";
          method = "POST";
        };

        stereo_line_1 = {
          url = "http://stereo.domus.diffeq.com:4646/ssap/line-1";
          method = "POST";
        };

        stereo_volume_up = {
          url = "http://stereo.domus.diffeq.com:4646/ssap/volume-up";
          method = "POST";
        };

        stereo_volume_down = {
          url = "http://stereo.domus.diffeq.com:4646/ssap/volume-down";
          method = "POST";
        };
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
