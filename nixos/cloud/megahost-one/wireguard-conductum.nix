{ self, inputs, config, pkgs, ... }: {
  networking.firewall.allowedUDPPorts = [ 51821 ];

  systemd.network = {
    netdevs."20-wg1" = {
      netdevConfig = {
        Kind = "wireguard";
        Name = "wg1";
      };
      wireguardConfig = {
        ListenPort = 51821;
        PrivateKeyFile = config.age.secrets.megahost-one-conductum-wg-key.path;
      };
      wireguardPeers = [{
        wireguardPeerConfig = {
          # conductum
          PublicKey = "fBOs8h31Jce8FH0eeeKWLvtXNSD7a6PkQoYiJtoOxUo=";
          AllowedIPs = [ "192.168.9.1/32" "192.168.0.0/16" ];
        };
      }];
    };

    networks."20-wg1" = {
      matchConfig.Name = "wg1";
      address = ["192.168.9.4/16"];

      # use the home router for DNS, so that we resolve borg.domus.diffeq.com to
      # its VPN IP.
      dns = ["192.168.9.1"];
      domains = ["~domus.diffeq.com"];
    };
  };

  age.secrets = {
    megahost-one-conductum-wg-key = {
      rekeyFile = ../../../secrets/wg/megahost-one-conductum.age;
      owner = "systemd-network";
      group = "systemd-network";
    };
  };
}
