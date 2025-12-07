{
  self,
  config,
  pkgs,
  ...
}:
{
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  environment.systemPackages = with pkgs; [
    rtl-sdr
    rtlamr
    rtlamr-collect
  ];

  hardware.rtl-sdr.enable = true;

  users.groups.rtlamr = { };

  users.users = {
    rtlamr = {
      isSystemUser = true;
      group = "rtlamr";
      extraGroups = [ "plugdev" ];
    };
  };

  # "systemd will dynamically create device units for all kernel devices that
  # are marked with the "systemd" udev tag"
  #
  # we could add SYMLINK+=rtl2838 here so that the systemd config below could
  # use a saner device unit name.
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="2838", TAG+="systemd"
  '';

  systemd.services.rtl_tcp = {
    description = "rtl_tcp";
    wantedBy = [ "multi-user.target" ];

    # wait until USB has been fully initialized - otherwise the dongle isn't
    # available in time.
    #
    # device unit name identified with:
    #
    #     sudo systemctl --all --full -t device
    # requires = ["sys-devices-platform-soc-3f980000.usb-usb1-1\\x2d1-1\\x2d1.3-1\\x2d1.3:1.0.device"];
    # after = ["sys-devices-platform-soc-3f980000.usb-usb1-1\\x2d1-1\\x2d1.3-1\\x2d1.3:1.0.device"];

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
      RTLAMR_FILTERID = "40010397,41946625";

      # COLLECT_LOGLEVEL = "Debug";
      COLLECT_INFLUXDB_HOSTNAME = "http://influx.domus.diffeq.com:8086/";
      COLLECT_INFLUXDB_ORG = "arbitrary";
      COLLECT_INFLUXDB_BUCKET = "rtlamr";
      COLLECT_INFLUXDB_MEASUREMENT = "utilities";
    };

    wantedBy = [ "multi-user.target" ];
    bindsTo = [ "rtl_tcp.service" ];
    after = [ "rtl_tcp.service" ];
    partOf = [ "rtl_tcp.service" ];

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
      rekeyFile = config.diffeq.secretsPath + /rtlamr-collect-env.age;
      owner = "rtlamr";
      group = "rtlamr";
    };
  };
}
