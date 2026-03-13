{ ... }:
{
  imports = [
    ../modules/beets
  ];

  systemd.user.mounts.mnt-beets = {
    Unit = {
      Description = "Mount /mnt/beets";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Mount = {
      What = "bct@mi-go.domus.diffeq.com:/mnt/bulk/beets";
      Where = "/mnt/beets";
      Type = "fuse.sshfs";
      Options = "_netdev,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount";
      TimeoutSec = 60;
    };
  };
}
