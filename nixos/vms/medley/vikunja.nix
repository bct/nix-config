{
  config,
  pkgs,
  ...
}:

{
  age.secrets = {
    vikunja-db-password = {
      rekeyFile = config.diffeq.databases.users.vikunja.agenixRekeyFile;
    };
    vikunja-openid-clientsecret = {
      rekeyFile = config.diffeq.oidc.services.vikunja.agenixRekeyFile;
    };
  };

  environment.systemPackages = [
    # for the "vikunja" cli tool
    config.services.vikunja.package
  ];

  services.vikunja = {
    enable = true;
    frontendScheme = "https";
    frontendHostname = "tasks.domus.diffeq.com";
    package = pkgs.vikunja;

    settings = {
      auth.local.enabled = false;
      auth.openid = {
        enabled = true;
        providers.domus = {
          name = "domus";
          authurl = "https://${config.diffeq.hostNames.oidc}/";
          clientid = "vikunja";
          clientsecret.file = "/run/credentials/vikunja.service/openid-clientsecret";
          scope = "openid profile email";
          forceuserinfo = false;
        };
      };

      service = {
        enableregistration = false;

        # (•‿•)
        allowiconchanges = false;
      };

      database.sslmode = "verify-full";
    };

    database = {
      type = "postgres";
      database = "vikunja";
      user = "vikunja";
      host = config.diffeq.hostNames.db;
    };
  };

  systemd.services.vikunja = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      LoadCredential = [
        "db-password:${config.age.secrets.vikunja-db-password.path}"
        "openid-clientsecret:${config.age.secrets.vikunja-openid-clientsecret.path}"
      ];
      RestartSec = "30";
    };
    environment.VIKUNJA_DATABASE_PASSWORD_FILE = "/run/credentials/vikunja.service/db-password";
  };

  services.caddy = {
    virtualHosts."tasks.domus.diffeq.com" = {
      useACMEHost = "tasks.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.vikunja.port}";
    };
  };
}
