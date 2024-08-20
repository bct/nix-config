{ self, inputs, outputs, config, pkgs, ... }:

let
  hostName = "torrent-scraper";
  tapInterfaceName = "vm-torrent-scra"; # <= 15 chars
  machineId = "e5b7d8199d4a4a34fb6748faef793248";
in {
  microvm.vms.torrent-scraper = {
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
      networking.hostName = hostName;

      systemd.network.enable = true;
      systemd.network.networks."20-lan" = {
        matchConfig.Type = "ether";
        networkConfig.DHCP = "yes";
      };

      environment.etc."machine-id" = {
        mode = "0644";
        text = "${machineId}\n";
      };

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
            id = tapInterfaceName;
            # Locally administered have one of 2/6/A/E in the second nibble.
            mac = "02:00:00:00:00:02";
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
            source = "/run/agenix-vms/${hostName}";
            mountPoint = "/run/agenix-host";
            proto = "virtiofs";
          }

          {
            tag = "journal";
            source = "/var/lib/microvms/${hostName}/journal";
            mountPoint = "/var/log/journal";
            proto = "virtiofs";
            socket = "journal.sock";
          }
        ];

        volumes = [
          {
            image = "var.img";
            mountPoint = "/var";
            size = 1024;
          }
        ];
      };

      networking.firewall.allowedTCPPorts = [ 8081 ];

      services.sickbeard = {
        enable = true;
        package = pkgs.sickgear;
      };
    };
  };
}
