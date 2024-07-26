{ lib, config, ... }:

let
  cfg = config.megahost.container-network;
  cfgMinio = config.megahost.minio;
in {
  options.megahost.container-network.bridge0 = {
    netmask6 = lib.mkOption {
      type = lib.types.int;
      default = 64;
    };

    hostAddress6 = lib.mkOption {
      type = lib.types.str;
    };

    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (
        {config, options, name, ...}: {
          options = {
            address6 = lib.mkOption {
              type = lib.types.str;
            };
          };
        }
      ));
    };
  };

  config = {
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/containers-bridge.nix
    networking.bridges.br0 = {
      interfaces = [];
    };
    networking.interfaces.br0 = {
      ipv6.addresses = [
        {
          address = cfg.bridge0.hostAddress6;
          prefixLength = cfg.bridge0.netmask6;
        }
      ];
    };

    containers = let
      bridge0 = (lib.mapAttrs (containerName: networkConfig: {
        hostBridge = "br0";

        # including the netmask here gives the container access to the entire bridge network.
        localAddress6 = "${networkConfig.address6}/${toString cfg.bridge0.netmask6}";
      }) cfg.bridge0.containers);

      minio = (lib.mapAttrs (containerName: instanceConfig: {
        hostAddress6 = instanceConfig.hostAddress6;
        localAddress6 = instanceConfig.containerAddress6;
      }) cfgMinio.instances);
    in bridge0 // minio;
  };
}
