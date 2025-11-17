{ config, ... }:

let
  backupName = "aquilonia";
in {
  age.secrets = {
    ssh-borg-aquilonia = {
      rekeyFile = ../../secrets/ssh/borg-aquilonia.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };

  services.borgmatic = {
    enable = true;
    settings = {
      repositories = [
        {
          label = "borg.domus.diffeq.com";
          path = "ssh://borg@borg.domus.diffeq.com/srv/borg/${backupName}/";
        }
      ];

      source_directories = [
        "/home"
      ];

      exclude_patterns = [
        "/home/*/.cache"
        "/home/bct/videos"
      ];

      ssh_command = "ssh -i ${config.age.secrets.ssh-borg-aquilonia.path}";

      # retention
      keep_daily = 14;
      keep_weekly = 8;
      keep_monthly = 12;
      keep_yearly = 1;

      ntfy = {
        topic = "doog4maechoh";
        finish = {
          title = "[${backupName}] borgmatic finished";
          message = "Your backup has finished.";
          priority = "default";
          tags = "kissing_heart,borgmatic";
        };
        fail = {
          title = "[${backupName}] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
        };

        # List of monitoring states to ping for. Defaults to pinging for failure only.
        states = ["finish" "fail"];
      };
    };
  };

  systemd.services.borgmatic.unitConfig.ConditionACPower = "";
}
