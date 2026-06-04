{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
    ./theme.nix
    ./waybar.nix
  ];

  # Get AppImages (cura) working.
  # "For the sandboxed apps to work correctly, desktop integration portals need to be installed."
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      config.wayland.windowManager.hyprland.portalPackage
    ];
    # attempt to fix screensharing on hyprland.
    config.hyprland.default = [
      "hyprland"
      "gtk"
    ];
  };

  services.cliphist.enable = true;

  home.packages = with pkgs; [
    brightnessctl # hyprland, hyprlock
    playerctl

    grim # screenshots

    alacritty
  ];

  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.configFile."grid-select/config.toml".text = ''
    item_width = 80
    item_height = 40
    item_margin = 5

    font_size = 15
    font_name = "UbuntuMono Nerd Font"
  '';

  # Fix screensharing double menu
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      allow_token_by_default = true
    }
  '';
}
