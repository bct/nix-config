{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.schromp-netbird}/nixos/modules/services/networking/netbird/server.nix"
  ];

  disabledModules = [
    "services/networking/netbird/server.nix"
  ];

  # examples:
  # https://github.com/jvanbruegge/server-config/blob/1d77b8b57c6bb44ed9ab5d3bb9c7e3707ab70607/vps/services/netbird.nix

  age.secrets = {
    netbird-mgmt-data-enc = {
      # a base64-encoded secret
      rekeyFile = ./secrets/netbird-mgmt-data-enc.age;
    };

    netbird-relay-secret = {
      rekeyFile = ./secrets/netbird-relay-secret.age;
      generator.script = "alnum";
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
    relay = {
      # >= 0.64.1
      package = pkgs.unstable.netbird-relay;
      authSecretFile = config.age.secrets.netbird-relay-secret.path;
      settings = {
        NB_EXPOSED_ADDRESS = "rels://viator.diffeq.com:443/";
        NB_ENABLE_STUN = "true";
        NB_STUN_PORTS = "3478";
      };
    };

    management = {
      oidcConfigEndpoint = "https://${config.diffeq.hostNames.oidc}/.well-known/openid-configuration";
      turnDomain = "viator.diffeq.com"; # TODO
      settings = {
        DataStoreEncryptionKey._secret = config.age.secrets.netbird-mgmt-data-enc.path;
        Signal.URI = "viator.diffeq.com:443";
        TURNConfig = {
          Turns = [ ];
        };
      };
    };
    coturn = {
      enable = false;
    };
  };

  services.caddy.virtualHosts."viator.diffeq.com" = {
    # https://docs.netbird.io/selfhosted/reverse-proxy#caddy-external
    extraConfig = ''
      # Relay (WebSocket)
      reverse_proxy /relay* localhost:${toString config.services.netbird.server.relay.port}

      # Signal WebSocket
      #reverse_proxy /ws-proxy/signal* netbird-signal:80

      # Signal gRPC (h2c for plaintext HTTP/2)
      reverse_proxy /signalexchange.SignalExchange/* h2c://localhost:${toString config.services.netbird.server.signal.port}

      # Management API
      reverse_proxy /api/* localhost:${toString config.services.netbird.server.management.port}

      # Management WebSocket
      reverse_proxy /ws-proxy/management* localhost:${toString config.services.netbird.server.management.port}

      # Management gRPC
      reverse_proxy /management.ManagementService/* h2c://localhost:${toString config.services.netbird.server.management.port}

      # Dashboard (catch-all)
      root * ${config.services.netbird.server.dashboard.finalDrv}
      #try_files {path} {path}.html {path}/ /index.html
      file_server

      # TODO: allow navigation to non-root URLs
      # search for "netbird try_files caddy"

      header * {
        Strict-Transport-Security "max-age=3600; includeSubDomains; preload"
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        X-XSS-Protection "1; mode=block"
        Referrer-Policy strict-origin-when-cross-origin
      }
    '';
  };

  networking.firewall.allowedUDPPorts = [ 3478 ];
}
