{
  self,
  pkgs,
  lib,
  config,
  ...
}:
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
          { targets = [ "lego-proxy.domus.diffeq.com:9100" ]; }
          { targets = [ "lubelogger.domus.diffeq.com:9100" ]; }
          { targets = [ "mail.domus.diffeq.com:9100" ]; }
          { targets = [ "media.domus.diffeq.com:9100" ]; }
          { targets = [ "medley.domus.diffeq.com:9100" ]; }
          { targets = [ "minecraft.domus.diffeq.com:9100" ]; }
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

      {
        job_name = "mktxp";
        scrape_interval = "60s";
        static_configs = [
          { targets = [ "localhost:49090" ]; }
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

  systemd.services.mktxp =
    let
      globalConfFile = pkgs.writeText "_mktxp.conf" ''
        [MKTXP]
            listen = '127.0.0.1:49090'         # Space separated list of socket addresses to listen to, both IPV4 and IPV6
            socket_timeout = 5

            initial_delay_on_failure = 120
            max_delay_on_failure = 900
            delay_inc_div = 5

            bandwidth = False                   # Turns metrics bandwidth metrics collection on / off
            bandwidth_test_dns_server = 8.8.8.8 # The DNS server to be used for the bandwidth test connectivity check
            bandwidth_test_interval = 600       # Interval for collecting bandwidth metrics
            minimal_collect_interval = 60       # Minimal metric collection interval

            verbose_mode = True             # Set it on for troubleshooting

            fetch_routers_in_parallel = True  # Fetch metrics from multiple routers in parallel / sequentially
            max_worker_threads = 2            # Max number of worker threads that can fetch routers (parallel fetch only)
            max_scrape_duration = 30          # Max duration of individual routers' metrics collection (parallel fetch only)
            total_max_scrape_duration = 90    # Max overall duration of all metrics collection (parallel fetch only)
            http_server_threads = 2          # Number of worker threads for the HTTP server

            persistent_router_connection_pool = True  # Use a persistent router connections pool between scrapes
            persistent_dhcp_cache = True              # Persist DHCP cache between metric collections
            compact_default_conf_values = False       # Compact mktxp.conf, so only specific values are kept on the individual routers' level
            prometheus_headers_deduplication = False  # Deduplicate Prometheus HELP / TYPE headers in the metrics output
      '';

      routersConfFile = pkgs.writeText "mktxp.conf" ''
        [ww-garage]
            hostname = 192.168.88.2

        [ww-barn]
            hostname = 192.168.88.3

        [default]
            # this affects configuration of all routers, unless overloaded on their specific levels

            enabled = True          # turns metrics collection for this RouterOS device on / off
            module_only = False     # use this entry only as a probe module (skip /metrics collection)
            port = 8728             # RouterOS IP Port

            credentials_file = /run/mktxp/credentials   # YAML file with username and password keys

            custom_labels = None    # Custom labels to be injected to all device metrics, comma-separated key:value (or key=value) pairs
                                    # Example: 'dc:london, rack=a1, service:prod' (quotation marks are optional)

            use_ssl = False                 # enables connection via API-SSL servis
            no_ssl_certificate = False      # enables API_SSL connect without router SSL certificate
            ssl_certificate_verify = False  # turns SSL certificate verification on / off
            ssl_check_hostname = True       # check if the hostname matches the peer cert's hostname
            ssl_ca_file = ""                # path to the certificate authority file to validate against, leave empty to use system store
            plaintext_login = True          # for legacy RouterOS versions below 6.43 use False

            routerboard = True              # RouterBOARD inventory / firmware metrics
            health = True                   # System Health metrics
            installed_packages = True       # Installed packages
            dhcp = False                    # DHCP general metrics
            dhcp_lease = False              # DHCP lease metrics

            connections = False             # IP connections metrics
            connection_stats = False        # Open IP connections metrics
            connection_stats_destinations = False   # Set to True to track individual destination IPs/ports (Warning: High Cardinality)

            interface = True                    # Interfaces traffic metrics
            interface_with_default_name = False # Append default_name label to interface metrics
            wireguard_peers = False             # Wireguard peers metrics
            bridge_vlan = False                 # Bridge VLAN metrics

            route = False                   # IPv4 Routes metrics
            pool = False                    # IPv4 Pool metrics
            firewall = False                # IPv4 Firewall rules traffic metrics
            neighbor = False                # IPv4 Reachable Neighbors
            address_list = None             # Firewall Address List metrics, a comma-separated list of names
            dns = False                     # DNS stats

            ipv6_route = False              # IPv6 Routes metrics
            ipv6_pool = False               # IPv6 Pool metrics
            ipv6_firewall = False           # IPv6 Firewall rules traffic metrics
            ipv6_neighbor = False           # IPv6 Reachable Neighbors
            ipv6_address_list = None        # IPv6 Firewall Address List metrics, a comma-separated list of names

            poe = False                     # POE metrics
            monitor = True                  # Interface monitor metrics
            netwatch = False                # Netwatch metrics
            public_ip = False               # Public IP metrics
            wireless = False                # WLAN general metrics
            wireless_clients = False        # WLAN clients metrics
            capsman = False                 # CAPsMAN general metrics
            capsman_clients = False         # CAPsMAN clients metrics
            w60g = True                     # W60G metrics

            eoip = False                    # EoIP status metrics
            gre = False                     # GRE status metrics
            ipip = False                    # IPIP status metrics
            lte = False                     # LTE signal and status metrics (requires additional 'test' permission policy on RouterOS v6)
            ipsec = False                   # IPSec active peer metrics
            switch_port = False             # Switch Port metrics

            kid_control_assigned = False    # Allow Kid Control metrics for connected devices with assigned users
            kid_control_dynamic = False     # Allow Kid Control metrics for all connected devices, including those without assigned user

            user = False                    # Active Users metrics
            queue = False                   # Queues metrics

            bfd = False                     # BFD sessions metrics
            bgp = False                     # BGP sessions metrics
            routing_stats = False           # Routing process stats
            certificate = False             # Certificates metrics

            container = False               # Containers metrics

            remote_dhcp_entry = None        # An MKTXP entry to provide for remote DHCP info / resolution
            remote_capsman_entry = None     # An MKTXP entry to provide for remote capsman info

            interface_name_format = name    # Format to use for interface / resource names, allowed values: 'name', 'comment', or 'combined'
                                                # 'name': use interface name only (e.g. 'ether1')
                                                # 'comment': use comment if available, fallback to name if not
                                                # 'combined': use both (e.g. 'ether1 (Office Switch)')
            check_for_updates = False       # check for available ROS updates
      '';
    in
    {
      description = "mktxp - Mikrotik RouterOS Prometheus exporter";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.coreutils ];
      preStart = ''
        install -m 0644 ${globalConfFile} /run/mktxp/_mktxp.conf
        install -m 0644 ${routersConfFile} /run/mktxp/mktxp.conf
        install -m 0600 $CREDENTIALS_DIRECTORY/mktxp-credentials /run/mktxp/credentials
      '';

      environment.PYTHONUNBUFFERED = "1";

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectory = "mktxp";
        LoadCredential = "mktxp-credentials:${config.age.secrets.mktxp-credentials.path}";
        ExecStart = "${lib.getExe pkgs.mktxp} --cfg-dir /run/mktxp export";
        Restart = "on-failure";
        RestartSec = 10;

        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
      };
    };

  age.secrets.mktxp-credentials = {
    rekeyFile = ./secrets/mktxp-credentials.age;
  };
}
