# Addressing for a host's guests (microvms and libvirt VMs), shared by
# nixos/modules/microvm-host and nixos/modules/nixvirt.
#
# Each host gets a /24. Guests get static addresses in it. The host sits on
# `gateway` and routes for them.
{ lib, config, ... }:
let
  cfg = config.diffeq.guestNetwork;

  guestsOf =
    kind: guests:
    lib.mapAttrsToList (name: guest: {
      inherit name kind;
      inherit (guest) address;
    }) guests;

  guests =
    guestsOf "microvm" (config.diffeq.microvms.guests or { })
    ++ guestsOf "nixvirt" (config.diffeq.nixvirt.guests or { });

  describe = g: "${g.kind} guest ${g.name} (${g.address})";

  hostPart =
    address:
    let
      m = builtins.match "${lib.escapeRegex cfg.subnetPrefix}\\.([0-9]{1,3})" address;
    in
    if m == null then null else lib.toInt (lib.head m);

  outsideSubnet = lib.filter (
    g:
    let
      n = hostPart g.address;
    in
    n == null || n < 1 || n > 254
  ) guests;

  onGateway = lib.filter (g: g.address == cfg.gateway) guests;

  duplicates = lib.filterAttrs (_: gs: lib.length gs > 1) (lib.groupBy (g: g.address) guests);
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
      description = "The host's address on the guest network, used by guests as their gateway.";
    };
  };

  config = lib.mkIf (guests != [ ]) {
    assertions = [
      {
        assertion = outsideSubnet == [ ];
        message = "guest addresses must be in ${cfg.subnetPrefix}.1-254: ${lib.concatMapStringsSep ", " describe outsideSubnet}";
      }
      {
        assertion = onGateway == [ ];
        message = "guest addresses must not be the gateway (${cfg.gateway}): ${lib.concatMapStringsSep ", " describe onGateway}";
      }
      {
        assertion = duplicates == { };
        message = "guest addresses must be unique: ${
          lib.concatStringsSep "; " (
            lib.mapAttrsToList (_: gs: lib.concatMapStringsSep ", " describe gs) duplicates
          )
        }";
      }
    ];
  };
}
