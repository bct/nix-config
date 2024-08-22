{ inputs, pkgs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

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

  fileSystems."/mnt/video" = {
    device = "//mi-go.domus.diffeq.com/video";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    in ["${automount_opts},credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"];
  };

  age.secrets = {
    fs-mi-go-torrent-scraper = {
      rekeyFile = ../../../../secrets/fs/mi-go-torrent-scraper.age;
    };
  };

  age.rekey = {
    masterIdentities = ["/home/bct/.ssh/id_rsa"];
    storageMode = "local";
    localStorageDir = ../../../.. + "/secrets/rekeyed/torrent-scraper";

    # TODO: pull from the .pub on disk?
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwu2O9ulPoL1YYEIkbDOjA5B7h/efXYjrPPV0xNpOxY root@torrent-scraper";
  };
}
