{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.services.airsonic-refix;
  env-js = pkgs.writeTextDir "env.js" ''
    window.env = {
      SERVER_URL: "https://stereo.domus.diffeq.com:4747",
    }
  '';
  airsonicRefixWithEnv = pkgs.buildEnv {
    name = "airsonic-refix-env";
    paths = [ pkgs.airsonic-refix env-js ];
  };
  airsonicRefixJukeboxWithEnv = pkgs.buildEnv {
    name = "airsonic-refix-jukebox-env";
    paths = [
      inputs.airsonic-refix-jukebox.packages.x86_64-linux.default
      env-js
    ];
  };
in {
  options.services.airsonic-refix = {
    enable = lib.mkEnableOption "airsonic-refix service";
  };

  config = lib.mkIf cfg.enable {
    users.users.nginx.extraGroups = [ "acme" ];

    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;

      virtualHosts."stereo.domus.diffeq.com" = {
        default = true;
        root = airsonicRefixJukeboxWithEnv;

        addSSL = true;
        useACMEHost = "stereo.domus.diffeq.com";

        locations = {
          "/" = {
            tryFiles = "$uri /index.html";
          };

          "/index.html" = {
            extraConfig = ''
              add_header 'Cache-Control' 'no-cache';
            '';
          };

          "/env.js" = {
            extraConfig = ''
              add_header 'Cache-Control' 'no-cache';
            '';
          };
        };
      };
    };
  };
}
