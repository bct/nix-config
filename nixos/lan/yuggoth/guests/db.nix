{ self, config, lib, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"

    ./db/borgmatic.nix
    ./db/postgres.nix
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 1024;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 2048;
      }
    ];
  };

  age.rekey.hostPubkey = lib.mkIf (builtins.pathExists ../../../../secrets/ssh/host-db.pub) ../../../../secrets/ssh/host-db.pub;

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
