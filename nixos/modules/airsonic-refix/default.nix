{ lib, pkgs, config, ... }:

let
  cfg = config.services.airsonic-refix;
  env-js = pkgs.writeTextDir "env.js" ''
    window.env = {
      SERVER_URL: "http://stereo.domus.diffeq.com:4747",
    }
  '';
  airsonicRefixWithEnv = pkgs.buildEnv {
    name = "airsonic-refix-env";
    paths = [ pkgs.airsonic-refix env-js ];
  };
in {
  options.services.airsonic-refix = {
    enable = lib.mkEnableOption "airsonic-refix service";
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedGzipSettings = true;

      virtualHosts."stereo.domus.diffeq.com" = {
        default = true;
        root = airsonicRefixWithEnv;

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
