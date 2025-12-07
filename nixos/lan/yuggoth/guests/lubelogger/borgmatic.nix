{
  self,
  config,
  pkgs,
  ...
}:

let
  var-backup = "/var/backups";
  backup-lubelogger-zip-path = "${var-backup}/lubelogger-backup.zip";

  # https://github.com/hargata/lubelog_scripts/blob/main/bash/makebackup.sh
  backup-lubelogger = pkgs.writeShellApplication {
    name = "backup-lubelogger";
    runtimeInputs = [ pkgs.curl ];
    text = ''
      base_url="http://localhost:${toString config.services.lubelogger.port}"
      makebackup_output=$(curl -sL "$base_url/api/makebackup" | tr -d "\"")

      curl -sL "$base_url$makebackup_output" -o ${backup-lubelogger-zip-path}
    '';
  };
in
{
  imports = [ "${self}/nixos/modules/borgmatic" ];

  systemd.tmpfiles.rules = [
    # ensure that /var/backups exists, and is only accessible by root.
    # "-" means no automatic cleanup.
    "d ${var-backup} 0700 root root -"
  ];

  age.secrets = {
    ssh-borg-lubelogger = {
      rekeyFile = config.diffeq.secretsPath + /ssh/borg-lubelogger.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };

  diffeq.borgmatic = {
    enable = true;
    backupName = "lubelogger.domus.diffeq.com";
    sshKeyPath = config.age.secrets.ssh-borg-lubelogger.path;

    settings = {
      source_directories = [
        var-backup
      ];

      # state directories must be on a persistent volume.
      borg_base_directory = "/var/lib/borg";
      borgmatic_source_directory = "/var/lib/borgmatic";

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
    };
  };
}
