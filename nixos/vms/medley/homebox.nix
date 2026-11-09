{ config, ... }:
let
  port = 7745;
in
{
  age.secrets = {
    homebox-db-password = {
      rekeyFile = config.diffeq.databases.users.homebox.agenixRekeyFile;
    };
    homebox-openid-clientsecret = {
      rekeyFile = config.diffeq.oidc.services.homebox.agenixRekeyFile;
    };
  };

  services.homebox = {
    enable = true;
    settings = {
      HBOX_WEB_PORT = toString port;
      HBOX_OPTIONS_TRUST_PROXY = "true";
      HBOX_MODE = "production";

      HBOX_OIDC_ENABLED = "true";
      HBOX_OIDC_ISSUER_URL = "https://${config.diffeq.hostNames.oidc}/";
      HBOX_OIDC_CLIENT_ID = "homebox";
      HBOX_OPTIONS_ALLOW_LOCAL_LOGIN = "false";

      HBOX_DATABASE_DRIVER = "postgres";
      HBOX_DATABASE_HOST = "db.domus.diffeq.com";
      HBOX_DATABASE_PORT = "5432";
      HBOX_DATABASE_USERNAME = "homebox";
      HBOX_DATABASE_DATABASE = "homebox";

      HBOX_DATABASE_SSL_MODE = "verify-full";
    };

    secrets = {
      HBOX_OIDC_CLIENT_SECRET = config.age.secrets.homebox-openid-clientsecret.path;
      HBOX_DATABASE_PASSWORD = config.age.secrets.homebox-db-password.path;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."inventory.domus.diffeq.com" = {
      useACMEHost = "inventory.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString port}";
    };
  };
}
