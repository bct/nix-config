{ self, config, lib, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
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

  age.rekey.hostPubkey = lib.mkIf (builtins.pathExists ../../../../secrets/ssh/host-grafana.pub) ../../../../secrets/ssh/host-grafana.pub;
  age.secrets = {
    db-password-domus-grafana = {
      rekeyFile = ../../../../secrets/db/password-domus-grafana.age;
      owner = "grafana";
      group = "grafana";
    };
  };

  networking.firewall.allowedTCPPorts = [3000];

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
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
}
