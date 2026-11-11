{
  self,
  config,
  pkgs,
  ...
}:
let
  # Environment for scrapers run via "uv run".
  uvEnvironment = {
    # Use nixpkgs' Python rather than letting uv download a generic-Linux one
    # (which can't run on NixOS). Referencing it here also keeps it in the
    # system closure, so the venv's interpreter won't get garbage-collected
    # out from under it; uv recreates the venv when this path changes.
    UV_PYTHON = "${pkgs.python3}/bin/python3";
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON_PREFERENCE = "only-system";

    # Use the system trust store rather than whatever PyPI certifi is locked.
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt";
  };
in
{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
  };

  microvm = {
    vcpu = 1;
    # need a little extra because we're using "nix run".
    mem = 1024;

    writableStoreOverlay = "/nix/.rw-store";

    volumes = [
      {
        image = "srv.img";
        mountPoint = "/srv";
        size = 1024;
      }

      {
        image = "/dev/mapper/ssdpool-abrado--nix--store--overlay";
        mountPoint = config.microvm.writableStoreOverlay;
        autoCreate = false;
      }
    ];
  };

  age.secrets = {
    password-db-influxdb-abrado = {
      rekeyFile = config.diffeq.secretsPath + /db/password-db-influxdb-abrado.age;
      owner = "abrado";
      group = "abrado";
    };

    config-fortis = {
      rekeyFile = ./abrado/secrets/config-fortis.age;
      owner = "abrado";
      group = "abrado";
    };

    config-cgwm = {
      rekeyFile = ./abrado/secrets/config-cgwm.age;
      owner = "abrado";
      group = "abrado";
    };
  };

  users = {
    groups.abrado = { };
    users.abrado = {
      isNormalUser = true;
      group = "abrado";

      packages = [
        pkgs.python3
        pkgs.uv
      ];
    };
  };

  systemd.timers.current-temp = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30m";
      OnUnitActiveSec = "30m";
      Unit = "current-temp.service";
    };
  };

  systemd.services.current-temp = {
    environment = uvEnvironment;
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.uv}/bin/uv run current-temp.py";
      LoadCredential = [
        "INFLUXDB_PASSWORD:${config.age.secrets.password-db-influxdb-abrado.path}"
      ];
    };
  };

  systemd.timers.exchange-rates = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00 UTC";
      Unit = "exchange-rates.service";
    };
  };

  systemd.services.exchange-rates = {
    environment = uvEnvironment;
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.uv}/bin/uv run exchange-rates.py";
      LoadCredential = [
        "INFLUXDB_PASSWORD:${config.age.secrets.password-db-influxdb-abrado.path}"
      ];
    };
  };

  systemd.timers.gas-rates = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00 UTC";
      Unit = "gas-rates.service";
    };
  };

  systemd.services.gas-rates = {
    environment = uvEnvironment;
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.uv}/bin/uv run gas-rates.py";
      LoadCredential = [
        "INFLUXDB_PASSWORD:${config.age.secrets.password-db-influxdb-abrado.path}"
      ];
    };
  };

  systemd.timers.fortis = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # run every ~3 days
      # when I ran more frequently than this I stopped getting any data at all.
      OnCalendar = "*-*-2,5,8,11,14,17,20,23,26,29 02:45:00 UTC";
      Unit = "fortis.service";
    };
  };

  systemd.services.fortis = {
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      # using path: syntax so that the service doesn't need access to git.
      ExecStart = "/srv/nix-profile/fortis/bin/fortis-sync --config ${config.age.secrets.config-fortis.path}";
    };
  };

  systemd.timers.cgwm = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "17:00 America/Edmonton";
      RandomizedDelaySec = "10m";
      Unit = "cgwm.service";
    };
  };

  systemd.services.cgwm = {
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";
      WorkingDirectory = "/srv/scraper-data/cgwm";

      # using path: syntax so that the service doesn't need access to git.
      ExecStart = "/srv/nix-profile/cgwm/bin/cgwm-sync --scrape --credentials-path ${config.age.secrets.config-cgwm.path}";
      Restart = "no";
    };
  };
}
