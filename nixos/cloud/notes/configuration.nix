{ self, inputs, config, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "notes";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "23.05";

#  boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];

  systemd.network = {
    netdevs."10-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = config.age.secrets.notes-wireguard-key.path;
      };
      wireguardPeers = [{
        wireguardPeerConfig = {
          # conductum
          PublicKey = "fBOs8h31Jce8FH0eeeKWLvtXNSD7a6PkQoYiJtoOxUo=";
          AllowedIPs = [ "192.168.9.1/32" "192.168.0.0/16" ];
        };
      }];
    };

    networks.wg0 = {
      matchConfig.Name = "wg0";
      address = ["192.168.9.3/16"];

      # use the home router for DNS, so that we resolve borg.domus.diffeq.com to
      # its VPN IP.
      dns = ["192.168.9.1"];
    };
  };

  environment.systemPackages = with pkgs; [
    # for the "vikunja" cli tool
    vikunja-api
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  networking.firewall.allowedUDPPorts = [ 51820 ];

  services.caddy = {
    enable = true;

    virtualHosts."tasks.diffeq.com".extraConfig = ''
      root * ${pkgs.vikunja-frontend}
      encode gzip
      file_server

      reverse_proxy /api/* localhost:3456
      reverse_proxy /.well-known/* localhost:3456
      reverse_proxy /dav/* localhost:3456
    '';

    virtualHosts."nixos-notes.diffeq.com".extraConfig = ''
      reverse_proxy localhost:3000
    '';
  };

  services.postgresql = {
    enable = true;

    ensureDatabases = [ "vikunja" "wiki" ];

    ensureUsers = [
      {
        name = "vikunja-api";
        ensurePermissions = {
          "DATABASE vikunja" = "ALL PRIVILEGES";
        };
      }

      {
        name = "wiki-js";
        ensurePermissions = {
          "DATABASE wiki" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.vikunja = {
    enable = true;
    frontendScheme = "https";
    frontendHostname = "tasks.diffeq.com";

    database = {
      type = "postgres";
      user = "vikunja-api";
      host = "/run/postgresql";
    };

    settings.service = {
      enableregistration = false;
    };
  };

  services.wiki-js = {
    enable = true;
    settings = {
      bindIp = "127.0.0.1";
      port = 3000;

      db = {
        user = "wiki-js";
        host = "/run/postgresql";
      };
    };
  };

  age.secrets = {
    notes-wireguard-key = {
      file = ../../../secrets/notes-wireguard-key.age;
      owner = "systemd-network";
      group = "systemd-network";
      mode = "600";
    };
  };
}
