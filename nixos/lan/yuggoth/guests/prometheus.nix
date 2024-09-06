{ pkgs, ... }: {
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

  # 9090: prometheus
  # 2003: graphite-exporter
  networking.firewall.allowedTCPPorts = [2003 9090];

  services.prometheus = {
    enable = true;
    # temporarily reduce retention so that early experimental data ages out.
    retentionTime = "365d";
    scrapeConfigs = [
      {
        job_name = "graphite";
        scrape_interval = "15s";
        static_configs = [
          { targets = ["localhost:9108"]; }
        ];
      }

      {
        job_name = "node-exporter";
        scrape_interval = "60s";
        static_configs = [
          # hosts
          { targets = ["stereo.domus.diffeq.com:9100"]; }
          { targets = ["yuggoth.domus.diffeq.com:9100"]; }

          # VMs
          { targets = ["grafana.domus.diffeq.com:9100"]; }
          { targets = ["lego-proxy.domus.diffeq.com:9100"]; }
          { targets = ["miniflux.domus.diffeq.com:9100"]; }
          { targets = ["prometheus.domus.diffeq.com:9100"]; }
          { targets = ["spectator.domus.diffeq.com:9100"]; }
          { targets = ["torrent-scraper.domus.diffeq.com:9100"]; }
        ];
      }
    ];
  };

  # services.prometheus.exporters.graphite.enable ?
  systemd.services.graphite-exporter = let
    # taken from:
    # https://github.com/mazay/truenas-grafana/blob/cbd5d3a7e8f7b949e8dab3e253cb07785983c202/truenas-graphite-exporter.yaml
    configFile = pkgs.writeText "graphite-exporter-config.yaml" (pkgs.lib.generators.toYAML {} {
      mappings = [
        # ifstats mapping
        { match = ''servers.(.*)\.interface-(.*)\.if_(.*)'';
          match_type = "regex";
          name = "truenas_interface_\${3}";
          labels = {
            hostname = "\${1}";
            device = "\${2}";
          };
        }
        # dataset metrics mapping
        { match = ''servers\.(.*)\.df-(.*)\.(.*)'';
          match_type = "regex";
          name = "truenas_dataset_\${3}";
          labels = {
            hostname = "\${1}";
            device = "\${2}";
          };
        }
        # memory metrics mapping
        { match = ''servers\.(.*)\.memory\.(.*)'';
          match_type = "regex";
          name = "truenas_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # zfs arc metrics mapping
        { match = ''servers\.(.*)\.zfs_arc\.(.*)'';
          match_type = "regex";
          name = "truenas_zfs_arc_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # processes metrics
        { match = ''servers\.(.*)\.processes\.(.*)'';
          match_type = "regex";
          name = "truenas_processes_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # LA metrics
        { match = ''servers\.(.*)\.load\.load\.(.*)'';
          match_type = "regex";
          name = "truenas_load_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # rrd cache metrics
        { match = ''servers\.(.*)\.rrdcached\.(.*)'';
          match_type = "regex";
          name = "truenas_rrdcached_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # swap metrics
        { match = ''servers\.(.*)\.swap\.(.*)'';
          match_type = "regex";
          name = "truenas_swap_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # uptime metric
        { match = ''servers\.(.*)\.uptime\.(.*)'';
          match_type = "regex";
          name = "truenas_uptime_\${2}";
          labels = {
            hostname = "\${1}";
          };
        }
        # disk metrics mapping
        { match = ''servers\.(.*)\.disk-(.*)\.(.*)\.(.*)'';
          match_type = "regex";
          name = "truenas_\${3}_\${4}";
          labels = {
            hostname = "\${1}";
            device = "\${2}";
          };
        }
        # more disk metrics?
        { match = ''servers\.(.*)\.geom_stat.(.*)-(.*)\.(.*)'';
          match_type = "regex";
          name = "truenas_geom_stat_\${2}";
          labels = {
            hostname = "\${1}";
            device = "\${3}";
            op = "\${4}";
          };
        }
        { match = ''servers\.(.*)\.geom_stat.(.*)-(.*)'';
          match_type = "regex";
          name = "truenas_geom_stat_\${2}";
          labels = {
            hostname = "\${1}";
            device = "\${3}";
          };
        }
        # cpu and nfs metrics mapping
        { match = ''servers\.(.*)\.(.*)-(.*)\.(.*)'';
          match_type = "regex";
          name = "truenas_\${2}_\${4}";
          labels = {
            hostname = "\${1}";
            device = "\${3}";
          };
        }
      ];
    });
  in {
    description = "graphite_exporter";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.prometheus-graphite-exporter}/bin/graphite_exporter --graphite.listen-address=:2003 --graphite.mapping-config=${configFile}";
      DynamicUser = true;
    };
  };
}
