{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  relayhost = "[smtppro.zoho.com]:587";
in
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule

    "${self}/nixos/modules/lego-proxy-client"
  ];

  services.lego-proxy-client = {
    enable = true;
    domains = [ "mail" ];
  };

  # /var/vmail needs to be group-readable, otherwise users (and dovecot) can't access it.
  # the systemd service does this when it starts, but sometimes when we deploy the permissions change.
  # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/blob/1ccd57f177539ed8c207b893c3f9798d88f87d2e/mail-server/systemd.nix#L90
  users.users.virtualMail = lib.mkForce { homeMode = "02770"; };

  mailserver = {
    enable = true;
    stateVersion = 3;

    #debug.dovecot = true;

    fqdn = "mail.domus.diffeq.com";
    domains = [
      "diffeq.com"
      "domus.diffeq.com"
    ];

    indexDir = "/var/lib/dovecot/indices";

    storage = {
      # /var/vmail/example.com/user/folder/subfolder/
      directoryLayout = "fs";
    };

    x509 = {
      useACMEHost = "mail.domus.diffeq.com";
    };

    # testing to see whether this fixes issues with resolving .domus.diffeq.com addresses.
    localDnsResolver = false;

    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    accounts = {
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
        special_use = "\\Drafts";
      };
      Junk = {
        auto = "subscribe";
        special_use = "\\Junk";
      };
      Sent = {
        auto = "subscribe";
        special_use = "\\Sent";
      };
      Trash = {
        auto = "no";
        special_use = "\\Trash";
      };
      archive = {
        auto = "create";
        special_use = "\\Archive";
      };
    };

    dkim = {
      enable = true;
      domains."diffeq.com".selectors = {
        "domus-rsa-2026-05" = {
          keyType = "rsa";
          keyLength = 2048;
        };
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
    # mail account passwords
    bct-hashed-password.rekeyFile = ./secrets/mail-bct-hashed-password.age;
    paperless-hashed-password.rekeyFile = ./secrets/mail-paperless-hashed-password.age;
    immich-hashed-password.rekeyFile = ./secrets/mail-immich-hashed-password.age;
    lubelogger-hashed-password.rekeyFile = ./secrets/mail-lubelogger-hashed-password.age;

    # relay host password
    sasl-passwd.rekeyFile = ./secrets/mail-sasl-passwd.age;
  };
}
