{ pkgs, config, ... }: {
  networking.nat = {
    enable = true;
    internalInterfaces = ["wg0"];
    externalInterface = "ens3";
  };

  networking.firewall.allowedUDPPorts = [ 51820 ];

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

        # dunwich
        {
          wireguardPeerConfig.PublicKey = "JHMq4bUoPeJ2LqoHkOvhvEtiYooegA7/2XXwl7604zQ=";
          wireguardPeerConfig.AllowedIPs = [ "192.168.8.5/32" ];
        }
      ];
    };

    networks."20-wg0" = {
      matchConfig.Name = "wg0";
      address = ["192.168.8.254/24"];
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
}
