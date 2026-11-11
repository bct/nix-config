{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.airsonic-refix;
  env-js = pkgs.writeTextDir "env.js" ''
    window.env = {
      SERVER_URL: ${builtins.toJSON cfg.serverUrl},
    }
  '';
  airsonicRefixWithEnv = pkgs.buildEnv {
    name = "airsonic-refix-env";
    paths = [
      pkgs.airsonic-refix
      env-js
    ];
  };
  # airsonicRefixJukeboxWithEnv = pkgs.buildEnv {
  #   name = "airsonic-refix-jukebox-env";
  #   paths = [
  #     inputs.airsonic-refix-jukebox.packages.${pkgs.stdenv.hostPlatform.system}.default
  #     env-js
  #   ];
  # };
in
{
  options.services.airsonic-refix = {
    enable = lib.mkEnableOption "airsonic-refix service";
    hostname = lib.mkOption {
      type = lib.types.str;
    };
    serverUrl = lib.mkOption {
      type = lib.types.str;
      example = "https://music.example.com:4747";
      description = "URL of the Subsonic-compatible server that the web UI talks to.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.caddy.extraGroups = [ "acme" ];

    services.caddy = {
      enable = true;

      virtualHosts."${cfg.hostname}" = {
        useACMEHost = cfg.hostname;
        extraConfig = ''
          root * ${airsonicRefixWithEnv}
          encode gzip

          @nocache path /index.html /env.js

          # "route" keeps these in the order written, so the Cache-Control
          # matcher sees the path after try_files has rewritten it.
          route {
            try_files {path} /index.html
            header @nocache Cache-Control no-cache
            file_server
          }
        '';
      };
    };
  };
}
