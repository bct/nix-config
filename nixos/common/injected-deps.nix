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
  };

  config.diffeq = {
    hostNames = {
      db = "db.domus.diffeq.com";
      oidc = "oidc.domus.diffeq.com"; # dex
      auth = "auth.domus.diffeq.com"; # tinyauth
      ldap = "ldap.domus.diffeq.com"; # lldap
      tasks = "tasks.domus.diffeq.com"; # vikunja
    };
  };
}
