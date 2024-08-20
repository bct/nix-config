{ self, inputs, config, pkgs, ... }:

let
  hostName = "miniflux";
  tapInterfaceName = "vm-${hostName}"; # <= 15 chars
  # Locally administered have one of 2/6/A/E in the second nibble.
  tapInterfaceMac = "02:00:00:00:00:01";
  machineId = "b42e25167b6bc7ca726ea9f41ce5ffcb";

  unshittifyPkgs = inputs.unshittify.packages.${pkgs.system};
in {
  imports = [
    # note that we're not including "${self}/nixos/common/nix.nix" here
    # it complains:
    #     Your system configures nixpkgs with an externally created
    #     instance.
    #     `nixpkgs.config` options should be passed when creating the
    #     instance instead.
    # presumably the overlays are being passed through anyways.
    # the other nix configuration seems OK to ignore.
    "${self}/nixos/common/headless.nix"

    # !!!! custom imports
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/nitter.nix"
  ];

  system.stateVersion = "24.05";
  networking.hostName = hostName;

  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
  };

  environment.etc."machine-id" = {
    mode = "0644";
    text = "${machineId}\n";
  };

  services.openssh.hostKeys = [
    {
      path = "/run/agenix-host/ssh-host";
      type = "ed25519";
    }
  ];

  microvm = {
    vcpu = 1;
    mem = 512;

    interfaces = [
      {
        type = "tap";
        id = tapInterfaceName;
        mac = tapInterfaceMac;
      }
    ];

    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }

      {
        tag = "agenix";
        source = "/run/agenix-vms/${hostName}";
        mountPoint = "/run/agenix-host";
        proto = "virtiofs";
      }

      {
        # On the host
        source = "/var/lib/microvms/${hostName}/journal";
        # In the MicroVM
        mountPoint = "/var/log/journal";
        tag = "journal";
        proto = "virtiofs";
        socket = "journal.sock";
      }
    ];
  };

  # we need to use the nixpkgs-unstable version of the nitter module.
  # we disable the default version. and then import the unstable version.
  disabledModules = [ "services/misc/nitter.nix" ];

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
