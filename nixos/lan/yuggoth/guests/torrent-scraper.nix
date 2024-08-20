{ pkgs, ... }: {
  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];

  services.sickbeard = {
    enable = true;
    package = pkgs.sickgear;
  };
}
