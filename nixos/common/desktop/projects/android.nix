{ config, pkgs, ... }:

let cfgPersonal = config.personal;
in {
  programs.adb.enable = true;

  users.users.${cfgPersonal.user} = {
    isNormalUser = true;
    extraGroups = [ "adbusers" ];

    packages = with pkgs; [
      unstable.androidStudioPackages.canary
      gcc # Android Studio needs cc.
    ];
  };
}
