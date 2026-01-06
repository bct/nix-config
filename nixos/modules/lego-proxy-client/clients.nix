# lego-proxy whitelist.
# keys in this attrset refer to entries in secrets/lego-proxy/
{
  auth.domain = "auth.domus.diffeq.com";

  books = {
    domain = "books.domus.diffeq.com";
  };

  bookmarks = {
    domain = "bookmarks.domus.diffeq.com";
  };

  flood = {
    domain = "flood.domus.diffeq.com";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDAju9q9t7fV3gjA4Xeup8apk4fFQQZy8Y0QmEYEhCGd torrent-scraper:lego-proxy-flood";
  };

  grafana = {
    domain = "grafana.domus.diffeq.com";
  };

  homepage.domain = "homepage.domus.diffeq.com";

  immich = {
    domain = "immich.domus.diffeq.com";
  };

  jellyfin = {
    domain = "jellyfin.domus.diffeq.com";
  };

  ldap.domain = "ldap.domus.diffeq.com";

  lubelogger = {
    domain = "lubelogger.domus.diffeq.com";
  };

  oidc.domain = "oidc.domus.diffeq.com";

  mail = {
    domain = "mail.domus.diffeq.com";
  };

  paperless = {
    domain = "paperless.domus.diffeq.com";
  };

  radarr = {
    domain = "radarr.domus.diffeq.com";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM7e7g8qEpc8BFv6MRdkZvlxHwrhusa9en98e4EhT/70 torrent-scraper:lego-proxy-radarr";
  };

  recipes = {
    domain = "recipes.domus.diffeq.com";
  };

  spectator = {
    domain = "spectator.domus.diffeq.com";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFk2zCBoSRaNUJfUhFNGLI1r+H5EVtWNukvTG6Lq0z+J spectator:lego-proxy-spectator";
  };

  sonarr = {
    domain = "sonarr.domus.diffeq.com";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJobOIdFH71iFfj2IrMr63xh6r+Ydhc/SGkifV2wAIoc torrent-scraper:lego-proxy-sonarr";
  };

  shell-of-the-old = {
    domain = "shell-of-the-old.domus.diffeq.com";
  };

  stereo = {
    domain = "stereo.domus.diffeq.com";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGps5WovLRtcOWuBupjj2CC2YxVtQsHjHa4UN686eU3Q stereo:lego-proxy-spectator";
  };
}
