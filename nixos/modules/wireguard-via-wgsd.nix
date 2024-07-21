{ config, lib, pkgs, ... }:


let
  cfg = config.services.wireguard-via-wgsd;

  wireguardInterface = "wg0";

  # this is viator.diffeq.com
  # we can't use a hostname here - it's resolved after the interface is brought
  # up, and adding the interface might have broken DNS resolution.
  wgsdDns = "104.156.252.101:53";
  wgsdZone = "diffeq.com";

  dns = "192.168.8.1";
  routerPublicKey = "pZ8XBJYx9gWz7emqNDkmBF+BMQ9IW9ESHCfZEj75VHw=";
  routerAllowedIps = [ "192.168.8.1/32" "192.168.0.0/20" ];
in {
  options = {
    services.wireguard-via-wgsd = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "IP address to use for this host on the wireguard network.";
      };
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      # make "wg" available so that we can generate keys, check status, etc.
      wireguard-tools
    ];

    # allow users to turn wireguard on and off without a password.
    security.sudo.extraRules = [
      {
        groups = [ "networkmanager" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl start wg-quick-${wireguardInterface}.service";
            options = ["NOPASSWD"];
          }

          {
            command = "/run/current-system/sw/bin/systemctl stop wg-quick-${wireguardInterface}.service";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    networking.wg-quick.interfaces = {
      ${wireguardInterface} = {
        autostart = false;
        address = [ cfg.address ];
        dns = [ dns ];

        # run manually:
        #   umask 077 && mkdir /etc/wireguard && wg genkey >/etc/wireguard/wg0.key
        privateKeyFile = "/etc/wireguard/${wireguardInterface}.key";

        postUp = ''
          ${pkgs.wgsd}/bin/wgsd-client -device ${wireguardInterface} -zone=${wgsdZone} -dns=${wgsdDns}
        '';

        peers = [
          # router
          {
            publicKey = routerPublicKey;
            allowedIPs = routerAllowedIps;
          }
        ];
      };
    };
  };
}
