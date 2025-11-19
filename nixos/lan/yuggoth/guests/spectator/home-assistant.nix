{ pkgs, config, ... }: {
  age.secrets = {
    home-assistant-my-cnf = {
      rekeyFile = config.diffeq.secretsPath + /home-assistant-my-cnf.age;
      owner = "hass";
      group = "hass";
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "spectator" ];
    group = "hass";
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  services.home-assistant = {
    enable = true;
    package = pkgs.unstable.home-assistant;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    extraComponents = [
      "default_config"
      "mqtt"
      "backup"

      "octoprint"
      "kodi"
      "dlna_dmr"
      "openweathermap"
      "environment_canada"
      "esphome"

      # Zigbee
      "zha"

      # Printer
      "brother"
      "ipp"
    ];

    extraPackages = python3Packages: with python3Packages; [
      # enable a mysql connector that allows us to store the db password in a file
      mysqlclient
    ];

    config = let
      sslDirectory = "${config.security.acme.certs."spectator.domus.diffeq.com".directory}";
    in {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = {};

      homeassistant = {
        time_zone = "America/Edmonton";
        country = "CA";
        external_url = "https://spectator.domus.diffeq.com:8123";
        internal_url = "https://spectator.domus.diffeq.com:8123";
      };

      http = {
        ssl_certificate = "${sslDirectory}/fullchain.pem";
        ssl_key = "${sslDirectory}/key.pem";
      };

      recorder = {
        # commit less frequently to reduce wear on the SD card
        commit_interval = 30;

        # keep data around for longer
        purge_keep_days = 60;

        # use remote mariadb
        db_url = "mysql://home_assistant@db.domus.diffeq.com/home_assistant?charset=utf8mb4&read_default_file=${config.age.secrets.home-assistant-my-cnf.path}";

        # wait up to 5 minutes for the database to come up.
        # e.g. if there's a power outage it takes TrueNAS some time to bring
        # the joils back up.
        db_max_retries = 30;
        db_retry_wait = 10;
      };

      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
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
}
