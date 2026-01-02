{ self, config, ... }:
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "grafana" ];
    group = "caddy";
  };

  age.secrets = {
    db-password-domus-grafana = {
      rekeyFile = config.diffeq.secretsPath + /db/password-domus-grafana.age;
      owner = "grafana";
      group = "grafana";
    };

    dex-grafana-secret = {
      rekeyFile = config.diffeq.secretsPath + /dex/grafana.age;
      owner = "grafana";
      group = "grafana";
      generator.script = "alnum";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.grafana = {
    enable = true;

    settings = {
      analytics = {
        feedback_links_enabled = false;
        reporting_enabled = false;
      };

      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://grafana.domus.diffeq.com/";
      };

      database = {
        type = "mysql";
        host = "db.domus.diffeq.com:3306";
        name = "grafana";
        user = "grafana";
        password = "$__file{${config.age.secrets.db-password-domus-grafana.path}}";
      };

      # https://grafana.com/docs/grafana/latest/setup-grafana/configure-access/configure-authentication/generic-oauth/#set-up-oauth2-with-dex
      "auth.generic_oauth" =
        let
          issuer = "https://auth.domus.diffeq.com";
        in
        {
          enabled = true;
          allow_assign_grafana_admin = true;
          allow_sign_up = true; # otherwise no new users can be created
          api_url = "${issuer}/userinfo";
          auth_url = "${issuer}/auth";
          auto_login = true; # redirect automatically to the only oauth provider
          client_id = "grafana";
          client_secret = "$__file{${config.age.secrets.dex-grafana-secret.path}}";
          disable_login_form = true; # only allow OAuth
          icon = "signin";
          name = "auth.domus.diffeq.com";
          oauth_allow_insecure_email_lookup = true; # otherwise updating the mail in ldap will break login
          use_refresh_token = true;
          role_attribute_path = "contains(groups[*], 'infra-owners') && 'GrafanaAdmin'";
          role_attribute_strict = true; # deny anybody who does not match a "role_attribute_path"
          # https://dexidp.io/docs/custom-scopes-claims-clients/
          scopes = "openid email groups profile offline_access";
          token_url = "${issuer}/token";
        };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."grafana.domus.diffeq.com" = {
      useACMEHost = "grafana.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:3000";
    };
  };
}
