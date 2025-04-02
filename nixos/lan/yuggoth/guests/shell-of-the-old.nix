{ self, inputs, config, pkgs, ... }: {
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.11";

  microvm = {
    vcpu = 1;
    mem = 4096;

    volumes = [
      {
        image = "/dev/mapper/ssdpool-shelloftheold--root";
        mountPoint = "/";
        autoCreate = false;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "shell-of-the-old" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;
    virtualHosts."shell-of-the-old.domus.diffeq.com" = {
      useACMEHost = "shell-of-the-old.domus.diffeq.com";
      extraConfig = ''
        reverse_proxy localhost:8080
        header Referrer-Policy no-referrer
      '';
    };
  };
}
