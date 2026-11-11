# Addressing and routing for a host's guests (microvms and libvirt VMs), shared
# by nixos/modules/microvm-host and nixos/modules/nixvirt.
#
# Each host gets a /24. Guests get static addresses in it. A guest is either:
#
# - bridged (the default, being phased out): its tap is in br0 and it gets its
#   address from the router's DHCP like any LAN device.
# - routed: its tap is a point-to-point link to the host. The host sits on
#   `gateway` (the same /32 on every tap) and routes for it; the guest's
#   side is configured by ./client.nix. With ipv6.enable the host also hands
#   it a /64 from the prefix the router delegates to the host.
#
# Guest host numbers are limited to 1-31 so they can double as the IPv6 subnet
# ID within the host's delegated /59.
{ lib, config, ... }:
let
  cfg = config.diffeq.guestNetwork;
  glib = import ./lib.nix { inherit lib; };

  microvmGuests = lib.mapAttrsToList (name: g: {
    inherit name;
    kind = "microvm";
    enabled = g.enable;
    hostName = g.hostName;
    tap = g.tapInterfaceName;
    pinnedMac = g.tapInterfaceMac;
    inherit (g) address routed ipv6;
  }) (config.diffeq.microvms.guests or { });

  nixvirtGuests = lib.mapAttrsToList (name: g: {
    inherit name;
    kind = "nixvirt";
    enabled = true;
    hostName = name;
    tap = g.tapInterfaceName;
    pinnedMac = g.mac;
    inherit (g) address routed ipv6;
  }) (config.diffeq.nixvirt.guests or { });

  allGuests = microvmGuests ++ nixvirtGuests;

  # what the rest of the config (and each guest) sees.
  normalize = g: {
    inherit (g)
      kind
      enabled
      hostName
      tap
      address
      routed
      ;
    mac = if g.routed then glib.macForAddress g.address else g.pinnedMac;
    inherit (cfg) gateway nameservers;
    ipv6 = g.ipv6 // {
      subnetId = glib.hostNumber cfg.subnetPrefix g.address;
    };
  };

  guests = builtins.listToAttrs (map (g: lib.nameValuePair g.name (normalize g)) allGuests);

  routedGuests = lib.filter (g: g.routed && g.enabled) (lib.attrValues guests);
  anyIPv6 = lib.any (g: g.ipv6.enable) routedGuests;

  describe = g: "${g.kind} guest ${g.name} (${g.address})";
  badHostNumber = lib.filter (
    g:
    let
      n = glib.hostNumber cfg.subnetPrefix g.address;
    in
    n == null || n < 1 || n > 31
  ) allGuests;
  duplicateAddresses = lib.filterAttrs (_: gs: lib.length gs > 1) (
    lib.groupBy (g: g.address) allGuests
  );
  duplicateNames = lib.filterAttrs (_: gs: lib.length gs > 1) (lib.groupBy (g: g.name) allGuests);
  bridgedWithoutMac = lib.filter (g: !g.routed && g.pinnedMac == null) allGuests;
  ipv6WithoutRouting = lib.filter (g: g.ipv6.enable && !g.routed) allGuests;
  listGuests = gs: lib.concatMapStringsSep ", " describe gs;
in
{
  options.diffeq.guestNetwork = with lib; {
    subnetPrefix = mkOption {
      type = types.strMatching "[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}";
      example = "192.168.200";
      description = "First three octets of the /24 that this host's guests are addressed from.";
    };

    gateway = mkOption {
      type = types.str;
      default = "${cfg.subnetPrefix}.254";
      defaultText = literalExpression ''"''${subnetPrefix}.254"'';
      description = "The host's address on every routed guest's tap; guests use it as their gateway.";
    };

    nameservers = mkOption {
      type = types.listOf types.str;
      default = [ "192.168.4.1" ];
      description = "DNS servers for routed guests.";
    };

    uplinkNetwork = mkOption {
      type = types.str;
      default = "10-lan-bridge";
      description = ''
        The systemd-networkd network (in systemd.network.networks) that holds
        the host's LAN address. If any routed guest has IPv6, it requests a
        prefix delegation from the router.
      '';
    };

    delegatedPrefixLength = mkOption {
      type = types.ints.between 48 64;
      default = 59;
      description = "Size of the IPv6 prefix to request from the router for this host's guests.";
    };

    guests = mkOption {
      type = types.attrsOf types.attrs;
      readOnly = true;
      description = ''
        Every guest on this host (microvm and libvirt), with its effective
        network settings. Each routed guest's own config reads its entry; see
        ./client.nix.
      '';
    };
  };

  config = lib.mkMerge [
    { diffeq.guestNetwork.guests = guests; }

    (lib.mkIf (allGuests != [ ]) {
      assertions = [
        {
          assertion = badHostNumber == [ ];
          message = "guest addresses must be in ${cfg.subnetPrefix}.1-31 (the host number doubles as the guest's IPv6 subnet ID): ${listGuests badHostNumber}";
        }
        {
          assertion = duplicateAddresses == { };
          message = "guest addresses must be unique: ${
            lib.concatStringsSep "; " (lib.mapAttrsToList (_: listGuests) duplicateAddresses)
          }";
        }
        {
          assertion = duplicateNames == { };
          message = "microvm and libvirt guests must have distinct names: ${
            lib.concatStringsSep "; " (lib.mapAttrsToList (_: listGuests) duplicateNames)
          }";
        }
        {
          assertion = bridgedWithoutMac == [ ];
          message = "bridged guests need a MAC set by hand (only routed guests get one generated): ${listGuests bridgedWithoutMac}";
        }
        {
          assertion = ipv6WithoutRouting == [ ];
          message = "ipv6.enable requires routed = true: ${listGuests ipv6WithoutRouting}";
        }
      ];
    })

    (lib.mkIf (routedGuests != [ ]) {
      systemd.network.enable = true;

      # forward between the guests' taps and the LAN.
      systemd.network.config.networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = anyIPv6;
      };

      # one point-to-point link per routed guest. Sorts before microvm-host's
      # "10-lan", which would otherwise put the tap in br0.
      systemd.network.networks = lib.listToAttrs (
        map (
          g:
          lib.nameValuePair "05-guest-${g.hostName}" {
            matchConfig.Name = g.tap;
            address = [ "${g.gateway}/32" ];
            routes = [ { Destination = "${g.address}/32"; } ];

            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = false;
              LinkLocalAddressing = if g.ipv6.enable then "ipv6" else "no";
            }
            // lib.optionalAttrs g.ipv6.enable {
              # take a /64 from the host's delegated prefix and advertise it
              # to the guest, which builds its address with SLAAC.
              DHCPPrefixDelegation = true;
              IPv6SendRA = true;
            };

            dhcpPrefixDelegationConfig = lib.mkIf g.ipv6.enable {
              # networkd parses this as hex (no 0x prefix).
              SubnetId = lib.toLower (lib.toHexString g.ipv6.subnetId);
              Announce = true;
            };

            # the tap only exists while the guest is running.
            linkConfig.RequiredForOnline = "no";
          }
        ) routedGuests
      );
    })

    (lib.mkIf anyIPv6 {
      systemd.network.networks.${cfg.uplinkNetwork} = {
        # with IPv6 forwarding on, networkd ignores RAs unless told otherwise,
        # and without RAs it never starts the DHCPv6 client that requests the
        # delegated prefix (and the host's own address).
        networkConfig.IPv6AcceptRA = true;

        dhcpV6Config.PrefixDelegationHint = "::/${toString cfg.delegatedPrefixLength}";
      };
    })
  ];
}
