# Network options shared by microvm guests (diffeq.microvms.guests.*) and
# libvirt guests (diffeq.nixvirt.guests.*). Imported into their submodules.
{ lib, ... }:
{
  options = with lib; {
    address = mkOption {
      type = types.str;
      description = "This guest's IPv4 address on the host's guest network (diffeq.guestNetwork).";
    };

    routed = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Put this guest on the host's routed guest network (its own point-to-point
        tap, with a static address) instead of bridging it onto the LAN via br0.
      '';
    };

    ipv6 = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Give this guest a /64 from the host's delegated IPv6 prefix. The prefix
          is dynamic, so the guest's address changes when the ISP's prefix does.
          Requires `routed`.
        '';
      };

      token = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "::d5b";
        description = ''
          Fixed interface identifier (the last 64 bits) of the guest's IPv6
          address, so firewall rules can match it by suffix. If null,
          systemd-networkd picks one.
        '';
      };
    };
  };
}
