{ inputs, config, lib, pkgs, ... }:
let
  hostIp6 = "fc00::1:1";
  containerIp6 = "fc00::1:3/7";
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

  containers.goatcounter = {
    autoStart = true;
    privateNetwork = true;

    hostBridge = "br0";
    localAddress6 = containerIp6;

    bindMounts = {
      "/tmp/agenix/password-goatcounter" = {
        isReadOnly = true;
        hostPath = config.age.secrets.password-goatcounter.path;
      };
    };

    # note that we're not taking pkgs here - it doesn't have access to our overlays.
    # instead we're using the outer pkgs.
    # TODO: what does this all mean?
    config = { config, ... }: {
      system.stateVersion = "24.05";

      networking.firewall.allowedTCPPorts = [ 4000 ];

      systemd.services.goatcounter = {
        wantedBy = ["multi-user.target"];
        after = ["network.target"];

        serviceConfig = {
          Type = "simple";
          DynamicUser = true;

          LoadCredential = [
            "password-goatcounter:/tmp/agenix/password-goatcounter"
          ];

          ExecStart = let
            run-goatcounter = pkgs.writeScript "run-goatcounter" ''
              #!/bin/sh

              set -euo pipefail

              password=$(cat $CREDENTIALS_DIRECTORY/password-goatcounter | tr -d '\n')

              # if we don't pass -email-from then it tries to look up the current
              # username, which doesn't work due to the chroot etc. below
              ${pkgs.goatcounter}/bin/goatcounter serve \
                -listen *:4000 \
                -db "postgresql+host=fc00::1:2 password=$password sslmode=disable" \
                -tls http \
                -email-from goatcounter@m.diffeq.com
            '';

          in "${run-goatcounter}";

          Restart = "always";

          RuntimeDirectory = "goatcounter";
          RootDirectory = "/run/goatcounter";
          ReadWritePaths = "";
          BindReadOnlyPaths = [
            "/bin"
            builtins.storeDir
          ];

          PrivateDevices = true;
          PrivateUsers = true;

          CapabilityBoundingSet = "";
          RestrictNamespaces = true;
        };
      };
    };
  };

  age.secrets = {
    password-goatcounter = {
      file = ../../../secrets/db/password-goatcounter.age;
      owner = "root";
      group = "root";
      mode = "600";
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."m.diffeq.com".extraConfig = ''
      reverse_proxy [fc00::1:3]:4000 {
        # 2.5.0 has "-tls proxy" which should make this unnecessary
        # https://github.com/arp242/goatcounter/issues/647#issuecomment-1345559928
        header_down Set-Cookie "^(.*HttpOnly;) (SameSite=None)$" "$1 Secure; $2"
      }
    '';
  };
}
