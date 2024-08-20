{ inputs, config, pkgs, ... }:

let
  unshittifyPkgs = inputs.unshittify.packages.${pkgs.system};
in {
  # we need to use the nixpkgs-unstable version of the nitter module.
  # we disable the default version. and then import the unstable version.
  disabledModules = [ "services/misc/nitter.nix" ];

  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/nitter.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 512;
  };

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

      # every 5 minutes retrieve 15 feeds.
      SCHEDULER_ROUND_ROBIN_MIN_INTERVAL = "5";
      BATCH_SIZE = "15";
      WORKER_POOL_SIZE = "1";

      # if i'm understanding correctly, with a large enough number of feeds this
      # value is ~irrelevant.
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

  age.rekey = {
    masterIdentities = ["/home/bct/.ssh/id_rsa"];
    storageMode = "local";
    localStorageDir = ../../../.. + "/secrets/rekeyed/miniflux";

    # TODO: pull from the .pub on disk?
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKz7HRp/8LfeXDEhLNbsNBKJWacqXWFZngOzBzwXGNl";
  };
}
