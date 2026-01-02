{ inputs, config, ... }:
{
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
      ldap_base_dn = "dc=domus,dc=diffeq,dc=com";
      force_ldap_user_pass_reset = "always";
    };

    # sets LLDAP_JWT_SECRET
    environmentFile = config.age.secrets.lldap-env.path;
    environment.LLDAP_LDAP_USER_PASS_FILE = config.age.secrets.lldap-user-pass.path;
  };

  networking.firewall.allowedTCPPorts = [ 17170 ];
}
