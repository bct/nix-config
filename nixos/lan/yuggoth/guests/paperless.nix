{ self, inputs, lib, config, pkgs, ... }:

let
  paperless-nixpkgs = inputs.nixpkgs-unstable;
in {
  imports = [
    "${paperless-nixpkgs}/nixos/modules/services/misc/paperless.nix"

    "${self}/nixos/modules/lego-proxy-client"
  ];

  disabledModules = [ "services/misc/paperless.nix" ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 2;
    mem = 2560;

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
    domains = [ "paperless" ];
    group = "caddy";
  };

  services.paperless = {
    enable = true;
    mediaDir = "/mnt/paperless/media";
    environmentFile = config.age.secrets.paperless-env.path;
    consumptionDirIsPublic = true;

    settings = {
      PAPERLESS_DBHOST = "db.domus.diffeq.com";
    };

    package = pkgs.paperless-ngx;
  };

  # can't have a private network if we need to talk to the database.
  systemd.services.paperless-consumer.serviceConfig.PrivateNetwork = lib.mkForce false;
  systemd.services.paperless-scheduler.serviceConfig.PrivateNetwork = lib.mkForce false;

  age.secrets = {
    fs-mi-go-paperless = {
      rekeyFile = ../../../../secrets/fs/mi-go-paperless.age;
    };

    paperless-env = {
      rekeyFile = ./secrets/paperless-env.age;
      owner = config.services.paperless.user;
    };
  };

  fileSystems."/mnt/paperless" = {
    device = "//mi-go.domus.diffeq.com/paperless";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},cifsacl,uid=${config.services.paperless.user},credentials=${config.age.secrets.fs-mi-go-paperless.path}"];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.caddy = {
    enable = true;
    virtualHosts."paperless.domus.diffeq.com" = {
      useACMEHost = "paperless.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.paperless.port}";
    };
  };
}
