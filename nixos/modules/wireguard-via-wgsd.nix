{ config, lib, pkgs, ... }:


let
  cfg = config.services.wireguard-via-wgsd;

  wireguardInterface = "wg0";

  # the DNS host that can provide information about our WireGuard peers
  wgsdDns = "viator.diffeq.com:53";

  # the DNS zone that we're discovering peers in
  wgsdZone = "diffeq.com";

  # a nameserver to add to resolv.conf
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

        # run manually:
        #   umask 077 && mkdir /etc/wireguard && wg genkey >/etc/wireguard/wg0.key
        privateKeyFile = "/etc/wireguard/${wireguardInterface}.key";

        postUp = ''
          # this has to happen before we update our DNS configuration, so that we can
          # look up the IP of our DNS server.
          ${pkgs.wgsd}/bin/wgsd-client -device ${wireguardInterface} -zone=${wgsdZone} -dns=${wgsdDns}

          # this is manually accomplishing what the "DNS" option would accomplish.
          # https://manpages.debian.org/unstable/wireguard-tools/wg-quick.8.en.html
          echo "nameserver ${dns}" | ${pkgs.openresolv}/bin/resolvconf -a tun.%i -m 0 -x
        '';

        postDown = ''
          # this is manually accomplishing what the "DNS" option would accomplish.
          # https://manpages.debian.org/unstable/wireguard-tools/wg-quick.8.en.html
          ${pkgs.openresolv}/bin/resolvconf -d tun.%i
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
