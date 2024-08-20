{ self, pkgs, ... }:

let
  hostName = "prometheus";
  tapInterfaceName = "vm-${hostName}"; # <= 15 chars
  # Locally administered have one of 2/6/A/E in the second nibble.
  tapInterfaceMac = "02:00:00:00:00:03";
  machineId = "6621b60f7f7ac43dca44e143eb0578a8";
in {
  imports = [
    # note that we're not including "${self}/nixos/common/nix.nix" here
    # it complains:
    #     Your system configures nixpkgs with an externally created
    #     instance.
    #     `nixpkgs.config` options should be passed when creating the
    #     instance instead.
    # presumably the overlays are being passed through anyways.
    # the other nix configuration seems OK to ignore.
    "${self}/nixos/common/headless.nix"
  ];

  system.stateVersion = "24.05";
  networking.hostName = hostName;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };

  environment.etc."machine-id" = {
    mode = "0644";
    text = "${machineId}\n";
  };

  services.openssh.hostKeys = [
    {
      path = "/run/agenix-host/ssh-host";
      type = "ed25519";
    }
  ];

  microvm = {
    vcpu = 1;
    mem = 512;

    interfaces = [
      {
        type = "tap";
        id = tapInterfaceName;
        mac = tapInterfaceMac;
      }
    ];

    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }

      {
        tag = "agenix";
        source = "/run/agenix-vms/${hostName}";
        mountPoint = "/run/agenix-host";
        proto = "virtiofs";
      }

      {
        tag = "journal";
        source = "/var/lib/microvms/${hostName}/journal";
        mountPoint = "/var/log/journal";
        proto = "virtiofs";
        socket = "journal.sock";
      }
    ];

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
