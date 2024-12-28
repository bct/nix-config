{ self, inputs, config, ... }:

let
  lubelogger-nixpkgs = inputs.nixpkgs-lubelogger;
in {
  imports = [
    "${lubelogger-nixpkgs}/nixos/modules/services/web-apps/lubelogger.nix"
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

  networking.firewall.allowedTCPPorts = [80 443];

  services.lubelogger = {
    enable = true;
    package = lubelogger-nixpkgs.legacyPackages.x86_64-linux.lubelogger;
  };

  services.caddy = {
    enable = true;
    virtualHosts."lubelogger.domus.diffeq.com" = {
      useACMEHost = "lubelogger.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.lubelogger.port}";
    };
  };
}
