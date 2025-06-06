{ self, inputs, outputs, lib, config, ... }:

let
  cfg = config.yuggoth.microvms;
  mkGuestModule = import ./microvm/mkGuestModule.nix;
  secretsRoot = ../../../secrets;
in {
  imports = [
    inputs.microvm.nixosModules.host
  ];

  options.yuggoth.microvms = with lib; {
    interfaceToBridge = mkOption {
      type = types.str;
      description = "The host interface that should be connected to the br0 bridge.";
    };

    guests = mkOption {
      type = types.attrsOf (types.submodule (
        {config, name, ...}: {
          options = {
            hostName = mkOption {
              type = types.str;
              default = name;
            };

            tapInterfaceName = mkOption {
              type = types.str;
              default = "vm-${config.hostName}"; # <= 15 chars
            };

            tapInterfaceMac = mkOption {
              type = types.str;
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
              default = [];
              description = "systemd Requires=";
            };

            startDelay = mkOption {
              type = types.nullOr types.int;
              default = null;
              description = "delay before booting the service, to ensure prerequisites are available and reduce load on system boot.";
            };
          };
        }
      ));
    };
  };

  config = {
    # https://astro.github.io/microvm.nix/simple-network.html
    systemd.network.enable = true;

    # bridge ethernet and VM interfaces
    systemd.network.networks."10-lan" = {
      matchConfig.Name = [cfg.interfaceToBridge "vm-*"];
      networkConfig = {
        Bridge = "br0";
      };
    };

    systemd.network.netdevs."br0" = {
      netdevConfig = {
        Name = "br0";
        Kind = "bridge";
      };
    };

    systemd.network.networks."10-lan-bridge" = {
      matchConfig.Name = "br0";
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "routable";
    };

    microvm.host.enable = true;
    # Enable if all your MicroVMs run with a Hypervisor that sends readiness notification over a VSOCK.
    # **Danger!** If one of your MicroVMs doesn't do this, its systemd service will not start up successfully!
    microvm.host.useNotifySockets = true;

    # https://astro.github.io/microvm.nix/faq.html#how-to-centralize-logging-with-journald
    # create a symlink of each MicroVM's journal under the host's /var/log/journal
    systemd.tmpfiles.rules = lib.mapAttrsToList (vmName: vmConfig:
      "L+ /var/log/journal/${vmConfig.machineId} - - - - /var/lib/microvms/${vmName}/journal/${vmConfig.machineId}"
    ) cfg.guests;

    age.secrets = lib.concatMapAttrs (vmName: vmConfig: {
      "ssh-host-${vmName}" = {
        path = "${vmConfig.agenixHostPrefix}/ssh-host";
        rekeyFile = ../../../secrets/ssh/host-${vmName}.age;
        generator.script = "ssh-ed25519-pubkey";

        # the guest can't resolve a symlink, because it would point to a path
        # that only exists on the host.
        symlink = false;
      };
    }) cfg.guests;

    microvm.vms = lib.mapAttrs (vmName: vmConfig: {
      specialArgs = { inherit self inputs outputs; };

      restartIfChanged = vmConfig.restartIfChanged;

      config = {
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

          "${self}/nixos/common/node-exporter.nix"
          "${self}/nixos/common/agenix-rekey.nix"

          (mkGuestModule vmName { inherit vmConfig lib; })
          ./guests/${vmName}.nix

          (
            let pubKey = secretsRoot + /ssh/host-${vmName}.pub;
            in lib.optionalAttrs
                (builtins.pathExists pubKey)
                { age.rekey.hostPubkey = pubKey; }
          )
        ];
      };
    }) cfg.guests;

    # microvm@ service dependencies
    systemd.services = lib.mapAttrs' (vmName: vmConfig: {
      name = "microvm@${vmName}";
      value = { requires = vmConfig.requires; };
    }) cfg.guests;
  };
}
