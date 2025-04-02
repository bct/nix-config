{ self, inputs, config, ... }:

let
  lubelogger-nixpkgs = inputs.nixpkgs-lubelogger;
in
{
  imports = [
    "${lubelogger-nixpkgs}/nixos/modules/services/web-apps/lubelogger.nix"
    "${self}/nixos/modules/lego-proxy-client"
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

  services.lego-proxy-client = {
    enable = true;
    domains = [ "lubelogger" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  age.secrets = {
    lubelogger-env = {
      rekeyFile = ./secrets/lubelogger-env.age;
      owner = config.services.lubelogger.user;
    };
  };

  services.lubelogger = {
    enable = true;
    package = lubelogger-nixpkgs.legacyPackages.x86_64-linux.lubelogger;
    environmentFile = config.age.secrets.lubelogger-env.path;
    settings = {
      MailConfig__EmailServer = "mail.domus.diffeq.com";
      MailConfig__EmailFrom = "lubelogger@mail.domus.diffeq.com";
      MailConfig__Port = "587";
      MailConfig__Username = "lubelogger@mail.domus.diffeq.com";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."lubelogger.domus.diffeq.com" = {
      useACMEHost = "lubelogger.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.lubelogger.port}";
    };
  };
}
