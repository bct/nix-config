{ inputs, config, lib, ... }:
let
  hostIp6 = "fc00::1:1";
  containerIp6 = "fc00::1:2/7";
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

  containers.postgres = {
    autoStart = true;
    privateNetwork = true;

    hostBridge = "br0";
    localAddress6 = containerIp6;

    bindMounts = {
      "/tmp/agenix/password-goatcounter" = {
        isReadOnly = true;
        hostPath = config.age.secrets.password-goatcounter.path;
      };
    };

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

        ensureDatabases = [ "goatcounter" ];


        ensureUsers = [
          {
            name = "goatcounter";
            ensureDBOwnership = true;
          }
        ];
      };

      systemd.services.postgresql.serviceConfig.LoadCredential = [
        "password-goatcounter:/tmp/agenix/password-goatcounter"
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
            ALTER USER $username WITH PASSWORD '$password';
          EOF
        '';
      in
        lib.mkAfter ''
          ${set-password} goatcounter $CREDENTIALS_DIRECTORY/password-goatcounter
        '';
      };
  };

  age.secrets = {
    password-goatcounter = {
      file = ../../../secrets/db/password-goatcounter.age;
      owner = "root";
      group = "root";
      mode = "600";
    };
  };
}
