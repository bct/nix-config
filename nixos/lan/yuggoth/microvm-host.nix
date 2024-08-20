{ self, inputs, outputs, lib, config, ... }:

let
  cfg = config.yuggoth.microvms;
in {
  imports = [
    inputs.microvm.nixosModules.host
  ];

  options.yuggoth.microvms = with lib; {
    interfaceToBridge = mkOption {
      type = types.str;
      description = mdDoc "The host interface that should be connected to the br0 bridge.";
    };

    guests = mkOption {
      type = types.attrsOf (types.submodule (
        {config, ...}: {
          options = {
            hostName = mkOption {
              type = types.str;
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

    # https://astro.github.io/microvm.nix/faq.html#how-to-centralize-logging-with-journald
    # create a symlink of each MicroVM's journal under the host's /var/log/journal
    systemd.tmpfiles.rules = lib.mapAttrsToList (vmName: vmConfig:
      "L+ /var/log/journal/${vmConfig.machineId} - - - - /var/lib/microvms/${vmName}/journal/${vmConfig.machineId}"
    ) cfg.guests;

    age.secrets = let
      generate-ssh-host-key = hostName: {pkgs, file, ...}: ''
          ${pkgs.openssh}/bin/ssh-keygen -qt ed25519 -N "" -C "root@${hostName}" -f ${lib.escapeShellArg (lib.removeSuffix ".age" file)}
          priv=$(${pkgs.coreutils}/bin/cat ${lib.escapeShellArg (lib.removeSuffix ".age" file)})
          ${pkgs.coreutils}/bin/shred -u ${lib.escapeShellArg (lib.removeSuffix ".age" file)}
          echo "$priv"
        '';
    in lib.concatMapAttrs (vmName: vmConfig: {
      "ssh-host-${vmName}" = {
        path = "/run/agenix-vms/${vmName}/ssh-host";
        symlink = false; # the VM can't resolve the symlink
        rekeyFile = ../../../secrets/ssh/host-${vmName}.age;
        generator.script = generate-ssh-host-key vmName;
      };
    }) cfg.guests;

    microvm.vms = lib.mapAttrs (vmName: vmConfig: {
      specialArgs = { inherit self inputs outputs; };
      config = {
        imports = [ ./guests/${vmName}.nix ];
      };
    }) cfg.guests;
  };
}
