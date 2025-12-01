{ self, inputs, config, pkgs, ... }:
let
  relayhost = "[smtppro.zoho.com]:587";
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule

    "${self}/nixos/modules/lego-proxy-client"

    ./mail/borgmatic.nix
  ];

  system.stateVersion = "24.05";
  mailserver.stateVersion = 3;

  microvm = {
    vcpu = 1;
    mem = 1536;

    volumes = [
      {
        image = "/dev/mapper/fastpool-mail--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "mail" ];
  };

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

  mailserver = {
    enable = true;
    fqdn = "mail.domus.diffeq.com";
    domains = [
      "diffeq.com"
      "domus.diffeq.com"
    ];

    indexDir = "/var/lib/dovecot/indices";
    useFsLayout = true;

    certificateScheme = "acme";

    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "bct@diffeq.com" = {
        aliases = [ "@diffeq.com" ];
        hashedPasswordFile = config.age.secrets.bct-hashed-password.path;
      };

      "paperless@domus.diffeq.com" = {
        hashedPasswordFile = config.age.secrets.paperless-hashed-password.path;
      };

      "immich@domus.diffeq.com" = {
        hashedPasswordFile = config.age.secrets.immich-hashed-password.path;
      };

      "lubelogger@domus.diffeq.com" = {
        hashedPasswordFile = config.age.secrets.lubelogger-hashed-password.path;
      };
    };

    mailboxes = {
      Drafts = {
        auto = "subscribe";
        specialUse = "Drafts";
      };
      Junk = {
        auto = "subscribe";
        specialUse = "Junk";
      };
      Sent = {
        auto = "subscribe";
        specialUse = "Sent";
      };
      Trash = {
        auto = "no";
        specialUse = "Trash";
      };
      archive = {
        auto = "create";
        specialUse = "Archive";
      };
    };
  };

  services.postfix = {
    mapFiles."sasl_passwd" = config.age.secrets.sasl-passwd.path;

    settings.main = {
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "hash:/etc/postfix/sasl_passwd";
      smtp_sasl_security_options = "noanonymous";
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_sasl_mechanism_filter = "AUTH LOGIN";
      relayhost = [ relayhost ];
    };
  };

  age.secrets = {
    bct-hashed-password.rekeyFile = ./secrets/mail-bct-hashed-password.age;
    paperless-hashed-password.rekeyFile = ./secrets/mail-paperless-hashed-password.age;
    immich-hashed-password.rekeyFile = ./secrets/mail-immich-hashed-password.age;
    lubelogger-hashed-password.rekeyFile = ./secrets/mail-lubelogger-hashed-password.age;

    sasl-passwd.rekeyFile = ./secrets/mail-sasl-passwd.age;
  };

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
