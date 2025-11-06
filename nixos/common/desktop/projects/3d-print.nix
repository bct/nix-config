{ config, pkgs, ... }:

let cfgPersonal = config.personal;
in {
  users.users.${cfgPersonal.user}.packages = with pkgs; [
    pkgs.unstable.cura-appimage
    freecad
    openscad
  ];
}
