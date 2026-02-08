{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfgContainerSecrets = config.megahost.container-secrets;
  cfgContainerNetwork = config.megahost.container-network.bridge-internal.containers;
in
{
  containers.vikunja = {
    autoStart = true;
    privateNetwork = true;

    config =
      { config, ... }:
      {
        system.stateVersion = "24.05";

        environment.systemPackages = with pkgs; [
          # for the "vikunja" cli tool
          vikunja
        ];

        networking.firewall.allowedTCPPorts = [ 3456 ];

        services.vikunja = {
          enable = true;
          frontendScheme = "https";
          frontendHostname = "tasks.diffeq.com";
          package = pkgs.unstable.vikunja; # for 1.0

          database = {
            type = "postgres";
            database = "vikunja";
            user = "vikunja";
            host = cfgContainerNetwork.postgres.address6;
          };

          settings.service = {
            enableregistration = false;

            # (•‿•)
            allowiconchanges = false;

            # TODO: remove this once we're on a module version that sets it
            publicurl = "https://tasks.domus.diffeq.com/";
          };
        };

        systemd.services.vikunja.serviceConfig = {
          LoadCredential = [
            "password-vikunja:${cfgContainerSecrets.vikunja.passwordVikunja.containerPath}"
          ];

          ExecStart =
            let
              run-vikunja = pkgs.writeShellScript "run-vikunja" ''
                set -euo pipefail

                export VIKUNJA_DATABASE_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/password-vikunja | tr -d '\n')

                ${config.services.vikunja.package}/bin/vikunja
              '';
            in
            lib.mkForce "${run-vikunja}";
        };
      };
  };

  megahost.container-secrets.vikunja = {
    passwordVikunja = {
      hostPath = config.age.secrets.password-vikunja.path;
    };
  };

  age.secrets = {
    password-vikunja.rekeyFile = config.diffeq.secretsPath + /db/password-vikunja.age;
  };

  services.caddy = {
    enable = true;

    virtualHosts."tasks.diffeq.com".extraConfig = ''
      reverse_proxy [${cfgContainerNetwork.vikunja.address6}]:3456
    '';
  };

  # bind mount data directory to the host for convenience
  fileSystems."/srv/data/vikunja" = {
    device = "/var/lib/nixos-containers/vikunja/var/lib/private/vikunja/";
    options = [ "bind" ];
  };
}
