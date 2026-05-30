{
  config,
  lib,
  pkgs,
  ...
}:
let
  usersWithPasswords = [
    "immich"
    "miniflux"
    "paperless"
    "vikunja"
  ];
in
{
  age.secrets = {
    db-password-db-postgres-immich = {
      generator.script = "alnum";
      rekeyFile = config.diffeq.secretsPath + /db/password-db-postgres-immich.age;
    };

    db-password-db-postgres-miniflux = {
      generator.script = "alnum";
      rekeyFile = config.diffeq.secretsPath + /db/password-db-postgres-miniflux.age;
    };

    db-password-db-postgres-paperless = {
      generator.script = "alnum";
      rekeyFile = config.diffeq.secretsPath + /db/password-db-postgres-paperless.age;
    };

    db-password-db-postgres-vikunja = {
      generator.script = "alnum";
      rekeyFile = config.diffeq.secretsPath + /db/password-db-postgres-vikunja.age;
    };
  };

  services.postgresql = {
    enable = true;
    enableTCPIP = true;

    extensions =
      ps: with ps; [
        pgvector # immich
        vectorchord # immich
      ];

    settings = {
      shared_preload_libraries = [
        "vchord.so" # immich
      ];
      search_path = "\"$user\", public, vectors"; # immich
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
      "paperless"
      "vikunja"
    ];

    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
        ensureClauses.login = true; # not sure why this is here.
      }

      {
        name = "miniflux";
        ensureDBOwnership = true;
      }

      {
        name = "paperless";
        ensureDBOwnership = true;
      }

      {
        name = "vikunja";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.postgresql.serviceConfig.LoadCredential = builtins.map (
    userName: "password-${userName}:${config.age.secrets."db-password-db-postgres-${userName}".path}"
  ) usersWithPasswords;

  systemd.services.postgresql.postStart =
    let
      set-all-passwords = pkgs.writeShellScript "psql-set-password" ''
        #!/bin/sh

        set -euo pipefail

        set_password() {
          username=$1

          echo "setting password for $username..."

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

      extensions = [
        "unaccent"
        "uuid-ossp"
        "cube"
        "earthdistance"
        "pg_trgm"
        "vector"
        "vchord"
      ];
      immichSqlFile = pkgs.writeText "immich-pgvectors-setup.sql" ''
        SELECT COALESCE(installed_version, ''') AS vchord_version_before FROM pg_available_extensions WHERE name = 'vchord' \gset

        ${lib.concatMapStringsSep "\n" (ext: "CREATE EXTENSION IF NOT EXISTS \"${ext}\";") extensions}
        ${lib.concatMapStringsSep "\n" (ext: "ALTER EXTENSION \"${ext}\" UPDATE;") extensions}
        ALTER SCHEMA public OWNER TO immich;

        SELECT COALESCE(installed_version, ''') AS vchord_version_after FROM pg_available_extensions WHERE name = 'vchord' \gset

        SELECT (:'vchord_version_before' != ''' AND :'vchord_version_before' != :'vchord_version_after') AS has_vchord_updated \gset
        \if :has_vchord_updated
          REINDEX INDEX face_index;
          REINDEX INDEX clip_index;
        \endif
      '';
    in
    lib.mkAfter ''
      ${set-all-passwords} ${builtins.concatStringsSep " " usersWithPasswords}
      ${lib.getExe' config.services.postgresql.package "psql"} -d "immich" -f "${immichSqlFile}"
    '';
}
