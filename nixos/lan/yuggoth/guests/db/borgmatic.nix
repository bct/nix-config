{
  self,
  config,
  pkgs,
  ...
}:
{
  imports = [ "${self}/nixos/modules/borgmatic" ];

  diffeq.borgmatic = {
    enable = true;
    backupName = "db";
    sshKeyPath = config.age.secrets.ssh-borg-db.path;

    settings = {
      source_directories = [
        "/var/backups/influxdb/"
      ];

      # state directories must be on a persistent volume.
      borg_base_directory = "/var/lib/borg";
      borgmatic_source_directory = "/var/lib/borgmatic";

      mariadb_databases = [
        {
          name = "all";
          username = "backup";
          password = "\${MYSQL_PASSWORD}";

          # dump each database to a separate file.
          format = "sql";
        }
      ];

      postgresql_databases = [
        {
          name = "all";
          username = "postgres";

          # dump each database to a separate file.
          format = "custom";
        }
      ];

      before_backup = [
        "${config.services.influxdb.package}/bin/influxd backup -portable /var/backups/influxdb/ >/dev/null"
      ];

      after_backup = [
        "rm -rf /var/backups/influxdb/"
      ];

      # retention
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 1;
    };
  };

  # override the borgmatic service to set password environment variables.
  systemd.services.borgmatic.serviceConfig.ExecStart =
    let
      run-borgmatic = pkgs.writeShellScript "run-borgmatic" ''
        set -euo pipefail

        password=$(cat ${config.age.secrets.db-password-db-mysql-backup.path} | tr -d '\n')

        export MYSQL_PASSWORD="$password"

        # see:
        # https://projects.torsion.org/borgmatic-collective/borgmatic/src/branch/main/sample/systemd/borgmatic.service
        # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/tools/backup/borgmatic/default.nix
        ${pkgs.systemd}/bin/systemd-inhibit \
          --who="borgmatic" \
          --what="sleep:shutdown" \
          --why="Prevent interrupting scheduled backup" \
          ${pkgs.borgmatic}/bin/borgmatic --verbosity -2 --syslog-verbosity 1
      '';
    in
    [
      # to override ExecStart we need to explicitly clear it first.
      ""
      "${run-borgmatic}"
    ];

  # config check fails because POSTGRES_PASSWORD isn't set
  services.borgmatic.enableConfigCheck = false;

  age.secrets = {
    db-password-db-mysql-backup.rekeyFile =
      config.diffeq.secretsPath + /db/password-db-mysql-backup.age;
    ssh-borg-db.rekeyFile = config.diffeq.secretsPath + /ssh/borg-db.age;
  };
}
