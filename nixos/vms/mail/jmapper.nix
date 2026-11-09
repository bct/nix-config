{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  fqdn = config.diffeq.hostNames.jmap;
  port = 8765;
in
{
  imports = [ inputs.jmapper.nixosModules.default ];

  services.lego-proxy-client = {
    enable = true;
    domains = [ "jmap" ];
    group = "caddy";
  };

  # accounts file, see https://github.com/amaanq/jmapper#config. Bulwark logs in with the
  # account email and its bearer_token (`openssl rand -hex 32`):
  age.secrets.jmapper-accounts = {
    rekeyFile = ./secrets/jmapper-accounts.age;
    owner = config.services.jmapper.user;
    mode = "400";
  };

  age.secrets.jmapper-db-password = {
    rekeyFile = config.diffeq.databases.users.jmapper.agenixRekeyFile;
  };

  # jmapper can't do TLS to postgres, so it talks to a local pgbouncer over a unix socket
  # (peer auth, no password) and pgbouncer connects to the db host over verified TLS.
  services.pgbouncer = {
    enable = true;
    settings = {
      # no listen_addr: unix socket only, at /run/pgbouncer/.s.PGSQL.6432
      pgbouncer = {
        # peer is only allowed inside an hba file
        auth_type = "hba";
        auth_hba_file = "${pkgs.writeText "pgbouncer-hba.conf" ''
          local jmapper jmapper peer
        ''}";
        # also supplies the password pgbouncer uses to log in to the server
        auth_file = "/run/pgbouncer/userlist.txt";
        server_tls_sslmode = "verify-full";
        server_tls_ca_file = "/etc/ssl/certs/ca-certificates.crt";
      };
      databases.jmapper = "host=${config.diffeq.hostNames.postgres} dbname=jmapper user=jmapper";
    };
  };

  systemd.services.pgbouncer = {
    serviceConfig.LoadCredential = [ "db-password:${config.age.secrets.jmapper-db-password.path}" ];
    preStart = ''
      (umask 077; printf '"jmapper" "%s"\n' "$(cat "$CREDENTIALS_DIRECTORY/db-password")" > /run/pgbouncer/userlist.txt)
    '';
  };

  services.jmapper = {
    enable = true;

    # gridlink-mail fetches header:List-Unsubscribe:asText, which RFC 8621 forbids and
    # jmapper rejects with invalidArguments, breaking message display. Allow it until
    # gridlink switches to asRaw.
    package = inputs.jmapper.packages.${pkgs.stdenv.hostPlatform.system}.jmapper.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./jmapper-list-headers-as-text.patch ];
    });

    openFirewall = false;
    createDatabase = false;
    accountsFile = config.age.secrets.jmapper-accounts.path;

    settings.server = {
      bind = "127.0.0.1:${toString port}";
      session_url = "https://${fqdn}";
      cors_origins = [ "https://${fqdn}" ];
      database_url = "host=/run/pgbouncer port=${toString config.services.pgbouncer.settings.pgbouncer.listen_port} user=jmapper dbname=jmapper";
    };
  };

  systemd.services.jmapper = {
    requires = [ "pgbouncer.service" ];
    after = [ "pgbouncer.service" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts.${fqdn} = {
      useACMEHost = fqdn;
      extraConfig = ''
        encode zstd gzip
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
