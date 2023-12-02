{ pkgs, ... }: {
  networking.firewall.allowedUDPPorts = [ 53 ];

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
        {name = "wgsd"; repo = "github.com/jwhited/wgsd"; version = "v0.3.5";}
      ];
      vendorHash = "sha256-yL0OHx4nP5lCq+Wo1PzqCE5l9+5Q0wwU+xFT7v8wqkU=";
    };
  };

  # wgsd needs cap_net_admin to read the wireguard peers
  systemd.services.coredns.serviceConfig.CapabilityBoundingSet = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
  systemd.services.coredns.serviceConfig.AmbientCapabilities = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
}
