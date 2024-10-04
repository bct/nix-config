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

    # https://www.postgresql.org/docs/current/auth-pg-hba-conf.html
    # The first record with a matching connection type, client address,
    # requested database, and user name is used to perform authentication. There
    # is no “fall-through” or “backup”: if one record is chosen and the
    # authentication fails, subsequent records are not considered. If no record
    # matches, access is denied.
    authentication = ''
      # allow root to log in as postgres
      # TYPE  DATABASE  USER  AUTH_METHOD [AUTH_OPTIONS]
      local   all       all   peer        map=superuser_map

      # allow "md5" (password) authentication on TCP connections
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      host    all             all             ::/0                    md5
    '';

    identMap = ''
      # allow root & postgres system users to log in as postgres.
      # ARBITRARY_MAP_NAME  SYSTEM_USER   DB_USER
      superuser_map         root          postgres
      superuser_map         postgres      postgres
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
    immichSqlFile = pkgs.writeText "immich-pgvectors-setup.sql" ''
      CREATE EXTENSION IF NOT EXISTS unaccent;
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      CREATE EXTENSION IF NOT EXISTS vectors;
      CREATE EXTENSION IF NOT EXISTS cube;
      CREATE EXTENSION IF NOT EXISTS earthdistance;
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      ALTER SCHEMA public OWNER TO immich;
      ALTER SCHEMA vectors OWNER TO immich;
      GRANT SELECT ON TABLE pg_vector_index_stat TO immich;
      ALTER EXTENSION vectors UPDATE;
    '';
  in
  lib.mkAfter ''
    ${set-all-passwords} miniflux immich
    ${lib.getExe' config.services.postgresql.package "psql"} -d "immich" -f "${immichSqlFile}"
  '';
}
