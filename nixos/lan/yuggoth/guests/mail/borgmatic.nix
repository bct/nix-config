{ self, config, ... }: {
  imports = [ "${self}/nixos/modules/borgmatic" ];

  diffeq.borgmatic = {
    enable = true;
    backupName = "mail.domus.diffeq.com";
    sshKeyPath = config.age.secrets.ssh-borg-mail.path;

    settings = {
      source_directories = [
        "/var/home/"
        "/var/vmail/"
      ];

      # state directories must be on a persistent volume.
      borg_base_directory = "/var/lib/borg";
      borgmatic_source_directory = "/var/lib/borgmatic";

      # retention
      keep_hourly = 24;
      keep_daily = 14;
      keep_weekly = 6;
      keep_monthly = 6;
      keep_yearly = 1;
    };
  };

  systemd.timers.borgmatic.timerConfig = {
    OnCalendar = "hourly";
    RandomizedDelaySec = "10m";
  };

  age.secrets = {
    ssh-borg-mail = {
      rekeyFile = config.diffeq.secretsPath + /ssh/borg-mail.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };
}
