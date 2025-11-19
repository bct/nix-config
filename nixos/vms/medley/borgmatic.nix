{ self, config, lib, pkgs, ... }:

{
  imports = [ "${self}/nixos/modules/borgmatic" ];

  age.secrets = {
    ssh-borg-medley = {
      rekeyFile = config.diffeq.secretsPath + /ssh/borg-medley.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };

  diffeq.borgmatic = {
    enable = true;
    backupName = "medley.domus.diffeq.com";
    sshKeyPath = config.age.secrets.ssh-borg-medley.path;

    settings = {
      source_directories = [
        "/var/lib/tandoor-recipes/recipes"
        "/var/lib/karakeep"
      ];

      sqlite_databases = [
        {
          name = "tandoor";
          path = "/var/lib/tandoor-recipes/db.sqlite3";
          sqlite_command = lib.getExe pkgs.sqlite;
        }
      ];
    };
  };
}
