{ self, config, lib, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 256;

    volumes = [
      {
        image = "srv.img";
        mountPoint = "/srv";
        size = 1024;
      }
    ];
  };

  age.rekey.hostPubkey = lib.mkIf (builtins.pathExists ../../../../secrets/ssh/host-abrado.pub) ../../../../secrets/ssh/host-abrado.pub;
  age.secrets = {
    password-db-influxdb-abrado = {
      rekeyFile = ../../../../secrets/db/password-db-influxdb-abrado.age;
      owner = "abrado";
      group = "abrado";
    };
  };

  users = {
    groups.abrado = {};
    users.abrado = {
      isNormalUser = true;
      group = "abrado";

      packages = [
        pkgs.python3
        pkgs.unstable.uv
      ];
    };
  };

  systemd.timers.current-temp = {
  wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
      Unit = "current-temp.service";
    };
  };

  systemd.services.current-temp = {
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.unstable.uv}/bin/uv run current-temp.py";
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
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.unstable.uv}/bin/uv run exchange-rates.py";
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
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.unstable.uv}/bin/uv run gas-rates.py";
      LoadCredential = [
        "INFLUXDB_PASSWORD:${config.age.secrets.password-db-influxdb-abrado.path}"
      ];
    };
  };

  systemd.timers.fortis = {
  wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00 UTC";
      Unit = "gas-rates.service";
    };
  };

  systemd.services.gas-rates = {
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scrapers/py";
      ExecStart = "${pkgs.unstable.uv}/bin/uv run gas-rates.py";
      LoadCredential = [
        "INFLUXDB_PASSWORD:${config.age.secrets.password-db-influxdb-abrado.path}"
      ];
    };
  };
}
