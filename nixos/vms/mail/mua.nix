{
  config,
  pkgs,
  ...
}:
{
  users.users.bct = {
    # put home directory in /var so that we can have a single writeable volume.
    home = "/var/home/bct";

    # give me access to the mailboxes
    extraGroups = [ config.mailserver.vmailGroupName ];
  };

  environment.systemPackages =
    let
      rspamc-deliver = pkgs.writeShellApplication {
        name = "rspamc-deliver";
        runtimeInputs = [
          pkgs.rspamd
          pkgs.procmail
        ];
        text = ''
          rspamc --connect /run/rspamd/worker-controller.sock --mime --exec procmail
        '';
      };
    in
    [
      pkgs.neomutt
      pkgs.notmuch
      pkgs.getmail6
      pkgs.afew
      pkgs.msmtp
      pkgs.procmail
      pkgs.lynx
      rspamc-deliver
    ];

  systemd.timers.getmail = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "getmail.service";
    };
  };

  systemd.services.getmail = {
    serviceConfig = {
      Type = "oneshot";
      User = "bct";
      Group = "virtualMail";
      ExecStart = "${pkgs.getmail6}/bin/getmail --quiet --rcfile zoho-bct --rcfile zoho-catchall";
    };
  };

  systemd.timers.notmuch-new = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "5m";
      Unit = "notmuch-new.service";
    };
  };

  systemd.services.notmuch-new = {
    serviceConfig = {
      Type = "oneshot";
      User = "bct";
      Group = "virtualMail";
      ExecStart = "${pkgs.notmuch}/bin/notmuch new --quiet";
    };
  };
}
