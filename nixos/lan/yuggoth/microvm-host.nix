{ self, inputs, outputs, lib, config, ... }:

let
  cfg = config.yuggoth.microvms;

  # mount point for secrets passed from the host to the VM
  agenixHostMountPoint = "/mnt/agenix-host";

  # host directory containing secrets to pass to each VM
  agenixVmPrefix = "/run/agenix-vms";
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

    age.secrets = lib.concatMapAttrs (vmName: vmConfig: {
      "ssh-host-${vmName}" = {
        path = "${agenixVmPrefix}/${vmName}/ssh-host";
        rekeyFile = ../../../secrets/ssh/host-${vmName}.age;
        generator.script = "ssh-ed25519-pubkey";

        # the guest can't resolve a symlink, because it would point to a path
        # that only exists on the host.
        symlink = false;
      };
    }) cfg.guests;

    microvm.vms = lib.mapAttrs (vmName: vmConfig: {
      specialArgs = { inherit self inputs outputs; };
      config = {
        imports = [
          ./guests/${vmName}.nix

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
              "${self}/nixos/common/headless.nix"
              "${self}/nixos/common/node-exporter.nix"
            ];

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
                }

                {
                  tag = "agenix";
                  source = "${agenixVmPrefix}/${vmName}";
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
        ];
      };
    }) cfg.guests;
  };
}
