{ config, pkgs, ... }:

let cfgPersonal = config.personal;
in {
  # Get AppImages (cura) working.
  # "For the sandboxed apps to work correctly, desktop integration portals need to be installed."
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "gtk";

  users.users.${cfgPersonal.user}.packages = with pkgs; [
    cura5
    freecad
    openscad
  ];
}
