{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-apps/grimmory.nix"
  ];

  age.secrets = {
    grimmory-env = {
      rekeyFile = ./secrets/grimmory-env.age;
      owner = "booklore";
      group = "booklore";
    };
  };

  services.grimmory = {
    enable = true;
    # TODO(unstable): drop this override once nixpkgs fixes the stale
    # pnpmDeps hash for grimmory-frontend.
    package = pkgs.unstable.grimmory.overrideAttrs (old: {
      frontend = old.frontend.overrideAttrs (oldFrontend: {
        pnpmDeps = oldFrontend.pnpmDeps.overrideAttrs {
          outputHash = "sha256-a8uiK/tkzPUPHycjVZ6UVAozfBGDz5o2ipYpG3TmR1o=";
        };
      });
    });

    database = {
      createLocally = false;
      name = "booklore";
      host = "db.domus.diffeq.com";
      user = "booklore";
    };

    # sets DATABASE_PASSWORD
    # TODO: services.grimmory.database.passwordFile ?
    environmentFile = config.age.secrets.grimmory-env.path;
    stateDir = "/var/lib/booklore";

    user = "booklore";
    group = "booklore";

    domain = "booklore.domus.diffeq.com";
    caddy = {
      enable = true;
      virtualHost.useACMEHost = "booklore.domus.diffeq.com";
    };
  };

  systemd.services.grimmory.path = [ pkgs.kepubify ];

  # the module only creates the user/group when they're named "grimmory".
  users.users.booklore = {
    isSystemUser = true;
    group = "booklore";
    home = config.services.grimmory.stateDir;
  };
  users.groups.booklore = { };

  # allow me to put files in the bookdrop.
  users.users.bct.extraGroups = [ "booklore" ];
}
