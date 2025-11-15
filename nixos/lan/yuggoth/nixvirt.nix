# to generate a UUID:
#
#     ruby -r securerandom -e "puts SecureRandom.uuid"
{ inputs, pkgs, ... }: let
  nixvirt = inputs.nixvirt;
  storagePool = "default";
in {
  imports = [
    nixvirt.nixosModules.default
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # "pkgs.qemu_kvm saves disk space allowing to emulate only host architectures."
      package = pkgs.qemu_kvm;
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
        target = { path = "/srv/libvirt/images"; };
      };

      volumes = [
        {
          present = true;
          definition = nixvirt.lib.volume.writeXML {
            name = "medley-root.qcow2";
            capacity = { count = 80; unit = "GiB"; };
            target.format.type = "qcow2";
          };
        }
      ];
    }
  ];

  virtualisation.libvirt.connections."qemu:///session".domains =
  [
    {
      definition = nixvirt.lib.domain.writeXML (nixvirt.lib.domain.templates.linux {
        name = "medley";
        uuid = "76a25495-6730-4982-9761-637f57f18e4a";
        memory = { count = 3; unit = "GiB"; };
        storage_vol = { pool = storagePool; volume = "medley-root.qcow2"; };

        # br0 is set up in microvm-host.nix
        bridge_name = "br0";

        # qemu fails to launch with a DRI error if virtio_video = true
        virtio_video = false;
      });
    }
  ];
}
