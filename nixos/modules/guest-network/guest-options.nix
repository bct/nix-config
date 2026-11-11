# Network options shared by microvm guests (diffeq.microvms.guests.*) and
# libvirt guests (diffeq.nixvirt.guests.*). Imported into their submodules.
{ lib, ... }:
{
  options = with lib; {
    address = mkOption {
      type = types.str;
      description = "This guest's IPv4 address on the host's guest network (diffeq.guestNetwork).";
    };

    ipv6 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Give this guest a /64 from the host's delegated IPv6 prefix. The prefix
          is dynamic, so the guest's address changes when the ISP's prefix does.
        '';
      };

      token = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "machine-id";
        description = ''
          Fixed interface identifier (the last 64 bits) of the guest's IPv6
          address, so firewall rules can match it by suffix.

          - "machine-id": derived at boot from the guest's machine ID (an
            app-specific hash, see nixos/modules/guest-network/client.nix).
            Stable, and private as long as the machine ID isn't in this repo,
            which is true for libvirt guests but NOT for microvms.
          - "::a:b:c:d": used as-is. Anything here is public if this repo is,
            and peers who see the address can find it.
          - null: systemd-networkd's default (derived from the MAC, which is
            derived from the guest's IPv4 address).
        '';
      };
    };
  };
}
