{ self, inputs, config, pkgs, ... }: {
  imports = [
    inputs.simple-nixos-mailserver.nixosModule

    "${self}/nixos/common/agenix-rekey.nix"

    # ./mail/borgmatic.nix
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "/dev/mapper/fastpool-mail--var";
        mountPoint = "/var";
        autoCreate = false;
      }
    ];
  };

  users.users.bct = {
    # put home directory in /var so that we can have a single writeable volume.
    home = "/var/home/bct";

    # give me access to the mailboxes
    extraGroups = [config.mailserver.vmailGroupName];
  };

  environment.systemPackages = [
    pkgs.neomutt
    pkgs.notmuch
    pkgs.getmail6
    pkgs.afew
    pkgs.msmtp
    pkgs.procmail
  ];

  mailserver = {
    enable = true;
    fqdn = "mail-new.domus.diffeq.com";
    domains = ["diffeq.com"];

    indexDir = "/var/lib/dovecot/indices";
    useFsLayout = true;

    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "bct@diffeq.com" = {
        aliases = ["@diffeq.com"];
        hashedPasswordFile = config.age.secrets.bct-hashed-password.path;
      };
    };
  };

  age.secrets = {
    bct-hashed-password.rekeyFile = ./secrets/mail-bct-hashed-password.age;
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
      ExecStart = "${pkgs.getmail6}/bin/getmail --quiet --rcfile zoho-catchall";
    };
  };
}
