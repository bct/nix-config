{ config, ... }:
let
  port = 5556;
in
{
  age.secrets = {
    dex-env = {
      rekeyFile = ./secrets/dex-env.age;
    };

    dex-grafana-secret = {
      rekeyFile = config.diffeq.secretsPath + /dex/grafana.age;
      generator.script = "alnum";
    };

    dex-immich-secret = {
      rekeyFile = config.diffeq.secretsPath + /dex/immich.age;
      generator.script = "alnum";
    };
  };

  services.dex = {
    enable = true;
    # sets DEX_SEARCH_USER_PASSWORD
    environmentFile = config.age.secrets.dex-env.path;
    settings = {
      issuer = "https://${config.diffeq.hostNames.oidc}/";
      web = {
        http = "127.0.0.1:${toString port}";
      };
      storage = {
        type = "sqlite3";
        config.host = "/var/lib/dex/dex.db";
      };
      enablePasswordDB = false;
      connectors = [
        {
          type = "ldap";
          id = "ldap";
          name = "LDAP";
          config = {
            host = "localhost";
            insecureNoSSL = true; # we're on localhost, this is fine.

            # ldap service account
            bindDN = "uid=ldap,ou=people,dc=diffeq,dc=com";
            bindPW = "$DEX_SEARCH_USER_PASSWORD";
            userSearch = {
              baseDN = "ou=people,dc=diffeq,dc=com";
              filter = "(memberOf=people)";
              username = "uid";
              idAttr = "uid";
              emailAttr = "mail";
              nameAttr = "displayName";
              preferredUsernameAttr = "uid";
            };
            groupSearch = {
              baseDN = "ou=groups,dc=diffeq,dc=com";
              filter = "(objectClass=groupOfUniqueNames)";
              userMatchers = [
                {
                  userAttr = "DN";
                  groupAttr = "member";
                }
              ];
              nameAttr = "cn";
            };
          };
        }
      ];
      staticClients = [
        {
          id = "grafana";
          name = "Grafana";
          secretFile = config.age.secrets.dex-grafana-secret.path;
          redirectURIs = [ "https://grafana.domus.diffeq.com/login/generic_oauth" ];
        }
        # https://docs.immich.app/administration/oauth/
        {
          id = "immich";
          name = "Immich";
          secretFile = config.age.secrets.dex-immich-secret.path;
          redirectURIs = [
            "app.immich:///oauth-callback"
            "https://immich.domus.diffeq.com/auth/login"
            "https://immich.domus.diffeq.com/user-settings"
          ];
        }
      ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts.${config.diffeq.hostNames.oidc} = {
      useACMEHost = config.diffeq.hostNames.oidc;
      extraConfig = "reverse_proxy localhost:${toString port}";
    };
  };

  systemd.services.dex.serviceConfig = {
    # `dex.service` is super locked down out of the box, but we need some
    # place to write the SQLite database. This creates $STATE_DIRECTORY below
    # /var/lib/private because DynamicUser=true, but it gets symlinked into
    # /var/lib/dex inside the unit
    StateDirectory = "dex";
  };
}
