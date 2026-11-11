{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  nixvirt = inputs.nixvirt;
  storagePool = "default";
  storagePoolDir = "/srv/libvirt/images";
  cfg = config.diffeq.nixvirt;
in
{
  imports = [
    nixvirt.nixosModules.default
    ../guest-network
  ];

  options.diffeq.nixvirt = with lib; {
    enable = mkEnableOption "qemu host";

    waitForZfs = mkOption {
      type = types.bool;
      description = mdDoc "Wait for ZFS mounts before launching guests?";
      default = false;
    };

    user = mkOption {
      type = types.str;
      description = mdDoc "User who is allowed to use virsh.";
    };

    guests = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, name, ... }:
          {
            # address, ipv6
            imports = [ ../guest-network/guest-options.nix ];

            options = {
              uuid = mkOption {
                type = types.str;
              };


              tapInterfaceName = mkOption {
                type = types.str;
                default = "vm-${name}"; # <= 15 chars
                description = "Name of the host-side tap interface.";
              };

              restartIfChanged = mkOption {
                type = types.bool;
                default = true;
                description = "Hard power-off and restart this guest on activation if its definition changed. If false, the new definition takes effect the next time the guest is started.";
              };

              memoryMB = mkOption {
                type = types.int;
              };

              disks = mkOption {
                type = types.listOf (
                  types.submodule (
                    { ... }:
                    {
                      options = {
                        device = mkOption {
                          type = types.str;
                        };
                        target = mkOption {
                          type = types.str;
                        };
                      };
                    }
                  )
                );
                default = [ ];
              };

              mounts = mkOption {
                type = types.listOf (
                  types.submodule (
                    { ... }:
                    {
                      options = {
                        source = mkOption {
                          type = types.str;
                        };
                        # this is actually a "mount tag" - it's up to the guest to decide where to mount it.
                        mountPoint = mkOption {
                          type = types.str;
                        };
                      };
                    }
                  )
                );
                default = [ ];
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      # ensure that our storage pool exists, and is only accessible by root & qemu
      # "-" means no automatic cleanup.
      "d ${storagePoolDir} 0770 root qemu-libvirtd -"
    ];

    # allow bct to use virsh
    users.users.${cfg.user} = {
      extraGroups = [ "libvirtd" ];
    };
    home-manager.users.${cfg.user}.home.file.".config/libvirt/libvirt.conf".text = ''
      uri_default = "qemu:///system"
    '';

    virtualisation.libvirtd = {
      enable = true;

      # shut guests down cleanly with the host, rather than saving their memory
      # to disk ("suspend", the default): a saved image can't be restored once
      # the domain definition has changed, e.g. after a deploy.
      onShutdown = "shutdown";

      qemu = {
        # "pkgs.qemu_kvm saves disk space allowing to emulate only host architectures."
        package = pkgs.qemu_kvm;
        vhostUserPackages = [ pkgs.virtiofsd ];
        runAsRoot = false;
      };
    };

    systemd.services.libvirt-guests = lib.mkIf cfg.waitForZfs {
      requires = lib.mkAfter [ "zfs.target" ];
      after = lib.mkAfter [ "zfs.target" ];
    };

    virtualisation.libvirt.enable = true;
    virtualisation.libvirt.connections."qemu:///system".pools = [
      {
        active = true;

        definition = nixvirt.lib.pool.writeXML {
          name = storagePool;
          uuid = "b9f64006-0c8e-4771-9535-eb6df709d579";
          type = "dir";
          target = {
            path = storagePoolDir;
          };
        };

        # these are volumes that should be created; if you're bootstrapping
        # with an existing image you don't need to add it here.
        #
        # instead, create a qcow2 file in /srv/libvirt/images/, and run:
        #     virsh pool-refresh default
        volumes = [
          # {
          #   present = true;
          #   definition = nixvirt.lib.volume.writeXML {
          #     name = "example.qcow2";
          #     capacity = {
          #       count = 80;
          #       unit = "GiB";
          #     };
          #     target.format.type = "qcow2";
          #   };
          # }
        ];
      }
    ];

    # guests use routed taps (nixos/modules/guest-network), not a libvirt
    # network. An empty list makes NixVirt delete any network that exists,
    # e.g. the old "default" network that bridged guests onto the LAN.
    virtualisation.libvirt.connections."qemu:///system".networks = [ ];

    virtualisation.libvirt.connections."qemu:///system".domains = lib.mapAttrsToList (
      name: guest:
      let
        net = config.diffeq.guestNetwork.guests.${name};

        baseXML = nixvirt.lib.domain.templates.linux {
          name = name;
          uuid = guest.uuid;
          memory = {
            count = guest.memoryMB;
            unit = "MiB";
          };
          storage_vol = {
            pool = storagePool;
            volume = "${name}-root.qcow2";
          };

          # this is undocumented, but it seems to turn on virtio_video while turning off DRM.
          virtio_video = null;
        };
        extraDisks = map (disk: {
          type = "block";
          device = "disk";
          driver = {
            name = "qemu";
            type = "raw";
          };
          source = {
            dev = disk.device;
          };
          target = {
            dev = disk.target;
            bus = "virtio";
          };
        }) guest.disks;
        # https://libvirt.org/kbase/virtiofs.html
        mounts = map (mount: {
          type = "mount";
          accessmode = "passthrough";
          driver = {
            type = "virtiofs";
          };
          source = {
            dir = mount.source;
          };
          target = {
            dir = mount.mountPoint;
          };
        }) guest.mounts;
      in
      {
        # State to put the domain in (running/stopped), or null to ignore.
        active = null;
        # Whether to restart the domain, or null to restart only if its
        # definition has changed.
        #
        # This is a hard power-off. If false, the new definition takes effect
        # the next time the guest is started.
        restart = if guest.restartIfChanged then null else false;
        definition = nixvirt.lib.domain.writeXML (
          baseXML
          // {
            # if virtiofs is used we need to set up shared memory.
            memoryBacking = lib.optionalAttrs (mounts != [ ]) {
              source = {
                type = "memfd";
              };
              access = {
                mode = "shared";
              };
            };
            devices = baseXML.devices // {
              # the template uses a nix store path, which would make the definition
              # change (and the guest restart) whenever qemu changes.
              emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";
              # a plain tap with a stable name, that libvirt creates but doesn't
              # attach to anything; nixos/modules/guest-network configures it as a
              # routed link.
              interface = {
                type = "ethernet";
                inherit (baseXML.devices.interface) model;
                mac.address = net.mac;
                target.dev = net.tap;
              };
              disk = baseXML.devices.disk ++ extraDisks;
              filesystem = (baseXML.devices.filesystem or [ ]) ++ mounts;

              # a serial console, for `virsh console <guest>`. The guest side
              # (GRUB + kernel on ttyS0) is in nixos/vms/common/qemu-vm.nix.
              serial = [
                {
                  type = "pty";
                  target.port = 0;
                }
              ];
              console = [
                {
                  type = "pty";
                  target = {
                    type = "serial";
                    port = 0;
                  };
                }
              ];
            };
          }
        );
      }
    ) cfg.guests;
  };
}
