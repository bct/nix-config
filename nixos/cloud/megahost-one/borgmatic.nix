{ self, config, pkgs, ... }:

let
  cfgContainerNetwork = config.megahost.container-network.bridge0.containers;
in {
  imports = [ "${self}/nixos/modules/borgmatic" ];

  diffeq.borgmatic = {
    enable = true;
    backupName = "megahost-one.diffeq.com";
    sshKeyPath = config.age.secrets.megahost-one-borg-ssh-key.path;

    settings = {
      source_directories = [
        "/srv/data/"
      ];

      postgresql_databases = [
        {
          name = "all";
          hostname = cfgContainerNetwork.postgres.address6;
          username = "postgres";
          password = "\${POSTGRES_PASSWORD}";

          # dump each database to a separate file.
          format = "custom";

          pg_dump_command = "${pkgs.postgresql}/bin/pg_dump";
          pg_restore_command = "${pkgs.postgresql}/bin/pg_restore";
          psql_command = "${pkgs.postgresql}/bin/psql";
        }
      ];

      # retention
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 1;
    };
  };

  # override the borgmatic service to set password environment variables.
  systemd.services.borgmatic.serviceConfig.ExecStart = let
    run-borgmatic = pkgs.writeShellScript "run-borgmatic" ''
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
  in [
    # to override ExecStart we need to explicitly clear it first.
    ""
    "${run-borgmatic}"
  ];

  # config check fails because POSTGRES_PASSWORD isn't set
  services.borgmatic.enableConfigCheck = false;

  age.secrets = {
    password-postgres.rekeyFile = config.diffeq.secretsPath + /db/password-megahost-postgres.age;
    megahost-one-borg-ssh-key.rekeyFile = config.diffeq.secretsPath + /ssh/megahost-one-borg.age;
  };
}
