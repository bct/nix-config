# to generate UUIDs:
#
#     ruby -r securerandom -e "puts SecureRandom.uuid"
{ inputs, pkgs, ... }:
let
  nixvirt = inputs.nixvirt;
  storagePool = "default";
in
{
  imports = [
    nixvirt.nixosModules.default
  ];

  # allow bct to use virsh
  users.users.bct = {
    extraGroups = [ "libvirtd" ];
  };
  home-manager.users.bct.home.file.".config/libvirt/libvirt.conf".text = ''
    uri_default = "qemu:///system"
  '';

  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      # "pkgs.qemu_kvm saves disk space allowing to emulate only host architectures."
      package = pkgs.qemu_kvm;
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
          path = "/srv/libvirt/images";
        };
      };

      # these are valumes that should be created; if you're bootstrapping
      # with an existing image you don't need to add it here.
      #
      # instead, create a qcow2 file in /srv/libvirt/images/, and run:
      #     virsh pool-refresh default
      volumes = [
        {
          present = true;
          definition = nixvirt.lib.volume.writeXML {
            name = "medley-root.qcow2";
            capacity = {
              count = 80;
              unit = "GiB";
            };
            target.format.type = "qcow2";
          };
        }
      ];
    }
  ];

  virtualisation.libvirt.connections."qemu:///system".domains = [
    {
      definition = nixvirt.lib.domain.writeXML (
        nixvirt.lib.domain.templates.linux {
          name = "medley";
          uuid = "76a25495-6730-4982-9761-637f57f18e4a";
          memory = {
            count = 3;
            unit = "GiB";
          };
          storage_vol = {
            pool = storagePool;
            volume = "medley-root.qcow2";
          };

          # br0 is set up in microvm-host.nix
          bridge_name = "br0";

          # qemu fails to launch with a DRI error if virtio_video = true
          virtio_video = false;
        }
      );
    }

    {
      definition =
        let
          baseXML = nixvirt.lib.domain.templates.linux {
            name = "mail";
            uuid = "6bdbad6f-540c-4114-a063-16fec1995347";
            memory = {
              count = 512;
              unit = "MiB";
            };
            storage_vol = {
              pool = storagePool;
              volume = "mail-root.qcow2";
            };

            # br0 is set up in microvm-host.nix
            bridge_name = "br0";

            # qemu fails to launch with a DRI error if virtio_video = true
            virtio_video = false;
          };
        in
        nixvirt.lib.domain.writeXML (
          baseXML
          // {
            devices = baseXML.devices // {
              disk = baseXML.devices.disk ++ [
                {
                  type = "block";
                  device = "disk";
                  driver = {
                    name = "qemu";
                    type = "raw";
                  };
                  source = {
                    dev = "/dev/mapper/fastpool-mail--var";
                  };
                  target = {
                    dev = "vdb";
                    bus = "virtio";
                  };
                }
              ];
            };
          }
        );
    }
  ];
}
