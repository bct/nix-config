{ pkgs, ... }:
{
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
        {
          name = "wgsd";
          repo = "github.com/jwhited/wgsd";
          version = "v0.3.6";
        }
      ];
      # the vendorHash needs to be updated every time pkgs.coredns updates,
      # due to the way the core & plugin packages are combined when vendored.
      # I spent a couple of days trying to fix this, and eventually gave up.
      vendorHash = "sha256-pauVp0pa/dSY2ACoaTRzlW6lI9DuwG3miO7uz9Cbr4k=";
    };
  };

  # wgsd needs cap_net_admin to read the wireguard peers
  systemd.services.coredns.serviceConfig.CapabilityBoundingSet =
    pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
  systemd.services.coredns.serviceConfig.AmbientCapabilities =
    pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
}
