{ ... }: {
  networking.firewall.allowedTCPPorts = [
    9100 # prometheus node-exporter
  ];

  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [
      "cpu"
      "filesystem"
      "loadavg"
      "meminfo"
    ];
    extraFlags = [ "--collector.disable-defaults" ];
  };
}
