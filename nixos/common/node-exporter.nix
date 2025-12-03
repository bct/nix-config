{ ... }:
{
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
    extraFlags = [
      "--collector.disable-defaults"

      # only include "real" filesystems
      "--collector.filesystem.fs-types-exclude=^(9p|bpf|configfs|cgroup2|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|overlay|proc|pstore|ramfs|securityfs|sysfs|tmpfs|virtiofs)$"
    ];
  };
}
