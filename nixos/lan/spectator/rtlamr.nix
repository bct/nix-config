{ config, pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    rtl-sdr
    rtlamr
    rtlamr-collect
  ];

  hardware.rtl-sdr.enable = true;

  users.groups.rtlamr = {};

  users.users = {
    rtlamr = {
      isSystemUser = true;
      group = "rtlamr";
      extraGroups = ["plugdev"];
    };
  };

  systemd.services.rtl_tcp = {
    description = "rtl_tcp";
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      StandardOutput = "journal";
      ExecStart = "${pkgs.rtl-sdr}/bin/rtl_tcp";
      User = "rtlamr";
      Group = "plugdev";
    };
  };

  systemd.services.rtlamr-collect = {
    description = "RTLAMR Collector";
    environment = {
      RTLAMR_FORMAT = "json";
      RTLAMR_MSGTYPE = "scm";
      RTLAMR_SERVER = "localhost:1234";
      RTLAMR_FILTERID= "40010397,41946625";

      # COLLECT_LOGLEVEL = "Debug";
      COLLECT_INFLUXDB_HOSTNAME = "http://db.domus.diffeq.com:8086/";
      COLLECT_INFLUXDB_ORG = "arbitrary";
      COLLECT_INFLUXDB_BUCKET = "rtlamr";
      COLLECT_INFLUXDB_MEASUREMENT = "utilities";
    };

    wantedBy = ["multi-user.target"];
    bindsTo = ["rtl_tcp.service"];
    after = ["rtl_tcp.service"];

    serviceConfig = {
      WorkingDirectory = "/run/rtlamr-collect";
      RuntimeDirectory = "rtlamr-collect";
      EnvironmentFile = config.age.secrets.rtlamr-collect-env.path;
      ExecStart = ''/bin/sh -c "${pkgs.rtlamr}/bin/rtlamr | ${pkgs.rtlamr-collect}/bin/rtlamr-collect"'';
      Restart = "always";
      RestartSec = "30";
      User = "rtlamr";
    };
  };

  age.secrets = {
    rtlamr-collect-env = {
      file = ../../../secrets/rtlamr-collect-env.age;
      owner = "rtlamr";
      group = "rtlamr";
      mode = "600";
    };
  };
}
