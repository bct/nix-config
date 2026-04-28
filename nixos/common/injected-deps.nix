# https://jade.fyi/blog/flakes-arent-real/
{ lib, ... }:
{
  options.diffeq = {
    secretsPath = lib.mkOption {
      type = lib.types.path;
      description = "The path to the agenix encrypted secrets. Injected by the flake.";
    };

    hostNames = lib.mkOption {
      type = lib.types.attrs;
    };

    accounts.userIds = lib.mkOption {
      type = lib.types.attrs;
    };

    accounts.groupIds = lib.mkOption {
      type = lib.types.attrs;
    };
  };

  config.diffeq = {
    hostNames = {
      db = "db.domus.diffeq.com";
      oidc = "oidc.domus.diffeq.com"; # dex
      auth = "auth.domus.diffeq.com"; # tinyauth
      ldap = "ldap.domus.diffeq.com"; # lldap
      tasks = "tasks.domus.diffeq.com"; # vikunja
    };

    accounts = {
      userIds = {
        blackbeard = 1002;
        torrent-scraper = 1003;
        rtorrent = 1004;
        immich = 1005;
        paperless = 1006;
      };

      groupIds = {
        bct = 1000;
        blackbeard = 1001;
        torrent-scraper = 1004;
        video-writers = 1005;
        rtorrent = 1006;
        immich = 1007;
        paperless = 1008;
      };
    };
  };
}
