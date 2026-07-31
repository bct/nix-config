{ ... }: {
  networking.useNetworkd = true;

  systemd.network.networks."10-enp6s0" = {
    matchConfig.Name = "enp6s0";
    networkConfig = {
      DHCP = "yes";
      # disable SLAAC. I want a stable IPv6 address so that my firewall has something to
      # key off, and I don't want to leak a mac address.
      IPv6PrivacyExtensions = false; # blocks temporary/privacy address
    };
    ipv6AcceptRAConfig = {
      UseAutonomousPrefix = false; # blocks SLAAC/EUI-64 address
      Token = ""; # not needed, just for clarity
    };
  };
}
