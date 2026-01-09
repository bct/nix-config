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
    systemd.network.networks."20-lan" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };

    environment.etc."machine-id" = {
      mode = "0644";
      text = "${vmConfig.machineId}\n";
    };

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
      preStart = lib.mkIf (vmConfig.startDelay != null) ''
        echo "executing ${toString vmConfig.startDelay} start delay..."
        sleep ${toString vmConfig.startDelay}
        echo "start delay complete."
      '';

      interfaces = [
        {
          type = "tap";
          id = vmConfig.tapInterfaceName;
          mac = vmConfig.tapInterfaceMac;
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
