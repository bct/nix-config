{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.tandoor-recipes = {
    enable = true;
    extraConfig = {
      # https://docs.tandoor.dev/system/configuration/#gunicorn-media
      GUNICORN_MEDIA = "1";

      SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";
      SOCIALACCOUNT_PROVIDERS_FILE = config.age.secrets.tandoor-allauth-py.path;
    };
  };

  systemd.services.tandoor-recipes.serviceConfig = {
    # ExecStartPre often hits the default 90s timeout
    TimeoutStartSec = 180;

    # convert our file to an environment variable.
    ExecStart = lib.mkForce (
      pkgs.writeShellScript "start" ''
        export SOCIALACCOUNT_PROVIDERS=$(<$SOCIALACCOUNT_PROVIDERS_FILE)
        ${config.services.tandoor-recipes.package.python.pkgs.gunicorn}/bin/gunicorn recipes.wsgi
      ''
    );
  };

  services.caddy = {
    enable = true;
    virtualHosts."recipes.domus.diffeq.com" = {
      useACMEHost = "recipes.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.tandoor-recipes.port}";
    };
  };

  age.secrets = {
    tandoor-allauth-py = {
      rekeyFile = config.diffeq.secretsPath + /oidc/tandoor-allauth-py.age;
      owner = config.services.tandoor-recipes.user;
      group = config.services.tandoor-recipes.user;
    };
  };
}
