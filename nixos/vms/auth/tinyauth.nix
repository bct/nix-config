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
    "${inputs.nixpkgs-unstable}/nixos/modules/services/security/tinyauth.nix"
  ];

  age.secrets = {
    tinyauth-env = {
      rekeyFile = ./secrets/tinyauth-env.age;
    };
  };

  services.tinyauth = {
    enable = true;
    package = pkgs.unstable.tinyauth;
    settings = {
      APPURL = "https://${config.diffeq.hostNames.auth}";
      PORT = port;
      LDAP_ADDRESS = "ldap://localhost:389/";
      LDAP_BASEDN = "ou=people,dc=diffeq,dc=com";

      LDAP_BINDDN = "uid=ldap,ou=people,dc=diffeq,dc=com";

      #LOG_LEVEL = "debug";
    };

    # sets TINYAUTH_LDAP_BINDPASSWORD
    environmentFile = config.age.secrets.tinyauth-env.path;
  };
  systemd.services.tinyauth.after = [ "lldap.service" ];

  services.caddy = {
    enable = true;
    virtualHosts.${config.diffeq.hostNames.auth} = {
      useACMEHost = config.diffeq.hostNames.auth;
      extraConfig = ''
        reverse_proxy localhost:${toString port} {
          # ensure that the X-Forwarded-Host header is passed through.
          # without this tinyauth won't redirect back to the original app.
          #
          # we could have the app talk directly to tinyauth rather than going
          # through caddy, but then we wouldn't have HTTPS.
          trusted_proxies private_ranges
        }
      '';
    };
  };
}
