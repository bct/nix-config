{ self, config, ... }:

{
  imports = [ "${self}/nixos/modules/borgmatic" ];

  age.secrets = {
    ssh-borg-aquilonia = {
      rekeyFile = ../../secrets/ssh/borg-aquilonia.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };

  diffeq.borgmatic = {
    enable = true;
    backupName = "aquilonia";
    sshKeyPath = config.age.secrets.ssh-borg-aquilonia.path;
    ntfyOnSuccess = true;

    settings = {
      source_directories = [
        "/home"
      ];

      exclude_patterns = [
        "/home/*/.cache"
        "/home/bct/videos"
      ];

      # retention
      keep_daily = 14;
      keep_weekly = 8;
      keep_monthly = 12;
      keep_yearly = 1;
    };
  };

  systemd.services.borgmatic.unitConfig.ConditionACPower = "";
}
