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
  containers.wiki = {
    autoStart = true;
    privateNetwork = true;

    config =
      { config, ... }:
      {
        system.stateVersion = "24.05";

        networking.firewall.allowedTCPPorts = [ 3000 ];

        services.wiki-js = {
          enable = true;
          settings = {
            bindIP = "::"; # listen on all IPv6 (and IPv4?) interfaces
            port = 3000;

            db = {
              db = "wiki-js";
              user = "wiki-js";
              host = cfgContainerNetwork.postgres.address6;
              pass = "$(DB_PASS)";
            };
          };
        };

        systemd.services.wiki-js.serviceConfig = {
          LoadCredential = [
            "password-wikijs:${cfgContainerSecrets.wiki.passwordWikijs.containerPath}"
          ];

          ExecStart =
            let
              run-wikijs = pkgs.writeShellScript "run-wikijs" ''
                set -euo pipefail

                export DB_PASS=$(cat $CREDENTIALS_DIRECTORY/password-wikijs | tr -d '\n')

                ${pkgs.nodejs_22}/bin/node ${pkgs.wiki-js}/server
              '';
            in
            lib.mkForce "${run-wikijs}";
        };
      };
  };

  megahost.container-secrets.wiki = {
    passwordWikijs = {
      hostPath = config.age.secrets.password-wikijs.path;
    };
  };

  age.secrets = {
    password-wikijs.rekeyFile = config.diffeq.secretsPath + /db/password-wikijs.age;
  };

  services.caddy = {
    enable = true;
    virtualHosts."notes.diffeq.com".extraConfig = ''
      reverse_proxy [${cfgContainerNetwork.wiki.address6}]:3000
    '';
  };

  # bind mount data directory to the host for convenience
  fileSystems."/srv/data/wiki" = {
    device = "/var/lib/nixos-containers/wiki/var/lib/private/wiki-js/";
    options = [ "bind" ];
  };
}
