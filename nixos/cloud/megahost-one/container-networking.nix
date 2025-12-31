{ lib, config, ... }:

let
  cfg = config.megahost.container-network;
  internalBridgeName = "br-int";
in
{
  options.megahost.container-network = {
    direct = {
      containers = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {
              config,
              options,
              name,
              ...
            }:
            {
              options = {
                prefix6 = lib.mkOption {
                  type = lib.types.str;
                };

                hostAddress6 = lib.mkOption {
                  type = lib.types.str;
                  default = "${config.prefix6}::1";
                };

                address6 = lib.mkOption {
                  type = lib.types.str;
                  default = "${config.prefix6}::2";
                };
              };
            }
          )
        );
      };
    };

    bridge-internal = {
      prefix6 = lib.mkOption {
        type = lib.types.str;
      };

      hostAddress6 = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.bridge-internal.prefix6}::1";
      };

      netmask6 = lib.mkOption {
        type = lib.types.int;
        default = 64;
      };

      containers = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            {
              config,
              options,
              name,
              ...
            }:
            {
              options = {
                suffix6 = lib.mkOption {
                  type = lib.types.str;
                };

                address6 = lib.mkOption {
                  type = lib.types.str;
                  default = "${cfg.bridge-internal.prefix6}::${config.suffix6}";
                };
              };
            }
          )
        );
      };
    };
  };

  config = {
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/containers-bridge.nix
    networking.bridges.${internalBridgeName} = {
      interfaces = [ ];
    };
    networking.interfaces.${internalBridgeName} = {
      ipv6.addresses = [
        {
          address = cfg.bridge-internal.hostAddress6;
          prefixLength = cfg.bridge-internal.netmask6;
        }
      ];
    };

    containers =
      let
        bridge-internal = (
          lib.mapAttrs (containerName: networkConfig: {
            hostBridge = internalBridgeName;

            # including the netmask here gives the container access to the entire bridge network.
            localAddress6 = "${networkConfig.address6}/${toString cfg.bridge-internal.netmask6}";
          }) cfg.bridge-internal.containers
        );

        direct = (
          lib.mapAttrs (containerName: instanceConfig: {
            hostAddress6 = instanceConfig.hostAddress6;
            localAddress6 = instanceConfig.address6;
          }) cfg.direct.containers
        );
      in
      bridge-internal // direct;
  };
}
