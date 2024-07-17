{ pkgs, ... }: {
  networking.firewall.allowedUDPPorts = [ 53 ];

  # set up coredns to respond to DNS requests for _wireguard._udp.diffeq.com
  # using the plugin: https://github.com/jwhited/wgsd
  #
  # the plugin provides IP addresses for known wireguard peers.
  services.coredns = {
    enable = true;

    config = ''
      .:53 {
        bind ens3
        debug
        wgsd diffeq.com. wg0
      }
    '';

    package = pkgs.coredns.override {
      externalPlugins = [
        {name = "wgsd"; repo = "github.com/jwhited/wgsd"; version = "v0.3.6";}
      ];
      vendorHash = "sha256-FNnVwxPYoaYpfkm3ZPWVhjFIaEhTxMyskv0+UJO2dd0=";
    };
  };

  # wgsd needs cap_net_admin to read the wireguard peers
  systemd.services.coredns.serviceConfig.CapabilityBoundingSet = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
  systemd.services.coredns.serviceConfig.AmbientCapabilities = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
}
