{ pkgs, ... }:
{
  system.stateVersion = "25.11";

  microvm = {
    vcpu = 1;
    mem = 1024;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 8192;
      }
    ];

    shares = [
      {
        tag = "video";
        source = "/mnt/bulk/video";
        mountPoint = "/mnt/video";
        proto = "virtiofs";
      }

      {
        tag = "pth";
        source = "/mnt/bulk/media/downloads/pth";
        mountPoint = "/bulk/downloads/pth";
        proto = "virtiofs";
      }

      {
        tag = "ggn";
        source = "/mnt/bulk/software/downloads/ggn";
        mountPoint = "/bulk/downloads/ggn";
        proto = "virtiofs";
      }
    ];
  };

  environment.systemPackages = [
    pkgs.rtorrent
  ];

  users.users.bct = {
    # put home directory in /var so that we can have a single writeable volume.
    home = "/var/home/bct";
    extraGroups = [
      "blackbeard"
      "video-writers"
    ];
  };

  # match up with the host
  users.groups.bct.gid = 1000;
  users.groups.blackbeard.gid = 1001;
  users.groups.video-writers.gid = 1005;
}
