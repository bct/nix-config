{ ... }:
{
  users.users.bct = {
    # put home directory in /var so that we can have a single writeable volume.
    home = "/var/home/bct";
    extraGroups = [
      "blackbeard"
      "rtorrent"
      "video-writers"
    ];
  };

  # match up with the host
  users.groups.bct.gid = 1000;
  users.groups.blackbeard.gid = 1001;
  users.groups.video-writers.gid = 1005;
  users.groups.rtorrent.gid = 1006;
}
