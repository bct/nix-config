{ self, inputs, config, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"
  ];

  networking.hostName = "viator";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "23.05";

  networking.nat = {
    enable = true;
    internalInterfaces = ["wg0"];
    externalInterface = "ens3";
  };

  networking.firewall.allowedUDPPorts = [ 53 51820 ];

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  systemd.network = {
    netdevs."20-wg0" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg0";
      };
      wireguardConfig = {
        ListenPort = 51820;
        PrivateKeyFile = config.age.secrets.viator-wireguard-key.path;
      };
      wireguardPeers = [
        # router
        {
          wireguardPeerConfig.PublicKey = "pZ8XBJYx9gWz7emqNDkmBF+BMQ9IW9ESHCfZEj75VHw=";
          wireguardPeerConfig.AllowedIPs = [ "192.168.8.1/32" "192.168.0.0/16" ];
        }

        # Galaxy A52 5G (2023)
        {
          wireguardPeerConfig.PublicKey = "rOiHdUBgYlUYXyohifWCwyyrG9XusIHQsId9OcsZJGE=";
          wireguardPeerConfig.AllowedIPs = [ "192.168.8.2/32" ];
        }

        # cimmeria
        {
          wireguardPeerConfig.PublicKey = "Dr++eMTOCnbCFsCsOxTEMxornygk0hVOwlaUGww9fkk=";
          wireguardPeerConfig.AllowedIPs = [ "192.168.8.4/32" ];
        }
      ];
    };

    networks."20-wg0" = {
      matchConfig.Name = "wg0";
      address = ["192.168.8.3/16"];

      # use the home router for DNS.
      dns = ["192.168.8.1"];
      domains = ["~domus.diffeq.com"];
    };
  };

  age.secrets = {
    viator-wireguard-key = {
      file = ../../../secrets/viator-wireguard-key.age;
      owner = "systemd-network";
      group = "systemd-network";
      mode = "600";
    };
  };

  systemd.services.imap-jump-socat = {
    description = "Forwards IMAP via socat";

    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:993,fork TCP:mail.domus.diffeq.com:993";
      Restart = "always";
    };
  };

  services.coredns = {
    enable = true;

    config = ''
      .:53 {
        bind ens3
        debug
        wgsd diffeq.com. wg0
      }
    '';

    package = pkgs.coredns.override {
      externalPlugins = [ "wgsd" ];
      vendorSha256 = "sha256-K2s1MrS8Ot5LFh4ZbtTtYxdYla5rUYSZ/RQ/UgA52hw=";
    };
  };

  # wgsd needs cap_net_admin to read the wireguard peers
  systemd.services.coredns.serviceConfig.CapabilityBoundingSet = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
  systemd.services.coredns.serviceConfig.AmbientCapabilities = pkgs.lib.mkForce "cap_net_bind_service cap_net_admin";
}
