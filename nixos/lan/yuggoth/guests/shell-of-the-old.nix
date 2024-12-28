{ self, inputs, config, pkgs, ... }: {
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
