{ self, pkgs, lib, ... }:

let
  acme-zoneedit = pkgs.writeShellApplication {
    name = "acme-zoneedit";
    runtimeInputs = [ pkgs.curl ];
    text = builtins.readFile ../../../modules/acme-zoneedit/acme-zoneedit.sh;
  };
  clients = import ../lego-proxy-clients.nix;
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
        domain = "spectator.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk2zCBoSRaNUJfUhFNGLI1r+H5EVtWNukvTG6Lq0z+J spectator:lego-proxy-spectator";
      }
      {
        domain = "stereo.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGps5WovLRtcOWuBupjj2CC2YxVtQsHjHa4UN686eU3Q stereo:lego-proxy-spectator";
      }
      {
        domain = "flood.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAju9q9t7fV3gjA4Xeup8apk4fFQQZy8Y0QmEYEhCGd torrent-scraper:lego-proxy-flood";
      }
      {
        domain = "radarr.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7e7g8qEpc8BFv6MRdkZvlxHwrhusa9en98e4EhT/70 torrent-scraper:lego-proxy-radarr";
      }
      {
        domain = "sonarr.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJobOIdFH71iFfj2IrMr63xh6r+Ydhc/SGkifV2wAIoc torrent-scraper:lego-proxy-sonarr";
      }
      {
        domain = "miniflux.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZEMtL1gR8npkfwmN5XN4p5a7qFgfr2gJIWQpyA/JGH miniflux:lego-proxy-miniflux";
      }
      {
        domain = "nitter.domus.diffeq.com";
        pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAxjglC0aoZBlx23w3TR7dnpI/udIRDMtVezl4Bj5Rvq miniflux:lego-proxy-nitter";
      }
    ] ++ lib.mapAttrsToList (name: clientConfig: {
      domain = clientConfig.domain;
      pubKey = builtins.readFile ../../../../secrets/lego-proxy/${name}.pub;
    }) clients;
  };
}
