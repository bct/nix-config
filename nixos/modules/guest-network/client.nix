# Guest side of the routed guest network. Set diffeq.guestNetworkClient to this
# guest's entry in its host's diffeq.guestNetwork.guests:
#
# - microvm guests: done automatically by nixos/modules/microvm-host.
# - libvirt guests: set it from the host's config, e.g.
#     diffeq.guestNetworkClient =
#       self.nixosConfigurations.mi-go.config.diffeq.guestNetwork.guests.ranger;
#
# Does nothing unless the entry has `routed = true`; bridged guests keep
# whatever network config they already have (DHCP from the router).
{ lib, config, ... }:
let
  c = config.diffeq.guestNetworkClient;
in
{
  options.diffeq.guestNetworkClient = lib.mkOption {
    type = lib.types.nullOr lib.types.attrs;
    default = null;
    description = "This guest's entry in its host's diffeq.guestNetwork.guests.";
  };

  config = lib.mkIf (c != null && c.routed) {
    networking.useNetworkd = true;
    networking.useDHCP = false;
    systemd.network.enable = true;

    systemd.network.networks."20-guest" = {
      # match by MAC rather than name: the host sets it, and the NIC's name can
      # change with the hypervisor's PCI layout.
      matchConfig.MACAddress = c.mac;

      # a point-to-point link: our /32, and the host's address on the far end.
      address = [ "${c.address}/32" ];
      routes = [
        { Destination = "${c.gateway}/32"; }
        {
          Gateway = c.gateway;
          GatewayOnLink = true;
        }
      ];
      dns = c.nameservers;

      networkConfig = {
        DHCP = "no";
        LinkLocalAddressing = if c.ipv6.enable then "ipv6" else "no";
        IPv6AcceptRA = c.ipv6.enable;
      };

      ipv6AcceptRAConfig = lib.mkIf (c.ipv6.enable && c.ipv6.token != null) {
        Token = "static:${c.ipv6.token}";
      };

      linkConfig.RequiredForOnline = "routable";
    };
  };
}
