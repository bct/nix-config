{ config, pkgs, ... }:

# TODO: move this to home-manager
let
  cfgPersonal = config.personal;
in
{
  users.users.${cfgPersonal.user} = {
    isNormalUser = true;
    extraGroups = [ "adbusers" ];

    packages = with pkgs; [
      androidStudioPackages.canary
      gcc # Android Studio needs cc.

      android-tools
    ];
  };
}
