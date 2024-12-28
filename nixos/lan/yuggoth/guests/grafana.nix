{ self, config, ... }: {
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

  age.secrets = {
    db-password-domus-grafana = {
      rekeyFile = ../../../../secrets/db/password-domus-grafana.age;
      owner = "grafana";
      group = "grafana";
    };
  };

  networking.firewall.allowedTCPPorts = [80 443];

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };

      database = {
        type = "mysql";
        host = "db.domus.diffeq.com:3306";
        name = "grafana";
        user = "grafana";
        password = "$__file{${config.age.secrets.db-password-domus-grafana.path}}";
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
