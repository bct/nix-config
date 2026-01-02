{ inputs, config, ... }:
# let
#   ldaps_cert = config.security.acme.certs."auth.domus.diffeq.com";
# in
{
  # https://github.com/NixOS/nixpkgs/pull/474559
  # fixes https://github.com/NixOS/nixpkgs/issues/438857
  imports = [
    "${inputs.sweenu-lldap}/nixos/modules/services/databases/lldap.nix"
  ];
  disabledModules = [ "services/databases/lldap.nix" ];

  age.secrets = {
    lldap-env.rekeyFile = ./secrets/lldap-env.age;
    lldap-user-pass.rekeyFile = ./secrets/lldap-user-pass.age;
  };

  services.lldap = {
    enable = true;

    settings = {
      ldap_base_dn = "dc=diffeq,dc=com";
      force_ldap_user_pass_reset = "always";
      ldap_port = 389;

      ldap_user_dn = "bct";
      ldap_user_email = "bct@diffeq.com";

      http_port = 17170;
      http_host = "127.0.0.1";
      # ldaps_options = {
      #   enabled = true;
      #   port = 636;
      #   cert_file = "${ldaps_cert.directory}/cert.pem";
      #   key_file = "${ldaps_cert.directory}/key.pem";
      # };
    };

    # sets LLDAP_JWT_SECRET
    environmentFile = config.age.secrets.lldap-env.path;
    environment.LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.lldap-user-pass.path;
  };

  # allow binding ports below 1024
  systemd.services.lldap.serviceConfig.AmbientCapabilities = "CAP_NET_BIND_SERVICE";

  networking.firewall.allowedTCPPorts = [
    config.services.lldap.settings.ldap_port
  ];

  services.caddy = {
    enable = true;
    virtualHosts."ldap.domus.diffeq.com" = {
      useACMEHost = "ldap.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.lldap.settings.http_port}";
    };
  };
}
