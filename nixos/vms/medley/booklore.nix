{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${inputs.jvanbruegge-booklore}/nixos/modules/services/web-apps/booklore.nix"
  ];

  age.secrets = {
    db-password-domus-booklore = {
      rekeyFile = config.diffeq.secretsPath + /db/password-domus-booklore.age;
      owner = "booklore";
      group = "booklore";
    };
  };

  services.booklore = {
    enable = true;
    package = pkgs.booklore;

    environment = {
      #SPRING_DATASOURCE_URL = "jdbc:mariadb://db.domus.diffeq.com:3306/booklore";
    };

    database = {
      createLocally = false;
      name = "booklore";
      host = "db.domus.diffeq.com";
      user = "booklore";
    };

    secretFiles = {
      DATABASE_PASSWORD = config.age.secrets.db-password-domus-booklore.path;
    };

    nginx.enable = false;
  };

  systemd.services.booklore.serviceConfig.ExecStartPre = lib.mkForce null;

  services.caddy = {
    enable = true;
    virtualHosts."booklore.domus.diffeq.com" = {
      useACMEHost = "booklore.domus.diffeq.com";
      extraConfig = ''
        root * ${config.services.booklore.package}/share/booklore-ui

        handle /api/* {
          reverse_proxy localhost:${toString config.services.booklore.api.port} {
            header_up X-Forwarded-Port 443

            # https://booklore-app.github.io/booklore-docs/docs/integration/kobo#%EF%B8%8F-nginx-proxy-configuration
            response_buffers 128k
          }
        }

        handle /ws {
          reverse_proxy localhost:${toString config.services.booklore.api.port}
        }

        handle {
          try_files {path} /index.html
          file_server
        }
      '';
    };
  };
}
