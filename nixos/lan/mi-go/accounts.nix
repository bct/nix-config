{ ... }:
{
  users.users.bct = {
    extraGroups = [
      "blackbeard"
      "video-writers"
      "syncthing"
    ];
  };
  users.groups.bct = {
    gid = 1000;
  };

  users.users.blackbeard = {
    isSystemUser = true;
    uid = 1002;
    group = "blackbeard";
  };
  users.groups.blackbeard = {
    gid = 1001;
  };

  users.users.amanda = {
    isNormalUser = true;
    uid = 1001;
    group = "amanda";
  };
  users.groups.amanda = {
    gid = 1002;
  };

  users.groups.inbox-droppers = {
    gid = 1003;
  };

  users.users.torrent-scraper = {
    isSystemUser = true;
    uid = 1003;
    group = "torrent-scraper";
    extraGroups = [
      "inbox-droppers"
      "video-writers"
    ];
  };
  users.groups.torrent-scraper = {
    gid = 1004;
  };

  users.groups.video-writers = {
    gid = 1005;
  };

  users.users.rtorrent = {
    isSystemUser = true;
    uid = 1004;
    group = "rtorrent";
    extraGroups = [ "video-writers" ];
  };
  users.groups.rtorrent = {
    gid = 1006;
  };

  users.users.immich = {
    isSystemUser = true;
    uid = 1005;
    group = "immich";
    home = "/mnt/bulk/home/photos/immich";
  };
  users.groups.immich = {
    gid = 1007;
  };

  users.users.paperless = {
    isSystemUser = true;
    uid = 1006;
    group = "paperless";
    home = "/mnt/bulk/home/photos/immich";
  };
  users.groups.paperless = {
    gid = 1008;
  };

  users.groups.syncthing.gid = 983;
}
