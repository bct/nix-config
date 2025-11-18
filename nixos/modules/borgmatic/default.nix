{ lib, config, ... }:

let
  cfg = config.diffeq.borgmatic;

  ntfyTopic = "doog4maechoh";
  borgPubKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtsDN0WY1wDki3JNSmGqOmxMR34IrZue4h3Xd+wdYfDOHhHTlk1taNWFGJusSc7hSC7ittGoOmeP6AepCIAhKNce0d9ITA9xAIN40qnFFkW1lUTL6/eE3+CM2VBqYreLy0YiID8K/OfoqppPzHpMB4ijQiSRrtBtGYx5OGtMAQkSSu50XH3s4tzHR0qXnjAi3Ly7pJ47d62MFR4JvpI5LQuIe3zvwW4W1GEYlZHOXDX7bb1cEyEhPeoEJ2AOHCdbtZ7osZyjQtARypWfuTgngpLYVcLErjj9UazUikJn7sBhYgwkaFcjfFn2optnU+3TpjIl4ot59vrwzOKOF634YTUD7iNWOTpdduHUWfK3eAARM4YnAOL3PMhEp/656kQqMPGeM60aSgGWKeBZWycp1VMGtQhZ4BCpFSErYKEi1CKey1xfHMaH5PVFZTJLToUEMzHlLYSbV8AYO25vNppUEfJAk215Al6gHR7o5l0NRlqLL18uo7zFlj75P7nIBsLSk=";
in {
  options.diffeq.borgmatic = {
    enable = lib.mkEnableOption "borgmatic";

    backupName = lib.mkOption {
      type = lib.types.str;
      description = lib.mdDoc "Name of the backup.";
    };

    sshKeyPath = lib.mkOption {
      type = lib.types.path;
      description = lib.mdDoc "Path to an SSH key.";
    };

    ntfyOnSuccess = lib.mkOption {
      type = lib.types.bool;
      description = lib.mdDoc "Ping ntfy when backup succeeds?";
      default = false;
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      description = lib.mdDoc "Additional settings.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh.knownHosts = {
      "borg.domus.diffeq.com".publicKey = borgPubKey;
    };

    services.borgmatic = {
      enable = true;
      settings = {
        repositories = [
          {
            label = "borg.domus.diffeq.com";
            path = "ssh://borg@borg.domus.diffeq.com/srv/borg/${cfg.backupName}/";
          }
        ];

        ssh_command = "ssh -i ${cfg.sshKeyPath}";

        # retention
        keep_daily = 14;
        keep_weekly = 6;
        keep_monthly = 6;
        keep_yearly = 1;

        ntfy = {
          topic = ntfyTopic;

          finish = {
            title = "[${cfg.backupName}] borgmatic finished";
            message = "Your backup has finished.";
            priority = "default";
            tags = "kissing_heart,borgmatic";
          };

          fail = {
            title = "[${cfg.backupName}] borgmatic failed";
            message = "Your backup has failed.";
            priority = "default";
            tags = "sweat,borgmatic";
          };

          # List of monitoring states to ping for. Defaults to pinging for failure only.
          states = ["fail"] ++ lib.lists.optional cfg.ntfyOnSuccess "finish";
        };
      } // cfg.settings;
    };
  };
}
