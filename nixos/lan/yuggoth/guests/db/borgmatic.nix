{ config, pkgs, ... }: {
  programs.ssh.knownHosts = {
    "borg.domus.diffeq.com".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtsDN0WY1wDki3JNSmGqOmxMR34IrZue4h3Xd+wdYfDOHhHTlk1taNWFGJusSc7hSC7ittGoOmeP6AepCIAhKNce0d9ITA9xAIN40qnFFkW1lUTL6/eE3+CM2VBqYreLy0YiID8K/OfoqppPzHpMB4ijQiSRrtBtGYx5OGtMAQkSSu50XH3s4tzHR0qXnjAi3Ly7pJ47d62MFR4JvpI5LQuIe3zvwW4W1GEYlZHOXDX7bb1cEyEhPeoEJ2AOHCdbtZ7osZyjQtARypWfuTgngpLYVcLErjj9UazUikJn7sBhYgwkaFcjfFn2optnU+3TpjIl4ot59vrwzOKOF634YTUD7iNWOTpdduHUWfK3eAARM4YnAOL3PMhEp/656kQqMPGeM60aSgGWKeBZWycp1VMGtQhZ4BCpFSErYKEi1CKey1xfHMaH5PVFZTJLToUEMzHlLYSbV8AYO25vNppUEfJAk215Al6gHR7o5l0NRlqLL18uo7zFlj75P7nIBsLSk=";
  };

  services.borgmatic = {
    enable = true;

    # config check fails because POSTGRES_PASSWORD isn't set
    enableConfigCheck = false;

    settings = {
      repositories = [
        {
          label = "borg.domus.diffeq.com";
          path = "ssh://borg@borg.domus.diffeq.com/srv/borg/db/";
        }
      ];

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

      ssh_command = "ssh -i ${config.age.secrets.ssh-borg-db.path}";

      # retention
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 1;

      ntfy = {
        topic = "doog4maechoh";
        fail = {
          title = "[db] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
          states = ["fail"];
        };
      };
    };
  };

  # make database commands available to borgmatic.
  systemd.services.borgmatic.path = [
    config.services.mysql.package
    config.services.postgresql.package
  ];

  # override the borgmatic service to set password environment variables.
  systemd.services.borgmatic.serviceConfig.ExecStart = let
    run-borgmatic = pkgs.writeScript "run-borgmatic" ''
      #!/bin/sh

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
  in [
    # to override ExecStart we need to explicitly clear it first.
    ""
    "${run-borgmatic}"
  ];

  age.secrets = {
    db-password-db-mysql-backup.rekeyFile = ../../../../../secrets/db/password-db-mysql-backup.age;
    ssh-borg-db.rekeyFile = ../../../../../secrets/ssh/borg-db.age;
  };
}
