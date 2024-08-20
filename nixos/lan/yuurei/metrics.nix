{ pkgs, ... }: {
  # 9090: prometheus
  networking.firewall.allowedTCPPorts = [9090];

  services.prometheus = {
    enable = true;
    # temporarily reduce retention so that early experimental data ages out.
    retentionTime = "365d";
    scrapeConfigs = [
      {
        job_name = "starlink";
        scrape_interval = "5s";
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
}
