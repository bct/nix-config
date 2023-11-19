{ pkgs, ... }:


let
  wireguardInterface = "wg0";
  wireguardAddress = "192.168.8.17/32";

  # we can't use a hostname here - it's resolved after the interface is brought
  # up, and adding the interface might have broken DNS resolution.
  wgsdDns = "66.135.19.196:53";
  wgsdZone = "diffeq.com";

in {
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
      address = [ wireguardAddress ];
      dns = [ "192.168.8.1" ];

      # run manually:
      #   umask 077 && mkdir /etc/wireguard && wg genkey >/etc/wireguard/wg0.key
      privateKeyFile = "/etc/wireguard/${wireguardInterface}.key";

      postUp = ''
        ${pkgs.wgsd}/bin/wgsd-client -device ${wireguardInterface} -zone=${wgsdZone} -dns=${wgsdDns}
      '';

      peers = [
        # router
        {
          publicKey = "pZ8XBJYx9gWz7emqNDkmBF+BMQ9IW9ESHCfZEj75VHw=";
          allowedIPs = [ "192.168.8.1/32" "192.168.0.0/20" ];
        }
      ];
    };
  };
}
