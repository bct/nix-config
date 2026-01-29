{ pkgs, lib, ... }:
let
  pkg = pkgs.profilarr;
  bind = "127.0.0.1";
  port = 6868;
  pythonEnv = pkg.python.buildEnv.override {
    extraLibs = with pkg.python.pkgs; [
      pkg
      gunicorn
    ];
  };
in
{
  # https://github.com/Dictionarry-Hub/profilarr/blob/v1.1.3/Dockerfile
  systemd.services.profilarr = {
    enable = false;
    serviceConfig = {
      ExecStart = ''
        ${lib.getExe' pythonEnv "gunicorn"} --bind ${bind}:${toString port} --timeout 600 profilarr.main:create_app()
      '';

      User = "profilarr";
      Group = "profilarr";
      DynamicUser = true;
      StateDirectory = "profilarr";
      WorkingDirectory = "/var/lib/profilarr";
      RuntimeDirectory = "profilarr";
    };
  };
}
