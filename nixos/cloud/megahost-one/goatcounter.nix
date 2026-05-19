{ config, ... }:
let
  cfgContainerSecrets = config.megahost.container-secrets;
  cfgContainerNetwork = config.megahost.container-network.bridge-internal.containers;

  goatCounterPort = 4000;
in
{
  containers.goatcounter = {
    autoStart = true;
    privateNetwork = true;

    config =
      { config, pkgs, ... }:
      {
        system.stateVersion = "24.05";

        networking.firewall.allowedTCPPorts = [ goatCounterPort ];

        services.goatcounter = {
          enable = true;
          address = "*";
          port = goatCounterPort;
          proxy = true;

          extraArgs = [
            "-db"
            "postgresql+host=${cfgContainerNetwork.postgres.address6} sslmode=disable"
          ];
        };

        systemd.services.goatcounter = {
          environment = {
            PGPASSFILE = "/run/goatcounter/goatcounter.pgpass";
          };

          serviceConfig = {
            RuntimeDirectory = "goatcounter";

            LoadCredential = [
              "password-goatcounter:${cfgContainerSecrets.goatcounter.passwordGoatcounter.containerPath}"
            ];

            ExecStartPre =
              let
                write-pg-pass = pkgs.writeShellScript "write-pgpass" ''
                  set -euo pipefail

                  password=$(cat $CREDENTIALS_DIRECTORY/password-goatcounter | tr -d '\n')

                  echo "*:*:*:*:$password" >$PGPASSFILE
                  chmod 0600 $PGPASSFILE
                '';
              in
              "${write-pg-pass}";
          };
        };
      };
  };

  age.secrets = {
    password-goatcounter.rekeyFile = config.diffeq.secretsPath + /db/password-goatcounter.age;
  };

  megahost.container-secrets.goatcounter = {
    passwordGoatcounter = {
      hostPath = config.age.secrets.password-goatcounter.path;
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."m.diffeq.com" = {
      serverAliases = [ "m.cats.birdlor.biz" ];
      extraConfig = ''
        reverse_proxy [${cfgContainerNetwork.goatcounter.address6}]:${toString goatCounterPort}
      '';
    };
  };
}
