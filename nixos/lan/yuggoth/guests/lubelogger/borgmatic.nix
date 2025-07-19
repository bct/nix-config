{ config, pkgs, ... }:

let
  borg-pubkey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtsDN0WY1wDki3JNSmGqOmxMR34IrZue4h3Xd+wdYfDOHhHTlk1taNWFGJusSc7hSC7ittGoOmeP6AepCIAhKNce0d9ITA9xAIN40qnFFkW1lUTL6/eE3+CM2VBqYreLy0YiID8K/OfoqppPzHpMB4ijQiSRrtBtGYx5OGtMAQkSSu50XH3s4tzHR0qXnjAi3Ly7pJ47d62MFR4JvpI5LQuIe3zvwW4W1GEYlZHOXDX7bb1cEyEhPeoEJ2AOHCdbtZ7osZyjQtARypWfuTgngpLYVcLErjj9UazUikJn7sBhYgwkaFcjfFn2optnU+3TpjIl4ot59vrwzOKOF634YTUD7iNWOTpdduHUWfK3eAARM4YnAOL3PMhEp/656kQqMPGeM60aSgGWKeBZWycp1VMGtQhZ4BCpFSErYKEi1CKey1xfHMaH5PVFZTJLToUEMzHlLYSbV8AYO25vNppUEfJAk215Al6gHR7o5l0NRlqLL18uo7zFlj75P7nIBsLSk=";

  var-backup = "/var/backups";
  backup-lubelogger-zip-path = "${var-backup}/lubelogger-backup.zip";
  # https://github.com/hargata/lubelog_scripts/blob/main/bash/makebackup.sh
  backup-lubelogger = pkgs.writeShellApplication {
    name = "backup-lubelogger";
    runtimeInputs = [pkgs.curl];
    text = ''
      base_url="http://localhost:${toString config.services.lubelogger.port}"
      makebackup_output=$(curl -sL "$base_url/api/makebackup" | tr -d "\"")

      curl -sL "$base_url$makebackup_output" -o ${backup-lubelogger-zip-path}
    '';
  };
in {
  programs.ssh.knownHosts = {
    "borg.domus.diffeq.com".publicKey = borg-pubkey;
  };

  systemd.tmpfiles.rules = [
    # ensure that /var/backups exists, and is only accessible by root.
    # "-" means no automatic cleanup.
    "d ${var-backup} 0700 root root -"
  ];

  services.borgmatic = {
    enable = true;
    settings = {
      repositories = [
        {
          label = "borg.domus.diffeq.com";
          path = "ssh://borg@borg.domus.diffeq.com/srv/borg/lubelogger.domus.diffeq.com/";
        }
      ];

      source_directories = [
        var-backup
      ];

      # state directories must be on a persistent volume.
      borg_base_directory = "/var/lib/borg";
      borgmatic_source_directory = "/var/lib/borgmatic";

      ssh_command = "ssh -i ${config.age.secrets.ssh-borg-lubelogger.path}";

      # retention
      keep_daily = 7;
      keep_weekly = 4;
      keep_monthly = 6;
      keep_yearly = 1;

      before_backup = [
        "${backup-lubelogger}/bin/backup-lubelogger"
      ];

      after_backup = [
        "rm -f ${backup-lubelogger-zip-path}"
      ];

      ntfy = {
        topic = "doog4maechoh";
        fail = {
          title = "[lubelogger] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
        };
        states = ["fail"];
      };
    };
  };

  age.secrets = {
    ssh-borg-lubelogger = {
      rekeyFile = ../../../../../secrets/ssh/borg-lubelogger.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };
}
