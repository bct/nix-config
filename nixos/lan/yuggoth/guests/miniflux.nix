{ self, inputs, config, pkgs, ... }:

let
  unshittifyPkgs = inputs.unshittify.packages.${pkgs.system};
in {
  # we need to use the nixpkgs-unstable version of the nitter module.
  # we disable the default version. and then import the unstable version.
  disabledModules = [ "services/misc/nitter.nix" ];

  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/nitter.nix"
  ];

  system.stateVersion = "24.05";

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

  # TODO: pull from the .pub on disk?
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKz7HRp/8LfeXDEhLNbsNBKJWacqXWFZngOzBzwXGNl";
  age.secrets = {
    nitter-guest-accounts = {
      rekeyFile = ../../../../secrets/nitter-guest-accounts.age;
    };

    miniflux-admin-credentials = {
      rekeyFile = ../../../../secrets/miniflux-admin-credentials.age;
    };
  };

  # 8080: nitter
  # 8081: miniflux
  networking.firewall.allowedTCPPorts = [8080 8081];

  services.miniflux = {
    enable = true;
    package = unshittifyPkgs.miniflux;
    config = {
      LISTEN_ADDR = "0.0.0.0:8081";

      # don't stop looking at a feed just because it has failed in the past
      POLLING_PARSING_ERROR_LIMIT = "0";

      # every 5 minutes retrieve 3 feeds.
      SCHEDULER_ROUND_ROBIN_MIN_INTERVAL = "5";
      BATCH_SIZE = "3";
      WORKER_POOL_SIZE = "1";

      # if i'm understanding correctly this is an lower bound on the time
      # between polls. with a large enough number of feeds this value is
      # ~irrelevant.
      POLLING_FREQUENCY = "20";
    };
    adminCredentialsFile = config.age.secrets.miniflux-admin-credentials.path;
  };

  services.nitter = {
    enable = true;
    package = unshittifyPkgs.nitter;
    guestAccounts = config.age.secrets.nitter-guest-accounts.path;
    server.port = 8080;
    server.hostname = "miniflux:8080";
  };
}
