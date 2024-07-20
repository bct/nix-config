{ inputs, config, lib, ... }:
let
  hostIp6 = "fc00::1:1";
  containerIp6 = "fc00::1:2/7";
  cfgContainerSecrets = config.megahost.container-secrets;
in {
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

  megahost.container-secrets.postgres = {
    passwordPostgres = {
      hostPath = config.age.secrets.password-postgres.path;
    };

    passwordGoatcounter = {
      hostPath = config.age.secrets.password-goatcounter.path;
    };

    passwordWikijs = {
      hostPath = config.age.secrets.password-wikijs.path;
    };
  };

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

      systemd.services.postgresql.serviceConfig.LoadCredential = [
        "password-postgres:${cfgContainerSecrets.postgres.passwordPostgres.containerPath}"
        "password-goatcounter:${cfgContainerSecrets.postgres.passwordGoatcounter.containerPath}"
        "password-wikijs:${cfgContainerSecrets.postgres.passwordWikijs.containerPath}"
      ];
      systemd.services.postgresql.postStart = let
        set-password = pkgs.writeScript "psql-set-password" ''
          #!/bin/sh

          set -euo pipefail

          username=$1
          password_path=$2

          password=$(cat $password_path | tr -d '\n')

          # ensure that our password won't break our weak quoting.
          if ! (echo "$password" | egrep '^[a-zA-Z0-9]+$' >/dev/null); then
            echo "passwords must be alphanumeric!"
            exit 1
          fi

          psql --port=${builtins.toString config.services.postgresql.settings.port} -tA <<EOF
            ALTER USER "$username" WITH PASSWORD '$password';
          EOF
        '';
      in
        lib.mkAfter ''
          ${set-password} postgres $CREDENTIALS_DIRECTORY/password-postgres
          ${set-password} goatcounter $CREDENTIALS_DIRECTORY/password-goatcounter
          ${set-password} wiki-js $CREDENTIALS_DIRECTORY/password-wikijs
        '';
      };
  };

  age.secrets = {
    password-postgres.file = ../../../secrets/db/password-megahost-postgres.age;
    password-goatcounter.file = ../../../secrets/db/password-goatcounter.age;
    password-wikijs.file = ../../../secrets/db/password-wikijs.age;
  };
}
