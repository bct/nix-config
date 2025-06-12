vmName: {vmConfig, lib}:
let
  # mount point for secrets passed from the host to the VM
  agenixHostMountPoint = "/mnt/agenix-host";
in {
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

  # the system activation script depends on the host SSH key, which
  # comes from this directory.
  fileSystems.${agenixHostMountPoint}.neededForBoot = true;

  services.openssh.hostKeys = [
    {
      path = "${agenixHostMountPoint}/ssh-host";
      type = "ed25519";
    }
  ];

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
}
