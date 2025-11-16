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

  # suspend works with 6.15
  boot.kernelPackages = lib.mkIf (lib.versionOlder pkgs.linux.version "6.15") (
    lib.mkDefault pkgs.linuxPackages_latest
  );
}
