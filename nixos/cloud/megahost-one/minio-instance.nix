{ lib, config, ... }:

with lib;

let
  cfg = config.megahost.minio;
  cfgContainerSecrets = config.megahost.container-secrets;
  consoleSubdomain = "console";
  bucketPort = 9000;
  consolePort = 9001;
in {
  options.megahost.minio = {
    enable = mkEnableOption "megahost.minio";

    instances = mkOption {
      type = types.attrsOf (types.submodule (
        {config, options, name, ...}: {
          options = {
            hostAddress6 = mkOption {
              type = types.str;
            };

            containerAddress6 = mkOption {
              type = types.str;
            };

            rootCredentialsPath = mkOption {
              type = types.path;
            };

            minioDomain = mkOption {
              type = types.str;
            };

            buckets = mkOption {
              type = types.listOf types.str;
            };
          };
        }
      ));
    };
  };

  # set up a container to run minio
  config = lib.mkIf cfg.enable {
    megahost.container-secrets = lib.mapAttrs (containerName: instanceConfig:
      {
        minioRootCredentials = {
          hostPath = instanceConfig.rootCredentialsPath;
        };
      }
    ) cfg.instances;

    containers = lib.mapAttrs (containerName: instanceConfig: {
      autoStart = true;
      privateNetwork = true;

      hostAddress6 = instanceConfig.hostAddress6;
      localAddress6 = instanceConfig.containerAddress6;

      config = { config, pkgs, ... }: {
        system.stateVersion = "24.05";

        networking.firewall.allowedTCPPorts = [ bucketPort consolePort ];

        services.minio = {
          enable = true;
          rootCredentialsFile = cfgContainerSecrets.${containerName}.minioRootCredentials.containerPath;
        };
        systemd.services.minio.environment.MINIO_DOMAIN = instanceConfig.minioDomain;
      };
    }) cfg.instances;

    # the host reverse proxies to each container.
    services.caddy = {
      enable = true;

      virtualHosts = lib.concatMapAttrs (containerName: instanceConfig: {
        # buckets are accessible on container port 9000
        # TODO: use the acme-zoneedit module to get a wildcard certificate, so that
        # we don't need to explicitly list buckets here.
        ${instanceConfig.minioDomain} = {
          serverAliases = map (bucket: "${bucket}.${instanceConfig.minioDomain}") instanceConfig.buckets;
          extraConfig = ''
            reverse_proxy [${instanceConfig.containerAddress6}]:${toString bucketPort}
          '';
        };

        # the admin console runs on container port 9001
        "${consoleSubdomain}.${instanceConfig.minioDomain}" = {
          extraConfig = ''
            reverse_proxy [${instanceConfig.containerAddress6}]:${toString consolePort}
          '';
        };
      }) cfg.instances;
    };
  };
}
