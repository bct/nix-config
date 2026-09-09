{ pkgs, lib, ... }:
let
  port = 3000;
in
{
  # attempting to fix crash in karakeep browser
  # Sep 08 18:31:22 medley karakeep-browser-start[19485]: [19474:19509:0908/183122.384202:FATAL:third_party/skia/src/ports/SkFontMgr_FontConfigInterface.cpp:163] Not implemented.
  fonts.fontconfig.enable = lib.mkForce true;

  services.karakeep = {
    enable = true;

    # https://github.com/NixOS/nixpkgs/pull/554776
    package = pkgs.unstable.karakeep;

    extraEnvironment = {
      NEXTAUTH_URL = "https://bookmarks.domus.diffeq.com/";
      PORT = toString port;
    };
  };

  # attempt to automatically migrate the database when meilisearch is updated.
  services.meilisearch.settings.experimental_dumpless_upgrade = true;

  services.caddy = {
    enable = true;
    virtualHosts."bookmarks.domus.diffeq.com" = {
      useACMEHost = "bookmarks.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString port}";
    };
  };
}
