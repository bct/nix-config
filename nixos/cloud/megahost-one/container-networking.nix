{ lib, config, ... }:

let
  hostIp6 = "fc00::1:1";
  containerIp6 = {
    postgres    = "fc00::1:2/7";
    goatcounter = "fc00::1:3/7";
    wiki        = "fc00::1:4/7";
  };

  cfgMinio = config.megahost.minio;
in {
  # https://github.com/NixOS/nixpkgs/blob/master/nixos/tests/containers-bridge.nix
  networking.bridges = {
    br0 = {
      interfaces = [];
    };
  };
  networking.interfaces = {
    br0 = {
      ipv6.addresses = [{ address = hostIp6; prefixLength = 7; }];
    };
  };

  containers = {
    postgres = {
      hostBridge = "br0";
      localAddress6 = containerIp6.postgres;
    };

    goatcounter = {
      hostBridge = "br0";
      localAddress6 = containerIp6.goatcounter;
    };

    wiki = {
      hostBridge = "br0";
      localAddress6 = containerIp6.wiki;
    };
  } // (lib.mapAttrs (containerName: instanceConfig: {
    hostAddress6 = instanceConfig.hostAddress6;
    localAddress6 = instanceConfig.containerAddress6;
  }) cfgMinio.instances);
}
