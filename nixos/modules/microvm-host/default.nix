{
  self,
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.diffeq.microvms;
  enabledGuests = lib.filterAttrs (_: guest: guest.enable) cfg.guests;
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ../guest-network
  ];

  options.diffeq.microvms = with lib; {
    enable = mkEnableOption "microvm host";

    waitForZfs = mkOption {
      type = types.bool;
      description = mdDoc "Wait for ZFS mounts before launching guests?";
      default = false;
    };

    uplinkInterface = mkOption {
      type = types.str;
      description = "The host's LAN interface. It gets the host's address by DHCP; guests are routed through it.";
    };

    guestsDir = mkOption {
      type = types.path;
      description = "Directory containing a ${name}.nix file for each guest.";
    };

    guests = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, name, ... }:
          {
            # address, ipv6
            imports = [ ../guest-network/guest-options.nix ];

            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Include this microvm on the host? If false, the guest is not evaluated, built or started.";
              };

              hostName = mkOption {
                type = types.str;
                default = name;
              };

              tapInterfaceName = mkOption {
                type = types.str;
                default = "vm-${config.hostName}"; # <= 15 chars
              };


              machineId = mkOption {
                type = types.str;
                description = "Populates /etc/machine-id. The machine ID is a single newline-terminated, hexadecimal, 32-character, lowercase ID.";
              };

              agenixHostPrefix = mkOption {
                type = types.str;
                default = "/run/agenix-vms/${name}";
                description = "host directory containing secrets to pass to the VM";
              };

              restartIfChanged = mkOption {
                type = types.bool;
                default = true;
                description = "Restart this MicroVM if the systemd units are changed, i.e. if it has been updated by rebuilding the host.";
              };

              requires = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "systemd Requires=";
              };

              wants = mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = "systemd Wants=. Like requires, but stopping or restarting the dependency does not stop or restart this guest.";
              };

              startDelay = mkOption {
                type = types.nullOr types.int;
                default = null;
                description = "delay (in seconds) before starting the guest during host boot, to reduce load. not applied when the guest is started or restarted after boot.";
              };

              readyPorts = mkOption {
                type = types.listOf types.port;
                default = [ ];
                description = "TCP ports on the guest that must accept connections before the microvm@ unit counts as started.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # https://astro.github.io/microvm.nix/simple-network.html
    systemd.network.enable = true;

    # the host's LAN address. Guests' taps are routed point-to-point links,
    # configured by nixos/modules/guest-network.
    systemd.network.networks."10-lan" = {
      matchConfig.Name = cfg.uplinkInterface;
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };

    microvm.host.enable = true;
    # Enable if all your MicroVMs run with a Hypervisor that sends readiness notification over a VSOCK.
    # **Danger!** If one of your MicroVMs doesn't do this, its systemd service will not start up successfully!
    microvm.host.useNotifySockets = true;

    # https://astro.github.io/microvm.nix/faq.html#how-to-centralize-logging-with-journald
    # create a symlink of each MicroVM's journal under the host's /var/log/journal
    systemd.tmpfiles.rules = lib.mapAttrsToList (
      vmName: vmConfig:
      "L+ /var/log/journal/${vmConfig.machineId} - - - - /var/lib/microvms/${vmName}/journal/${vmConfig.machineId}"
    ) enabledGuests;

    age.secrets = lib.concatMapAttrs (vmName: vmConfig: {
      "ssh-host-${vmName}" = {
        path = "${vmConfig.agenixHostPrefix}/ssh-host";
        rekeyFile = config.diffeq.secretsPath + /ssh/host-${vmName}.age;
        generator.script = "ssh-ed25519-pubkey";

        # the guest can't resolve a symlink, because it would point to a path
        # that only exists on the host.
        symlink = false;
      };
    }) enabledGuests;

    microvm.vms = lib.mapAttrs (vmName: vmConfig: {
      specialArgs = { inherit self inputs outputs; };

      restartIfChanged = vmConfig.restartIfChanged;

      config = {
        diffeq.microvmName = vmName;
        diffeq.microvmConfig = vmConfig;
        diffeq.guestNetworkClient = config.diffeq.guestNetwork.guests.${vmName};
        diffeq.secretsPath = config.diffeq.secretsPath;

        imports = [
          "${self}/nixos/modules/guest-network/client.nix"
          "${self}/nixos/common/microvm.nix"
          (cfg.guestsDir + "/${vmName}.nix")
        ];
      };
    }) enabledGuests;

    # microvm@ service dependencies
    systemd.services = lib.concatMapAttrs (vmName: vmConfig: {
      "microvm@${vmName}" = {
        requires = vmConfig.requires;
        wants = vmConfig.wants;
        after = vmConfig.requires ++ vmConfig.wants;

        # only delay while the host is booting, so that restarting a guest
        # (e.g. when redeploying it) doesn't have to wait.
        serviceConfig.ExecStartPre = lib.mkIf (vmConfig.startDelay != null) [
          (pkgs.writeShellScript "microvm-${vmName}-start-delay" ''
            if [ "$(${config.systemd.package}/bin/systemctl is-system-running)" = starting ]; then
              echo "host is booting; executing ${toString vmConfig.startDelay}s start delay..."
              sleep ${toString vmConfig.startDelay}
              echo "start delay complete."
            fi
          '')
        ];
        # the start timeout includes ExecStartPre, so leave room for the delay.
        serviceConfig.TimeoutStartSec = lib.mkIf (vmConfig.startDelay != null) (
          config.microvm.host.startupTimeout + vmConfig.startDelay
        );

        # probe by address rather than name, so this doesn't depend on DNS.
        serviceConfig.ExecStartPost = lib.mkIf (vmConfig.readyPorts != [ ]) [
          (pkgs.writeShellScript "microvm-${vmName}-wait-ready" ''
            for port in ${toString vmConfig.readyPorts}; do
              until ${pkgs.netcat}/bin/nc -z -w 2 ${config.diffeq.guestNetwork.guests.${vmName}.address} "$port"; do
                sleep 1
              done
              echo "port $port is accepting connections"
            done
          '')
        ];
      };

      "microvm-virtiofsd@${vmName}" = lib.mkIf cfg.waitForZfs {
        requires = lib.mkAfter [ "zfs.target" ];
        after = lib.mkAfter [ "zfs.target" ];
      };
    }) enabledGuests;
  };
}
