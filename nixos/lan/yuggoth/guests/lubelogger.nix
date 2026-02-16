{
  self,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"

    ./lubelogger/borgmatic.nix
  ];

  system.stateVersion = "24.11";

  microvm = {
    vcpu = 1;
    mem = 512;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [ "lubelogger" ];
    group = "caddy";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  age.secrets = {
    lubelogger-env = {
      rekeyFile = ./secrets/lubelogger-env.age;
      owner = config.services.lubelogger.user;
    };
  };

  services.lubelogger = {
    enable = true;
    package = pkgs.unstable.lubelogger;
    environmentFile = config.age.secrets.lubelogger-env.path;
    settings = {
      MailConfig__EmailServer = "mail.domus.diffeq.com";
      MailConfig__EmailFrom = "lubelogger@domus.diffeq.com";
      MailConfig__Port = "587";
      MailConfig__Username = "lubelogger@domus.diffeq.com";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."lubelogger.domus.diffeq.com" = {
      useACMEHost = "lubelogger.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.lubelogger.port}";
    };
  };

  systemd.timers.lubelogger-reminders = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "10m";
      Unit = "lubelogger-reminders.service";
    };
  };

  systemd.services.lubelogger-reminders =
    let
      reminderUrl = "https://lubelogger.domus.diffeq.com/api/vehicle/reminders/send?urgencies=NotUrgent&urgencies=VeryUrgent&urgencies=Urgent&urgencies=PastDue";
    in
    {
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lib.getExe pkgs.curl} ${reminderUrl}";
      };
    };
}
