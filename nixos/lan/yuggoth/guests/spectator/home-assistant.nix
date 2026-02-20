{
  pkgs,
  config,
  ...
}:
let
  hassPort = 8123;
  mqttPort = 1883;
  zigbee2MqttPort = 8080;
  sslDirectory = "${config.security.acme.certs."spectator.domus.diffeq.com".directory}";
  # zha-quirks-src = pkgs.fetchFromGitHub {
  #   owner = "claudegel";
  #   repo = "sinope-zha";
  #   rev = "39b0dc6d42c98c197a3909b36043781ccaed64e2";
  #   sha256 = "sha256-l6/FX4tQCzJw8on9IsFm6+J17HJcx4xR6vMWVamSCsI=";
  # };
  #
  # zha-quirks = lib.sourceByRegex zha-quirks-src [ ".*\\.py$" ];
in
{
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

  networking.firewall.allowedTCPPorts = [
    hassPort
    zigbee2MqttPort
  ];

  services.home-assistant = {
    enable = true;
    package = pkgs.unstable.home-assistant;

    # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/component-packages.nix
    extraComponents = [
      "default_config"
      "mqtt"
      "backup"

      "octoprint"
      "openweathermap"
      "environment_canada"
      "esphome"

      # Media
      "dlna_dmr"
      "kodi"
      "mpd"

      # Zigbee
      "zha" # not used any more, but it complains at boot if it's not present

      # Printer
      "brother"
      "ipp"
    ];

    extraPackages =
      python3Packages: with python3Packages; [
        # enable a mysql connector that allows us to store the db password in a file
        mysqlclient
      ];

    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };

      homeassistant = {
        time_zone = "America/Edmonton";
        country = "CA";
        external_url = "https://spectator.domus.diffeq.com:${toString hassPort}";
        internal_url = "https://spectator.domus.diffeq.com:${toString hassPort}";
      };

      http = {
        ssl_certificate = "${sslDirectory}/fullchain.pem";
        ssl_key = "${sslDirectory}/key.pem";
      };

      recorder = {
        # keep data around for longer
        purge_keep_days = 60;

        # use remote mariadb
        db_url = "mysql://home_assistant@db.domus.diffeq.com/home_assistant?charset=utf8mb4&read_default_file=${config.age.secrets.home-assistant-my-cnf.path}";

        # wait up to 5 minutes for the database to come up.
        # e.g. if there's a power outage it takes TrueNAS some time to bring
        # the jails back up.
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

      # zha = {
      #   database_path = "${config.services.home-assistant.configDir}/zigbee.db";
      #   enable_quirks = true;
      #   custom_quirks_path = toString zha-quirks;
      # };

      logger = {
        default = "warning";
        logs = {
          # "homeassistant.components.mqtt" = "debug";
          "homeassistant.components.kodi" = "debug";
          "homeassistant.components.kodi.media_player" = "debug";
        };
      };
    };
  };

  services.mosquitto = {
    enable = true;
    #logType = [ "all" ];

    listeners = [
      {
        port = mqttPort;
        users = {
          hass = {
            acl = [ "readwrite #" ];
            password = "hass";
          };
          octopi = {
            acl = [ "readwrite #" ];
            password = "octopi";
          };
          zigbee2mqtt = {
            acl = [ "readwrite #" ];
            password = "zigbee2mqtt";
          };
        };
      }
    ];
  };

  services.zigbee2mqtt = {
    enable = true;
    settings = {
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://localhost:${toString mqttPort}";
        user = "zigbee2mqtt";
        password = "zigbee2mqtt";
      };
      serial = {
        port = "/dev/serial/by-id/usb-Silicon_Labs_Sonoff_Zigbee_3.0_USB_Dongle_Plus_0001-if00-port0";
        adapter = "zstack";
      };
      frontend = {
        enabled = true;
        port = zigbee2MqttPort;
      };
      homeassistant.enabled = true;
    };
  };
}
