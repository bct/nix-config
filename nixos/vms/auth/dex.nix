{ config, lib, ... }:
let
  port = 5556;

  servicesWithSecrets = lib.filterAttrs (_: s: !s.public) config.diffeq.oidc.services;
  serviceClientSecrets = lib.mapAttrs' (id: s: {
    name = "dex-${id}-secret";
    value = {
      rekeyFile = s.agenixRekeyFile;
      generator.script = "alnum";
    };
  }) servicesWithSecrets;
in
{
  age.secrets = {
    dex-env = {
      rekeyFile = ./secrets/dex-env.age;
    };
  }
  // serviceClientSecrets;

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

      staticClients = lib.mapAttrsToList (
        id: svcConfig:
        {
          inherit id;
          inherit (svcConfig) redirectURIs;
          name = svcConfig.displayName;
        }
        // (
          if svcConfig.public then
            { public = true; }
          else
            { secretFile = config.age.secrets."dex-${id}-secret".path; }
        )
      ) config.diffeq.oidc.services;

      web = {
        allowedOrigins = [ "*" ];
      };
      oauth2 = {
        responseTypes = [ "code" ];
        skipApprovalScreen = true;
      };
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
