{ self, config, inputs, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix

    "${self}/nixos/modules/acme-zoneedit"
  ];

  networking.hostName = "yuurei";

  time.timeZone = "Etc/UTC";

  services.acme-zoneedit = {
    enable = true;
    hostnames = ["mi-go.domus.diffeq.com" "router.domus.diffeq.com" "yuurei.domus.diffeq.com"];
    email = "s+acme@diffeq.com";
    credentialsFile = config.age.secrets.zoneedit.path;
  };

  age.secrets = {
    zoneedit = {
      file = ../../../secrets/zoneedit.age;
      owner = "acme";
      group = "acme";
      mode = "600";
    };
  };

  services.iperf3 = {
    enable = true;
    openFirewall = true;
  };

  # prometheus
  networking.firewall.allowedTCPPorts = [9090];

  services.prometheus = {
    enable = true;
    retentionTime = "365d";
    scrapeConfigs = [
      {
        job_name = "starlink";
        static_configs = [
          { targets = ["localhost:9817"]; }
        ];
      }
      {
        job_name = "speedtest";
        scrape_interval = "60m";
        scrape_timeout = "60s";
        static_configs = [
          { targets = ["localhost:9818"]; }
        ];
      }
    ];
  };

  systemd.services.starlink-exporter = {
    description = "starlink_exporter";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.starlink_exporter}/bin/starlink_exporter -port 9817";
      DynamicUser = true;
    };
  };

  systemd.services.speedtest-exporter = {
    description = "speedtest_exporter";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.speedtest_exporter}/bin/speedtest_exporter -port 9818";
      DynamicUser = true;
    };
  };

  system.stateVersion = "23.05";
}
