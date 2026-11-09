{
  config,
  lib,
  pkgs,
  ...
}:
let
  usersWithPasswords = builtins.attrNames config.diffeq.databases.users;
  databases = usersWithPasswords;
in
{
  age.secrets = lib.mapAttrs' (id: u: {
    name = "db-password-db-postgres-${id}";
    value = {
      rekeyFile = u.agenixRekeyFile;
      generator.script = "alnum";
    };
  }) config.diffeq.databases.users;

  services.postgresql = {
    enable = true;
    enableTCPIP = true;

    package = pkgs.postgresql_17;

    extensions =
      ps: with ps; [
        pgvector # immich
        vectorchord # immich
      ];

    settings = {
      shared_preload_libraries = [
        "vchord.so" # immich
      ];
      search_path = "\"$user\", public"; # immich
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

      # allow "scram-sha-256" (password) authentication on TLS connections.
      # when operating remotely everyone may only connect to the
      # database with the same name as their user.
      # TYPE     DATABASE        USER            ADDRESS                 METHOD
      hostssl    sameuser        all             ::/0                    scram-sha-256
      hostssl    sameuser        all             192.168.4.0/24          scram-sha-256
    '';

    identMap = ''
      # allow root & postgres system users to log in as postgres.
      # ARBITRARY_MAP_NAME  SYSTEM_USER   DB_USER
      superuser_map         root          postgres
      superuser_map         postgres      postgres
    '';

    ensureDatabases = databases;
    ensureUsers = map (name: {
      inherit name;
      ensureDBOwnership = true;
    }) usersWithPasswords;
  };

  systemd.services.postgresql-setup.serviceConfig.LoadCredential = map (
    userName: "password-${userName}:${config.age.secrets."db-password-db-postgres-${userName}".path}"
  ) usersWithPasswords;

  systemd.services.postgresql-setup.postStart =
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

          psql --port=${toString config.services.postgresql.settings.port} -tA <<EOF
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
