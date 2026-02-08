{
  config,
  pkgs,
  ...
}:

{
  age.secrets = {
    vikunja-db-password = {
      generator.script = "alnum";
      rekeyFile = config.diffeq.secretsPath + /db/password-db-postgres-vikunja.age;
    };
    vikunja-openid-clientsecret = {
      rekeyFile = config.diffeq.secretsPath + /dex/vikunja.age;
      generator.script = "alnum";
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
    package = pkgs.unstable.vikunja; # for 1.0

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

        # TODO: remove this once we're on a module version that sets it
        publicurl = "https://tasks.domus.diffeq.com/";
      };
    };

    database = {
      type = "postgres";
      database = "vikunja";
      user = "vikunja";
      host = config.diffeq.hostNames.db;
    };
  };

  systemd.services.vikunja = {
    serviceConfig = {
      LoadCredential = [
        "db-password:${config.age.secrets.vikunja-db-password.path}"
        "openid-clientsecret:${config.age.secrets.vikunja-openid-clientsecret.path}"
      ];
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
