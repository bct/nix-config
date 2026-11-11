# Guest side of the routed guest network. Set diffeq.guestNetworkClient to this
# guest's entry in its host's diffeq.guestNetwork.guests:
#
# - microvm guests: done automatically by nixos/modules/microvm-host.
# - libvirt guests: set it from the host's config, e.g.
#     diffeq.guestNetworkClient =
#       self.nixosConfigurations.mi-go.config.diffeq.guestNetwork.guests.ranger;
{
  lib,
  config,
  pkgs,
  ...
}:
let
  c = config.diffeq.guestNetworkClient;

  token = if c != null && c.ipv6.enable then c.ipv6.token else null;
  tokenFromMachineId = token == "machine-id";

  # app ID for `systemd-id128 machine-id --app-specific`. Not secret: it only
  # keeps the derived value distinct from other uses of the machine ID.
  tokenAppId = "67c0e877cc644cd0ae6c6257b77e62fa";

  networkDropInDir = "/run/systemd/network/20-guest.network.d";
in
{
  options.diffeq.guestNetworkClient = lib.mkOption {
    type = lib.types.nullOr lib.types.attrs;
    default = null;
    description = "This guest's entry in its host's diffeq.guestNetwork.guests.";
  };

  config = lib.mkIf (c != null) {
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
      }
      // lib.optionalAttrs (token != null) {
        # a fixed token is for a stable, firewall-matchable address; don't
        # prefer temporary addresses for outgoing connections over it.
        IPv6PrivacyExtensions = false;
      };

      # with "machine-id", the token comes from a drop-in written at boot
      # (below) instead.
      ipv6AcceptRAConfig = lib.mkIf (token != null && !tokenFromMachineId) {
        Token = "static:${token}";
      };

      linkConfig.RequiredForOnline = "routable";
    };

    # derive the IPv6 interface identifier from an app-specific hash of the
    # machine ID, and hand it to networkd as a drop-in for 20-guest.network.
    # To see it (e.g. for the router's firewall rule):
    #   cat /run/systemd/network/20-guest.network.d/ipv6-token.conf
    systemd.services.guest-ipv6-token = lib.mkIf tokenFromMachineId {
      description = "Derive this guest's IPv6 interface identifier from its machine ID";
      wantedBy = [
        "systemd-networkd.service"
        "multi-user.target"
      ];
      before = [ "systemd-networkd.service" ];
      unitConfig.DefaultDependencies = false;
      path = [ config.systemd.package ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # pick up the drop-in if networkd is already running (e.g. on switch).
        ExecStartPost = "-${config.systemd.package}/bin/networkctl reload";
      };
      script = ''
        id=$(systemd-id128 machine-id --app-specific=${tokenAppId})
        token="::''${id:0:4}:''${id:4:4}:''${id:8:4}:''${id:12:4}"
        mkdir -p ${networkDropInDir}
        printf '[IPv6AcceptRA]\nToken=static:%s\n' "$token" > ${networkDropInDir}/ipv6-token.conf
      '';
    };
  };
}
