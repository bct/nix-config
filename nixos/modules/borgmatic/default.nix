{ lib, config, ... }:

let
  cfg = config.diffeq.borgmatic;

  ntfyTopic = "doog4maechoh";
  borgPubKey = builtins.readFile (config.diffeq.secretsPath + /ssh/host-borg.pub);
in
{
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
          states = [ "fail" ] ++ lib.lists.optional cfg.ntfyOnSuccess "finish";
        };
      }
      // cfg.settings;
    };
  };
}
