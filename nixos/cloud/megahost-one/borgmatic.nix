{ self, inputs, config, pkgs, ... }: {
  services.borgmatic = {
    enable = true;
    settings = {
      repositories = [
        {
          label = "borg.domus.diffeq.com";
          path = "ssh://borg@borg.domus.diffeq.com/srv/borg/megahost-one.diffeq.com/";
        }
      ];

      source_directories = [
        "/var/lib/nixos-containers/wiki/var/lib/wiki-js"
      ];

      postgresql_databases = [
        {
          name = "all";
          hostname = "fc00::1:2";
          username = "postgres";
          password = "\${POSTGRES_PASSWORD}";

          # dump each database to a separate file.
          format = "custom";

          pg_dump_command = "${pkgs.postgresql}/bin/pg_dump";
          pg_restore_command = "${pkgs.postgresql}/bin/pg_restore";
          psql_command = "${pkgs.postgresql}/bin/psql";
        }
      ];

      ssh_command = "ssh -i ${config.age.secrets.megahost-one-borg-ssh-key.path}";

      # retention
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 1;

      ntfy = {
        topic = "doog4maechoh";
        fail = {
          title = "[megahost-one] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
          states = ["fail"];
        };
      };
    };
  };

  # override the borgmatic service to set password environment variables.
  systemd.services.borgmatic.serviceConfig.ExecStart = let
    run-borgmatic = pkgs.writeScript "run-borgmatic" ''
      #!/bin/sh

      set -euo pipefail

      password=$(cat ${config.age.secrets.password-postgres.path} | tr -d '\n')

      export POSTGRES_PASSWORD="$password"

      # see:
      # https://projects.torsion.org/borgmatic-collective/borgmatic/src/branch/main/sample/systemd/borgmatic.service
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/tools/backup/borgmatic/default.nix
      ${pkgs.systemd}/bin/systemd-inhibit \
        --who="borgmatic" \
        --what="sleep:shutdown" \
        --why="Prevent interrupting scheduled backup" \
        ${pkgs.borgmatic}/bin/borgmatic --verbosity -2 --syslog-verbosity 1
    '';
  in "${run-borgmatic}";

  age.secrets = {
    password-postgres.file = ../../../secrets/db/password-megahost-postgres.age;
    megahost-one-borg-ssh-key.file = ../../../secrets/ssh/megahost-one-borg.age;
  };
}
