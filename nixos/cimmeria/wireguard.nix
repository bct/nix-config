{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  networking.wg-quick.interfaces = {
    wg0 = {
      autostart = false;
      address = [ "192.168.8.4/32" ];
      dns = [ "192.168.8.1" ];
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
