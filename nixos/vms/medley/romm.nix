{
  inputs,
  pkgs,
  config,
  ...
}:
let
  rommPort = 9054;
  nginxPort = 9055;
in
{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/romm.nix"
  ];

  services.romm = {
    enable = true;
    package = pkgs.unstable.romm;

    nginx.virtualHost = "romm.domus.diffeq.com";
    database = {
      createLocally = false;
      host = "db.domus.diffeq.com";
    };

    port = rommPort;

    # sets:
    # - DB_PASSWD
    # - OIDC_CLIENT_SECRET
    environmentFile = config.age.secrets.romm-env.path;
    extraEnvironment = {
      OIDC_ENABLED = "true";
      OIDC_PROVIDER = "oidc.domus.diffeq.com";
      OIDC_CLIENT_ID = "romm";
      OIDC_REDIRECT_URI = "https://romm.domus.diffeq.com/api/oauth/openid";
      OIDC_SERVER_APPLICATION_URL = "https://${config.diffeq.hostNames.oidc}";
    };
  };

  services.nginx.virtualHosts."romm.domus.diffeq.com".listen = [
    {
      addr = "127.0.0.1";
      port = nginxPort;
      ssl = false;
    }
  ];

  age.secrets = {
    romm-env = {
      rekeyFile = ./secrets/romm-env.age;
      owner = config.services.romm.user;
      group = config.services.romm.group;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."romm.domus.diffeq.com" = {
      useACMEHost = "romm.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString nginxPort}";
    };
  };
}
