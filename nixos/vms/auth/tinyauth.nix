{
  config,
  inputs,
  pkgs,
  ...
}:
let
  port = 3000;
in
{
  imports = [
    "${inputs.shaunren-tinyauth}/nixos/modules/services/security/tinyauth.nix"
  ];

  age.secrets = {
    tinyauth-env = {
      rekeyFile = ./secrets/tinyauth-env.age;
    };
  };

  services.tinyauth = {
    enable = true;
    package = inputs.shaunren-tinyauth.legacyPackages.${pkgs.stdenv.hostPlatform.system}.tinyauth;
    settings = {
      APP_URL = "https://${config.diffeq.hostNames.auth}";
      PORT = port;
      DISABLE_ANALYTICS = true;
      LDAP_ADDRESS = "ldap://localhost:389/";
      LDAP_BASE_DN = "ou=people,dc=diffeq,dc=com";

      LDAP_BIND_DN = "uid=ldap,ou=people,dc=diffeq,dc=com";
    };

    # sets LDAP_BIND_PASSWORD
    environmentFile = config.age.secrets.tinyauth-env.path;
  };

  services.caddy = {
    enable = true;
    virtualHosts.${config.diffeq.hostNames.auth} = {
      useACMEHost = config.diffeq.hostNames.auth;
      extraConfig = "reverse_proxy localhost:${toString port}";
    };
  };
}
