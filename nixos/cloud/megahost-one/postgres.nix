{ config, lib, ... }:
let
  cfgContainerSecrets = config.megahost.container-secrets;

  cfg = config.megahost.postgres;
in {
  options.megahost.postgres = {
    databases = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };

    users = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (
        {config, options, name, ...}: {
          options = {
            passwordFile = lib.mkOption {
              type = lib.types.str;
            };

            ensureDBOwnership = lib.mkOption {
              type = lib.types.bool;
              default = false;
            };
          };
        }
      ));
    };
  };

  config = {
    assertions = builtins.map (username: {
        assertion = !isNull (builtins.match "[-a-z]+" username);
        message = "username \"${username}\" does not match \"[-a-z]+\"";
    }) (lib.attrNames cfg.users);

    megahost.container-secrets.postgres = lib.concatMapAttrs (userName: userConfig: {
      "password-${userName}" = { hostPath = userConfig.passwordFile; };
    }) cfg.users;

    containers.postgres = {
      autoStart = true;
      privateNetwork = true;

      config = { config, pkgs, ... }: {
        system.stateVersion = "24.05";

        networking.firewall.allowedTCPPorts = [ 5432 ];

        services.postgresql = {
          enable = true;
          enableTCPIP = true;

          authentication = ''
            # TYPE  DATABASE        USER            ADDRESS                 METHOD

            # allow "md5" (password) authentication on TCP connections
            host    all             all             ::/0                    md5
          '';

          ensureDatabases = cfg.databases;

          ensureUsers = lib.mapAttrsToList (username: userConfig:
            {
              name = username;
              ensureDBOwnership = userConfig.ensureDBOwnership;
            }) cfg.users;
        };

        systemd.services.postgresql.serviceConfig.LoadCredential = lib.mapAttrsToList (userName: _:
          "password-${userName}:${cfgContainerSecrets.postgres."password-${userName}".containerPath}") cfg.users;

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

          allUsernames = lib.concatStringsSep " " (lib.attrNames cfg.users);
        in
          lib.mkAfter "${set-all-passwords} ${allUsernames}";
      };
    };
  };
}
