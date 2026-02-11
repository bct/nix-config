{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hyprland.nix
    ./hyprlock.nix
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
  };

  services.cliphist.enable = true;

  home.packages = with pkgs; [
    brightnessctl

    swww
    capitaine-cursors

    grim

    alacritty
    light

    playerctl
  ];

  home.pointerCursor = {
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 18;
    gtk.enable = true;
    x11.enable = true;
  };

  # Optional, hint Electron apps to use Wayland:
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  xdg.configFile."grid-select/config.toml".text = ''
    item_width = 80
    item_height = 40
    item_margin = 5

    font_size = 15
    font_name = "UbuntuMono Nerd Font"
  '';

  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/bct/images/wallpaper/View_of_Vent_in_the_Ventertal.jpg"
      ];

      wallpaper = [
        ",/home/bct/images/wallpaper/View_of_Vent_in_the_Ventertal.jpg"
      ];
    };
  };

  gtk = {
    enable = true;
    font = {
      name = "Ubuntu";
      size = 8;
    };
  };
}
