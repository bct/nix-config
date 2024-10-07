{ self, inputs, config, pkgs, ... }:

let
  unshittifyPkgs = inputs.unshittify.packages.${pkgs.system};
in {
  # we need to use the nixpkgs-unstable version of the nitter module.
  # we disable the default version. and then import the unstable version.
  disabledModules = [ "services/misc/nitter.nix" ];

  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/nitter.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 1280;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  age.secrets = {
    db-password-miniflux = {
      rekeyFile = ../../../../secrets/db/password-db-postgres-miniflux.age;
    };

    nitter-guest-accounts = {
      rekeyFile = ../../../../secrets/nitter-guest-accounts.age;
    };

    miniflux-admin-credentials = {
      rekeyFile = ../../../../secrets/miniflux-admin-credentials.age;
    };

    lego-proxy-miniflux = {
      generator.script = "ssh-ed25519";
      rekeyFile = ../../../../secrets/lego-proxy/miniflux.age;
      owner = "acme";
      group = "acme";
    };

    lego-proxy-nitter = {
      generator.script = "ssh-ed25519";
      rekeyFile = ../../../../secrets/lego-proxy/nitter.age;
      owner = "acme";
      group = "acme";
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "miniflux.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-miniflux.path; }
      { domain = "nitter.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-nitter.path; }
    ];
    group = "caddy";
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
    8080 # nitter
    8081 # miniflux
  ];

  services.miniflux = {
    enable = true;
    package = unshittifyPkgs.miniflux;
    createDatabaseLocally = false;
    config = {
      LISTEN_ADDR = "127.0.0.1:8081";
      DATABASE_URL_FILE = "/run/miniflux/database-url";

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

  systemd.services.miniflux = {
    serviceConfig.LoadCredential = [
      "password-miniflux:${config.age.secrets.db-password-miniflux.path}"
    ];

    preStart = let
      template = "host=db.domus.diffeq.com user=miniflux password=\${DB_PASSWORD} dbname=miniflux sslmode=disable";
    in ''
      DB_PASSWORD=$(cat $CREDENTIALS_DIRECTORY/password-miniflux | tr -d '\n')

      echo '${template}' | \
        DB_PASSWORD="$DB_PASSWORD" ${pkgs.envsubst}/bin/envsubst | \
        (umask 0077; cat >/run/miniflux/database-url)
    '';
  };

  services.nitter = {
    enable = true;
    package = unshittifyPkgs.nitter;
    guestAccounts = config.age.secrets.nitter-guest-accounts.path;

    server = {
      port = 8080;
      hostname = "nitter.domus.diffeq.com";
      https = true;
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."miniflux.domus.diffeq.com" = {
      useACMEHost = "miniflux.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:8081";
    };

    virtualHosts."nitter.domus.diffeq.com" = {
      useACMEHost = "nitter.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:8080";
    };
  };
}
