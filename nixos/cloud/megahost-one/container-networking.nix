{ lib, config, ... }:

let
  cfg = config.megahost.container-network;
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

    bridge0 = {
      prefix6 = lib.mkOption {
        type = lib.types.str;
      };

      hostAddress6 = lib.mkOption {
        type = lib.types.str;
        default = "${cfg.bridge0.prefix6}::1";
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
                  default = "${cfg.bridge0.prefix6}::${config.suffix6}";
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
    networking.bridges.br0 = {
      interfaces = [ ];
    };
    networking.interfaces.br0 = {
      ipv6.addresses = [
        {
          address = cfg.bridge0.hostAddress6;
          prefixLength = cfg.bridge0.netmask6;
        }
      ];
    };

    containers =
      let
        bridge0 = (
          lib.mapAttrs (containerName: networkConfig: {
            hostBridge = "br0";

            # including the netmask here gives the container access to the entire bridge network.
            localAddress6 = "${networkConfig.address6}/${toString cfg.bridge0.netmask6}";
          }) cfg.bridge0.containers
        );

        direct = (
          lib.mapAttrs (containerName: instanceConfig: {
            hostAddress6 = instanceConfig.hostAddress6;
            localAddress6 = instanceConfig.address6;
          }) cfg.direct.containers
        );
      in
      bridge0 // direct;
  };
}
