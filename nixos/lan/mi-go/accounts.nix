{ config, ... }:
{
  users.users.bct = {
    extraGroups = [
      "blackbeard"
      "video-writers"
      "syncthing"
    ];
  };
  users.groups.bct.gid = config.diffeq.accounts.groupIds.bct;

  users.users.blackbeard = {
    isSystemUser = true;
    uid = config.diffeq.accounts.userIds.blackbeard;
    group = "blackbeard";
  };
  users.groups.blackbeard.gid = config.diffeq.accounts.groupIds.blackbeard;

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
    uid = config.diffeq.accounts.userIds.torrent-scraper;
    group = "torrent-scraper";
    extraGroups = [
      "inbox-droppers"
      "video-writers"
      "blackbeard"
    ];
  };
  users.groups.torrent-scraper.gid = config.diffeq.accounts.groupIds.torrent-scraper;
  users.groups.video-writers.gid = config.diffeq.accounts.groupIds.video-writers;

  users.users.rtorrent = {
    isSystemUser = true;
    uid = config.diffeq.accounts.userIds.rtorrent;
    group = "rtorrent";
    extraGroups = [ "video-writers" ];
  };
  users.groups.rtorrent.gid = config.diffeq.accounts.groupIds.rtorrent;

  users.users.immich = {
    isSystemUser = true;
    uid = config.diffeq.accounts.userIds.immich;
    group = "immich";
    home = "/mnt/bulk/home/photos/immich";
  };
  users.groups.immich.gid = config.diffeq.accounts.groupIds.immich;

  users.users.paperless = {
    isSystemUser = true;
    uid = config.diffeq.accounts.userIds.paperless;
    group = "paperless";
    home = "/mnt/bulk/home/photos/immich";
  };
  users.groups.paperless.gid = config.diffeq.accounts.groupIds.paperless;

  users.groups.syncthing.gid = 983;
}
