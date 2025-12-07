{
  self,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./db/borgmatic.nix
    ./db/postgres.nix
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 1536;

    volumes = [
      {
        image = "/dev/mapper/fastpool-db--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  environment.systemPackages = [
    config.services.mysql.package
    config.services.influxdb.package
    config.services.postgresql.package
  ];

  networking.firewall.allowedTCPPorts = [
    3306 # mysql
    5432 # postgres
    8086 # influxdb
  ];

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # TODO: services.influxdb2?
  services.influxdb = {
    enable = true;

    extraConfig = {
      reporting-disabled = true;

      http = {
        auth-enabled = true;
        flux-enabled = true;
      };
    };
  };
}
