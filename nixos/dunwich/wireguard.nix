{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  networking.wg-quick.interfaces = {
    wg0 = {
      autostart = false;
      address = [ "192.168.8.5/32" ];
      dns = [ "192.168.8.1" ];

      # run manually:
      #   umask 077 && mkdir /etc/wireguard && wg genkey >/etc/wireguard/wg0.key
      privateKeyFile = "/etc/wireguard/wg0.key";

      peers = [
        # viator.diffeq.com
        {
          publicKey = "DAEuIyEFD5M2MCc+Hz3WPVjWYo6eaXxrPo8FF124FWQ=";
          allowedIPs = [ "192.168.0.0/20" ];
          endpoint = "viator.diffeq.com:51820";
        }
      ];
    };
  };
}
