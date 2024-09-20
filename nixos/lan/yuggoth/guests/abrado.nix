{ self, config, lib, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  # don't throw away our nix-based scraper deploys
  nix.gc.automatic = false;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
  };

  microvm = {
    vcpu = 1;
    mem = 512;

    writableStoreOverlay = "/nix/.rw-store";

    volumes = [
      {
        image = "srv.img";
        mountPoint = "/srv";
        size = 1024;
      }

      {
        image = "nix-store-overlay.img";
        mountPoint = config.microvm.writableStoreOverlay;
        size = 2048;
        # with the default bytes-per-inode of 16384, a 1GB volume only gets
        # 65536 inodes. that runs out quickly!
        mkfsExtraArgs = ["-i" "8192"];
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
      # run every ~3 days
      # when I ran more frequently than this I stopped getting any data at all.
      OnCalendar = "*-*-1,4,7,10,13,16,19,22,25,28,31 02:45:00 UTC";
      Unit = "fortis.service";
    };
  };

  systemd.services.fortis = {
    serviceConfig = {
      Type = "oneshot";
      User = "abrado";

      WorkingDirectory = "/srv/scraper-data/fortis";
      # using path: syntax so that the service doesn't need access to git.
      ExecStart = "${config.nix.package}/bin/nix run path:/srv/scrapers/fortis";
    };
  };
}
