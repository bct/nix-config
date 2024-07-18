{ config, inputs, pkgs, ... }: let
  unshittifyPkgs = inputs.unshittify.packages.${pkgs.system};
in {
  # we need to use the nixpkgs-unstable version of the nitter module.
  # we disable the default version. and then import the unstable version.
  disabledModules = [ "services/misc/nitter.nix" ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/nitter.nix"
  ];

  age.secrets = {
    nitter-guest-accounts = {
      file = ../../../secrets/nitter-guest-accounts.age;
      owner = "root";
      group = "root";
      mode = "600";
    };

    miniflux-admin-credentials = {
      file = ../../../secrets/miniflux-admin-credentials.age;
      owner = "root";
      group = "root";
      mode = "600";
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

      POLLING_FREQUENCY = "5";
      SCHEDULER_ROUND_ROBIN_MIN_INTERVAL = "5";
      BATCH_SIZE = "25";
      WORKER_POOL_SIZE = "1";
    };
    adminCredentialsFile = config.age.secrets.miniflux-admin-credentials.path;
  };

  services.nitter = {
    enable = true;
    package = unshittifyPkgs.nitter;
    guestAccounts = config.age.secrets.nitter-guest-accounts.path;
    server.port = 8080;
    server.hostname = "yuurei:8080";
  };
}
