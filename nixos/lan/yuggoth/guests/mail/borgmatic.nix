{ config, ... }: {
  programs.ssh.knownHosts = {
    "borg.domus.diffeq.com".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCtsDN0WY1wDki3JNSmGqOmxMR34IrZue4h3Xd+wdYfDOHhHTlk1taNWFGJusSc7hSC7ittGoOmeP6AepCIAhKNce0d9ITA9xAIN40qnFFkW1lUTL6/eE3+CM2VBqYreLy0YiID8K/OfoqppPzHpMB4ijQiSRrtBtGYx5OGtMAQkSSu50XH3s4tzHR0qXnjAi3Ly7pJ47d62MFR4JvpI5LQuIe3zvwW4W1GEYlZHOXDX7bb1cEyEhPeoEJ2AOHCdbtZ7osZyjQtARypWfuTgngpLYVcLErjj9UazUikJn7sBhYgwkaFcjfFn2optnU+3TpjIl4ot59vrwzOKOF634YTUD7iNWOTpdduHUWfK3eAARM4YnAOL3PMhEp/656kQqMPGeM60aSgGWKeBZWycp1VMGtQhZ4BCpFSErYKEi1CKey1xfHMaH5PVFZTJLToUEMzHlLYSbV8AYO25vNppUEfJAk215Al6gHR7o5l0NRlqLL18uo7zFlj75P7nIBsLSk=";
  };

  services.borgmatic = {
    enable = true;
    settings = {
      repositories = [
        {
          label = "borg.domus.diffeq.com";
          path = "ssh://borg@borg.domus.diffeq.com/srv/borg/mail.domus.diffeq.com/";
        }
      ];

      source_directories = [
        "/var/home/"
        "/var/vmail/"
      ];

      # state directories must be on a persistent volume.
      borg_base_directory = "/var/lib/borg";
      borgmatic_source_directory = "/var/lib/borgmatic";

      ssh_command = "ssh -i ${config.age.secrets.ssh-borg-mail.path}";

      # retention
      keep_hourly = 24;
      keep_daily = 14;
      keep_weekly = 6;
      keep_monthly = 6;
      keep_yearly = 1;

      ntfy = {
        topic = "doog4maechoh";
        fail = {
          title = "[mail] borgmatic failed";
          message = "Your backup has failed.";
          priority = "default";
          tags = "sweat,borgmatic";
        };
        states = ["fail"];
      };
    };
  };

  systemd.timers.borgmatic.timerConfig = {
    OnCalendar = "hourly";
    RandomizedDelaySec = "10m";
  };

  age.secrets = {
    ssh-borg-mail = {
      rekeyFile = ../../../../../secrets/ssh/borg-mail.age;
      generator.script = "ssh-ed25519-pubkey";
    };
  };
}
