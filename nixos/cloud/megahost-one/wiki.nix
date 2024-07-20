{ config, lib, pkgs, ... }:

let
  hostIp6 = "fc00::1:1";
  containerIp6 = "fc00::1:4/7";
  cfgContainerSecrets = config.megahost.container-secrets;
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

  containers.wiki = {
    autoStart = true;
    privateNetwork = true;

    hostBridge = "br0";
    localAddress6 = containerIp6;

    config = { config, ... }: {
      system.stateVersion = "24.05";

      networking.firewall.allowedTCPPorts = [ 3000 ];

      services.wiki-js = {
        enable = true;
        settings = {
          bindIP = "::"; # listen on all IPv6 (and IPv4?) interfaces
          port = 3000;

          db = {
            db = "wiki-js";
            user = "wiki-js";
            host = "fc00::1:2";
            pass = "$(DB_PASS)";
          };
        };
      };

      systemd.services.wiki-js.serviceConfig = {
        LoadCredential = [
          "password-wikijs:${cfgContainerSecrets.wiki.passwordWikijs.containerPath}"
        ];

        ExecStart = let
          run-wikijs = pkgs.writeScript "run-wikijs" ''
            #!/bin/sh

            set -euo pipefail

            export DB_PASS=$(cat $CREDENTIALS_DIRECTORY/password-wikijs | tr -d '\n')

            ${pkgs.nodejs_18}/bin/node ${pkgs.wiki-js}/server
          '';
          in lib.mkForce "${run-wikijs}";
      };
    };
  };

  megahost.container-secrets.wiki = {
    passwordWikijs = {
      hostPath = config.age.secrets.password-wikijs.path;
    };
  };

  age.secrets = {
    password-wikijs.file = ../../../secrets/db/password-wikijs.age;
  };

  services.caddy = {
    enable = true;
    virtualHosts."notes.diffeq.com".extraConfig = ''
      reverse_proxy [fc00::1:4]:3000
    '';
  };
}
