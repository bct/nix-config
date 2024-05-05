{ self, config, inputs, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix

    "${self}/nixos/modules/acme-zoneedit"

    ./miniflux.nix
  ];

  networking.hostName = "yuurei";
  networking.useNetworkd = true;

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

  # 9090: prometheus
  # 2003: graphite-exporter
  networking.firewall.allowedTCPPorts = [2003 9090];

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
      {
        job_name = "graphite";
        scrape_interval = "15s";
        static_configs = [
          { targets = ["localhost:9108"]; }
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

  system.stateVersion = "23.05";
}
