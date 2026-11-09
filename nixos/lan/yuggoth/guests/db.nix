{
  self,
  config,
  pkgs,
  ...
}:
let
  cert = config.security.acme.certs.${config.diffeq.hostNames.db};
in
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
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

  services.lego-proxy-client = {
    enable = true;
    domains = [ "db" ];
  };

  # postgres refuses a key file not owned by itself or root, and the ACME files are owned
  # by acme, so hand them over as systemd credentials (copied, owned by postgres, 0400).
  systemd.services.postgresql.serviceConfig.LoadCredential = [
    "ssl-cert:${cert.directory}/fullchain.pem"
    "ssl-key:${cert.directory}/key.pem"
  ];
  systemd.services.postgresql = {
    wants = [ "acme-finished-${config.diffeq.hostNames.db}.target" ];
    after = [ "acme-finished-${config.diffeq.hostNames.db}.target" ];
  };

  services.postgresql.settings = {
    ssl = true;
    ssl_cert_file = "/run/credentials/postgresql.service/ssl-cert";
    ssl_key_file = "/run/credentials/postgresql.service/ssl-key";
  };

  # credentials are only re-copied on restart, so a reload wouldn't pick up a renewed cert.
  security.acme.certs.${config.diffeq.hostNames.db}.postRun =
    "systemctl try-restart postgresql.service";

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  # TODO: services.influxdb2?
  services.influxdb = {
    enable = true;

    settings = {
      reporting-disabled = true;

      http = {
        auth-enabled = true;
        flux-enabled = true;
      };
    };
  };
}
