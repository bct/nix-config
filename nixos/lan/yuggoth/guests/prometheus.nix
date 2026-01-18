{ pkgs, ... }:
{
  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-prometheus--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  # 9090: prometheus
  networking.firewall.allowedTCPPorts = [
    9090
  ];

  services.prometheus = {
    enable = true;
    # temporarily reduce retention so that early experimental data ages out.
    retentionTime = "365d";
    scrapeConfigs = [
      {
        job_name = "node-exporter";
        scrape_interval = "60s";
        static_configs = [
          # hosts
          { targets = [ "fever-dreams.domus.diffeq.com:9100" ]; }
          { targets = [ "mi-go.domus.diffeq.com:9100" ]; }
          { targets = [ "stereo.domus.diffeq.com:9100" ]; }
          { targets = [ "yuggoth.domus.diffeq.com:9100" ]; }

          # VMs
          { targets = [ "abrado.domus.diffeq.com:9100" ]; }
          { targets = [ "auth.domus.diffeq.com:9100" ]; }
          { targets = [ "books.domus.diffeq.com:9100" ]; }
          { targets = [ "bookmarks.domus.diffeq.com:9100" ]; }
          { targets = [ "borg.domus.diffeq.com:9100" ]; }
          { targets = [ "db.domus.diffeq.com:9100" ]; }
          { targets = [ "git.domus.diffeq.com:9100" ]; }
          { targets = [ "grafana.domus.diffeq.com:9100" ]; }
          { targets = [ "immich.domus.diffeq.com:9100" ]; }
          { targets = [ "jellyfin.domus.diffeq.com:9100" ]; }
          { targets = [ "lego-proxy.domus.diffeq.com:9100" ]; }
          { targets = [ "lubelogger.domus.diffeq.com:9100" ]; }
          { targets = [ "mail.domus.diffeq.com:9100" ]; }
          { targets = [ "medley.domus.diffeq.com:9100" ]; }
          { targets = [ "paperless.domus.diffeq.com:9100" ]; }
          { targets = [ "prometheus.domus.diffeq.com:9100" ]; }
          { targets = [ "ranger.domus.diffeq.com:9100" ]; }
          { targets = [ "spectator.domus.diffeq.com:9100" ]; }
          { targets = [ "syncthing.domus.diffeq.com:9100" ]; }
          { targets = [ "torrent-scraper.domus.diffeq.com:9100" ]; }
        ];
      }

      {
        job_name = "starlink";
        scrape_interval = "5s";
        static_configs = [
          { targets = [ "localhost:9817" ]; }
        ];
      }
    ];

    exporters = {
    };
  };

  systemd.services.starlink-exporter = {
    description = "starlink_exporter";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.starlink_exporter}/bin/starlink_exporter -port 9817";
      DynamicUser = true;
    };
  };
}
