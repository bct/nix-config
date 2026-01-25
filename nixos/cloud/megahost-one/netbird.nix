{ config, ... }:
{
  # TODO
  # evaluation warning: The TURNConfig.secret is world-readable in the Nix Store, you should provide it as a _secret.
  # evaluation warning: A Turn configuration's password is world-readable in the Nix Store, you should provide it as a _secret.

  age.secrets = {
    netbird-mgmt-data-enc = {
      # a base64-encoded secret
      rekeyFile = ./secrets/netbird-mgmt-data-enc.age;
    };
  };

  services.netbird.server = {
    enable = true;
    domain = "viator.diffeq.com";
    dashboard = {
      settings = {
        AUTH_AUTHORITY = "https://${config.diffeq.hostNames.oidc}/";
        AUTH_AUDIENCE = "netbird";
        AUTH_CLIENT_ID = "netbird";
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access";
        USE_AUTH0 = "false";
      };
    };
    management = {
      oidcConfigEndpoint = "https://${config.diffeq.hostNames.oidc}/.well-known/openid-configuration";
      turnDomain = "turn.diffeq.com";
      settings = {
        DataStoreEncryptionKey._secret = config.age.secrets.netbird-mgmt-data-enc.path;
      };
    };
  };

  services.caddy.virtualHosts."viator.diffeq.com" = {
    extraConfig = ''
      root * ${config.services.netbird.server.dashboard.finalDrv}

      reverse_proxy /signalexchange.SignalExchange/* h2c://localhost:${toString config.services.netbird.server.signal.port}
      reverse_proxy /api/* localhost:${toString config.services.netbird.server.management.port}
      reverse_proxy /management.ManagementService/* h2c://localhost:${toString config.services.netbird.server.management.port}

      file_server

      header * {
        Strict-Transport-Security "max-age=3600; includeSubDomains; preload"
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
      }

      # TODO: allow navigation to non-root URLs
      # search for "netbird try_files caddy"
    '';
  };
}
