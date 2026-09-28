{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    "${inputs.alvr-grimmory}/nixos/modules/services/web-apps/grimmory.nix"
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
    package = inputs.alvr-grimmory.legacyPackages.x86_64-linux.grimmory;

    database = {
      createLocally = false;
      name = "booklore";
      host = "db.domus.diffeq.com";
      user = "booklore";
    };

    # sets DATABASE_PASSWORD
    environmentFile = config.age.secrets.grimmory-env.path;
    dataDir = "/var/lib/booklore";

    user = "booklore";
    group = "booklore";
  };

  systemd.services.grimmory.path = [ pkgs.kepubify ];

  services.caddy = {
    enable = true;
    virtualHosts."booklore.domus.diffeq.com" = {
      useACMEHost = "booklore.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.grimmory.port}";
    };
  };

  # allow me to put files in the bookdrop.
  users.users.bct.extraGroups = [ "booklore" ];
}
