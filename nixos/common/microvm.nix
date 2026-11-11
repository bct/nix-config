# common configuration for a microvm guest.
{
  self,
  lib,
  config,
  ...
}:
let
  # mount point for secrets passed from the host to the VM
  # TODO: complain if anything else is mounted directly to /mnt!
  agenixHostMountPoint = "/mnt/agenix-host";
  vmName = config.diffeq.microvmName;
  vmConfig = config.diffeq.microvmConfig;
  # this guest's network settings, from the host; see nixos/modules/guest-network.
  net = config.diffeq.guestNetworkClient;
in
{
  imports = [
    # note that we're not including "${self}/nixos/common/nix.nix" here
    # it complains:
    #     Your system configures nixpkgs with an externally created
    #     instance.
    #     `nixpkgs.config` options should be passed when creating the
    #     instance instead.
    # presumably the overlays are being passed through anyways.
    # the other nix configuration seems OK to ignore.
    "${self}/nixos/common/injected-deps.nix"
    "${self}/nixos/common/headless.nix"
    "${self}/nixos/common/node-exporter.nix"
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  options = {
    # see microvm-host.nix for the definition of this type.
    diffeq.microvmName = lib.mkOption {
      type = lib.types.str;
    };

    # see microvm-host.nix for the definition of this type.
    diffeq.microvmConfig = lib.mkOption {
      type = lib.types.attrs;
    };
  };

  config = {
    networking.hostName = vmConfig.hostName;

    systemd.network.enable = true;

    # microvm.nix disables wait-online, citing
    # https://github.com/systemd/systemd/issues/29388
    # as long as we have one network (client.nix's "20-guest")
    # that sets RequiredForOnline, we should be able to re-enable it.
    systemd.network.wait-online.enable = true;
    age.rekey.hostPubkey = config.diffeq.secretsPath + /ssh/host-${vmName}.pub;

    # the system activation script depends on the host SSH key, which
    # comes from this directory.
    fileSystems.${agenixHostMountPoint}.neededForBoot = true;

    services.openssh.hostKeys = [
      {
        path = "${agenixHostMountPoint}/ssh-host";
        type = "ed25519";
      }
    ];

    # home-manager assumes that /nix is writeable.
    diffeq.headless.enable-home-manager = false;

    # we can't do GC if /nix isn't writeable
    # (possibly we should allow this if there's a writableStoreOverlay?)
    nix.gc.automatic = false;

    microvm = {
      # convert 32 char hex to a UUID
      machineId =
        let
          hs = offset: len: builtins.substring offset len vmConfig.machineId;
        in
        builtins.concatStringsSep "-" [
          (hs 0 8)
          (hs 8 4)
          (hs 12 4)
          (hs 16 4)
          (hs 20 12)
        ];

      interfaces = [
        {
          type = "tap";
          id = vmConfig.tapInterfaceName;
          inherit (net) mac;
        }
      ];

      shares = [
        {
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
          proto = "virtiofs";
        }

        {
          tag = "agenix";
          source = "${vmConfig.agenixHostPrefix}";
          mountPoint = agenixHostMountPoint;
          proto = "virtiofs";
        }

        {
          tag = "journal";
          source = "/var/lib/microvms/${vmName}/journal";
          mountPoint = "/var/log/journal";
          proto = "virtiofs";
          socket = "journal.sock";
        }
      ];
    };
  };
}
