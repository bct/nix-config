{ self, pkgs, lib, ... }:

let
  acme-zoneedit = pkgs.writeShellApplication {
    name = "acme-zoneedit";
    runtimeInputs = [ pkgs.curl ];
    text = builtins.readFile ../../../modules/acme-zoneedit/acme-zoneedit.sh;
  };
  clients = import ../../../modules/lego-proxy-client/clients.nix;
in {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-host"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 256;
  };

  age.secrets = {
    zoneedit = {
      rekeyFile = ./lego-proxy/secrets/zoneedit.age;
      owner = "lego-proxy";
      group = "lego-proxy";
    };
  };

  services.lego-proxy-host = {
    enable = true;
    execCommand = "${acme-zoneedit}/bin/acme-zoneedit";

    clients = [
      {
        domain = "stereo.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGps5WovLRtcOWuBupjj2CC2YxVtQsHjHa4UN686eU3Q stereo:lego-proxy-spectator";
      }
    ] ++ lib.mapAttrsToList (name: clientConfig: {
      domain = clientConfig.domain;
      pubKey = if clientConfig ? "pubKey"
                then clientConfig.pubKey
                else builtins.readFile ../../../../secrets/lego-proxy/${name}.pub;
    }) clients;
  };
}
