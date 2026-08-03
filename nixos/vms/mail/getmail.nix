{ pkgs, config, ... }:

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
{
  environment.systemPackages = [
    pkgs.getmail6
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

  age.secrets = {
    passwd-bct-zoho = {
      rekeyFile = ./secrets/passwd-bct-zoho.age;
      owner = "bct";
      group = "bct";
    };
    passwd-spam-zoho = {
      rekeyFile = ./secrets/passwd-spam-zoho.age;
      owner = "bct";
      group = "bct";
    };
  };

  home-manager.users.bct = {
    home.file.".getmail/zoho-bct".text = ''
      [retriever]
      type = SimpleIMAPSSLRetriever
      server = imappro.zoho.com
      username = bct@diffeq.com
      password_command = ("cat", "${config.age.secrets.passwd-bct-zoho.path}",)
      mailboxes = ALL

      [destination]
      type = MDA_external
      path = ${rspamc-deliver}/bin/rspamc-deliver

      [options]
      received = false
      # if set, getmail retrieves all available messages.
      # if unset, getmail only retrieves messages it has not seen before.
      read_all = false
      # 0 prints only warnings and errors
      # 1 prints messages about retrieving and deleting messages only (default)
      # 2 prints messages about each action
      #
      # We can leave this verbose because we'll pass --quiet in the cronjob
      verbose = 2
      message_log = ~/.getmail/logs/zoho-bct.log
      # delete messages 14 days after we saw them
      delete_after = 14
    '';

    home.file.".getmail/zoho-catchall".text = ''
      [retriever]
      type = SimpleIMAPSSLRetriever
      server = imappro.zoho.com
      username = spam@diffeq.com
      password_command = ("cat", "${config.age.secrets.passwd-spam-zoho.path}",)
      mailboxes = ALL

      [destination]
      type = MDA_external
      path = ${rspamc-deliver}/bin/rspamc-deliver

      [options]
      received = false
      # if set, getmail retrieves all available messages.
      # if unset, getmail only retrieves messages it has not seen before.
      read_all = false
      # 0 prints only warnings and errors
      # 1 prints messages about retrieving and deleting messages only (default)
      # 2 prints messages about each action
      #
      # We can leave this verbose because we'll pass --quiet in the cronjob
      verbose = 2
      message_log = ~/.getmail/logs/zoho-catchall.log
      # delete messages 14 days after we saw them
      delete_after = 14
    '';
  };
}
