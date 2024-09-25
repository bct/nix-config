{ config, lib, pkgs, ... }: {
  age.secrets = {
    db-password-db-postgres-immich = {
      generator.script = "alnum";
      rekeyFile = ../../../../../secrets/db/password-db-postgres-immich.age;
    };

    db-password-db-postgres-miniflux = {
      generator.script = "alnum";
      rekeyFile = ../../../../../secrets/db/password-db-postgres-miniflux.age;
    };
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;

    extraPlugins = ps: with ps; [
      pgvecto-rs # immich
    ];

    settings = {
      shared_preload_libraries = [ "vectors.so" ];
      search_path = "\"$user\", public, vectors";
    };

    authentication = ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD

      # allow "md5" (password) authentication on TCP connections
      host    all             all             ::/0                    md5
    '';

    ensureDatabases = [
      "immich"
      "miniflux"
    ];

    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }

      {
        name = "miniflux";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.postgresql.serviceConfig.LoadCredential = builtins.map (userName:
    "password-${userName}:${config.age.secrets."db-password-db-postgres-${userName}".path}") [ "immich" "miniflux" ];

  systemd.services.postgresql.postStart = let
    set-all-passwords = pkgs.writeShellScript "psql-set-password" ''
      #!/bin/sh

      set -euo pipefail

      set_password() {
        username=$1
        password_path="$CREDENTIALS_DIRECTORY/password-$username"
        password=$(cat $password_path | tr -d '\n')

        # ensure that our password won't break our weak quoting.
        if ! (echo "$password" | egrep '^[a-zA-Z0-9]+$' >/dev/null); then
          echo "passwords must be alphanumeric!"
          exit 1
        fi

        psql --port=${builtins.toString config.services.postgresql.settings.port} -tA <<EOF
          ALTER USER "$username" WITH PASSWORD '$password';
      EOF
      }

      for username in $@; do
        set_password "$username"
      done
    '';
  in
    lib.mkAfter "${set-all-passwords} miniflux immich";
}
