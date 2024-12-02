{ pkgs, config, ... }: {
  # make the "wg" command available for debugging.
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  # we'll listen for wireguard connections on port 51820.
  networking.firewall.allowedUDPPorts = [ 51820 ];

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
          PublicKey = "pZ8XBJYx9gWz7emqNDkmBF+BMQ9IW9ESHCfZEj75VHw=";
          AllowedIPs = [ "192.168.8.1/32" "192.168.0.0/16" ];
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
      rekeyFile = ../../../secrets/viator-wireguard-key.age;
      owner = "systemd-network";
      group = "systemd-network";
    };
  };
}
