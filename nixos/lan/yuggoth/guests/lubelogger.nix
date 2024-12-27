{ self, inputs, config, ... }:

let
  paperless-nixpkgs = inputs.nixpkgs-lubelogger;
in {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
    "${paperless-nixpkgs}/nixos/modules/services/web-apps/lubelogger.nix"
  ];

  system.stateVersion = "24.11";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  age.secrets = {
    lego-proxy-lubelogger = {
      generator.script = "ssh-ed25519-pubkey";
      rekeyFile = ../../../../secrets/lego-proxy/lubelogger.age;
      owner = "acme";
      group = "acme";
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "lubelogger.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-lubelogger.path; }
    ];
    group = "caddy";
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  networking.firewall.allowedTCPPorts = [80 443];

  services.lubelogger = {
    enable = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts."lubelogger.domus.diffeq.com" = {
      useACMEHost = "lubelogger.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.lubelogger.port}";
    };
  };
}
