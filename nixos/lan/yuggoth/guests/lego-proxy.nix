{ self, config, pkgs, lib, ... }:

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

    clients = lib.mapAttrsToList (name: clientConfig: {
      domain = clientConfig.domain;
      pubKey = if clientConfig ? "pubKey"
                then clientConfig.pubKey
                else builtins.readFile (config.diffeq.secretsPath + /lego-proxy/${name}.pub);
    }) clients;
  };
}
