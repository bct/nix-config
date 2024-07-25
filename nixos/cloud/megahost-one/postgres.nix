{ config, lib, ... }:
let
  hostIp6 = "fc00::1:1";
  containerIp6 = "fc00::1:2/7";
  cfgContainerSecrets = config.megahost.container-secrets;

  cfg = config.megahost.postgres;
in {
  options.megahost.postgres = {
    userPasswords = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
    };
  };

  config = {
    assertions = builtins.map (username: {
        assertion = !isNull (builtins.match "[-a-z]+" username);
        message = "username \"${username}\" does not match \"[-a-z]+\"";
    }) (lib.attrNames cfg.userPasswords);

    # https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/containers-bridge.nix
    networking.bridges = {
      br0 = {
        interfaces = [];
      };
    };
    networking.interfaces = {
      br0 = {
        ipv6.addresses = [{ address = hostIp6; prefixLength = 7; }];
      };
    };

    megahost.container-secrets.postgres = lib.concatMapAttrs (userName: hostSecretPath: {
      "password-${userName}" = { hostPath = hostSecretPath; };
    }) cfg.userPasswords;

    containers.postgres = {
      autoStart = true;
      privateNetwork = true;

      hostBridge = "br0";
      localAddress6 = containerIp6;

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

          ensureDatabases = [ "goatcounter" "wiki-js" ];

          ensureUsers = [
            {
              name = "goatcounter";
              ensureDBOwnership = true;
            }

            {
              name = "wiki-js";
              ensureDBOwnership = true;
            }
          ];
        };

        systemd.services.postgresql.serviceConfig.LoadCredential = lib.mapAttrsToList (userName: _:
          "password-${userName}:${cfgContainerSecrets.postgres."password-${userName}".containerPath}") cfg.userPasswords;

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

          allUsernames = lib.concatStringsSep " " (lib.attrNames cfg.userPasswords);
        in
          lib.mkAfter "${set-all-passwords} ${allUsernames}";
      };
    };
  };
}
