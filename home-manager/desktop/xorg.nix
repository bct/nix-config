{ config, pkgs, ... }:
{
  imports = [
    ../modules/dunst
    ../modules/rofi
    ../modules/hyprland

    ./screen-break-reminder.nix
  ];

  fonts.fontconfig.enable = true;

  # Get AppImages (cura) working.
  # "For the sandboxed apps to work correctly, desktop integration portals need to be installed."
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      config.wayland.windowManager.hyprland.portalPackage
    ];
  };
}
