{ lib, pkgs, config, ... }: {
  services.fwupd.enable = true;

  services.udev.extraRules = ''
    # Ethernet expansion card support
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
  '';

  hardware.sensor.iio.enable = lib.mkDefault true;

  environment.systemPackages = [ pkgs.framework-tool ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    framework-laptop-kmod
  ];

  # https://github.com/DHowett/framework-laptop-kmod?tab=readme-ov-file#usage
  boot.kernelModules = [
    "cros_ec"
    "cros_ec_lpcs"
  ];

  # https://community.frame.work/t/externally-visible-sleep-indicator/5615/30
  systemd.services."suspend-led-set" = {
    description = "blue led for sleep";
    wantedBy = [ "suspend.target" ];
    before = [ "systemd-suspend.service" ];
    serviceConfig.Type = "simple";
    script = ''
      ${pkgs.fw-ectool}/bin/ectool led battery blue
    '';
  };

  systemd.services."suspend-led-unset" = {
    description = "auto led after sleep";
    wantedBy = [ "suspend.target" ];
    after = [ "systemd-suspend.service" ];
    serviceConfig.Type = "simple";
    script = ''
      ${pkgs.fw-ectool}/bin/ectool led battery auto
    '';
  };

  # suspend works with 6.15
  boot.kernelPackages = lib.mkIf (lib.versionOlder pkgs.linux.version "6.15") (
    lib.mkDefault pkgs.linuxPackages_latest
  );
}
