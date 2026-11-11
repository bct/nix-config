# ranger is a routed guest of mi-go: its address, gateway and IPv6 token are
# defined there (mi-go/nixvirt.nix), and nixos/modules/guest-network/client.nix
# turns them into this machine's network config.
#
# ranger's IPv6 suffix is derived from its machine ID at boot (token =
# "machine-id"), so it isn't published here. The router's inbound rule for
# rtorrent's IPv6 port matches that suffix (::xxxx:xxxx:xxxx:xxxx/-64), so it
# keeps working when the ISP prefix changes. To see the suffix:
#   cat /run/systemd/network/20-guest.network.d/ipv6-token.conf
{ self, ... }:
{
  imports = [ "${self}/nixos/modules/guest-network/client.nix" ];

  diffeq.guestNetworkClient = self.nixosConfigurations.mi-go.config.diffeq.guestNetwork.guests.ranger;
}
