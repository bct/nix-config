{ config, lib, ... }:
{
  users.users.bct = {
    # put home directory in /var so that we can have a single writeable volume.
    home = "/var/home/bct";
    # this is the easiest way to control the owner of our downloads.
    group = lib.mkForce "blackbeard";
    extraGroups = [
      "bct"
      "rtorrent"
      "video-writers"
    ];
  };

  # match up with the host
  users.groups.bct.gid = config.diffeq.accounts.groupIds.bct;
  users.groups.blackbeard.gid = config.diffeq.accounts.groupIds.blackbeard;
  users.groups.video-writers.gid = config.diffeq.accounts.groupIds.video-writers;
  users.groups.rtorrent.gid = config.diffeq.accounts.groupIds.rtorrent;

  users.users = {
    caddy.extraGroups = [ "acme" ];
    nginx.extraGroups = [ "acme" ];
  };

  # allow bct to have more open files (for rtorrent)
  security.pam.loginLimits = [
    {
      domain = "bct";
      type = "soft";
      item = "nofile";
      value = "8192";
    }
  ];
}
