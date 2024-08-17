{ self, inputs, outputs, config, ... }:

{
  microvm.vms.miniflux = {
    specialArgs = { inherit self inputs outputs; };

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
      ];

      system.stateVersion = "24.05";
      networking.hostName = "miniflux";

      systemd.network.enable = true;
      systemd.network.networks."20-lan" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };

      environment.etc."machine-id" = {
        mode = "0644";
        text = "b42e25167b6bc7ca726ea9f41ce5ffcb\n";
      };

      # TODO: figure out why SSHD doesn't start when this is hooked up
      services.openssh.hostKeys = [
        {
          path = "/run/agenix-host/ssh-host";
          type = "ed25519";
        }
      ];

      microvm = {
        vcpu = 1;
        mem = 512;

        interfaces = [
          {
            type = "tap";
            id = "vm-miniflux";
            # Locally administered have one of 2/6/A/E in the second nibble.
            mac = "02:00:00:00:00:01";
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
            source = "/run/agenix-vms/minflux";
            mountPoint = "/run/agenix-host";
            proto = "virtiofs";
          }

          {
            # On the host
            source = "/var/lib/microvms/miniflux/journal";
            # In the MicroVM
            mountPoint = "/var/log/journal";
            tag = "journal";
            proto = "virtiofs";
            socket = "journal.sock";
          }
        ];
      };
    };
  };
}
