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
  ];

  options.diffeq.nixvirt = with lib; {
    enable = mkEnableOption "qemu host";

    user = mkOption {
      type = types.str;
      description = mdDoc "User who is allowed to use virsh.";
    };

    guests = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, name, ... }:
          {
            options = {
              uuid = mkOption {
                type = types.str;
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

      qemu = {
        # "pkgs.qemu_kvm saves disk space allowing to emulate only host architectures."
        package = pkgs.qemu_kvm;
        vhostUserPackages = [ pkgs.virtiofsd ];
        runAsRoot = false;
      };
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

    virtualisation.libvirt.connections."qemu:///system".domains = lib.mapAttrsToList (
      name: guest:
      let
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

          # br0 is set up in microvm-host.nix
          # TODO
          bridge_name = "br0";

          # qemu fails to launch with a DRI error if virtio_video = true
          virtio_video = false;
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
              disk = baseXML.devices.disk ++ extraDisks;
              filesystem = (baseXML.devices.filesystem or [ ]) ++ mounts;
            };
          }
        );
      }
    ) cfg.guests;
  };
}
