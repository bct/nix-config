{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    capitaine-cursors
  ];

  home.pointerCursor = {
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 18;
    gtk.enable = true;
    x11.enable = true;
  };

  # use lxappearance to view/check themes
  gtk = {
    enable = true;
    colorScheme = "dark";
    font = {
      name = "Ubuntu";
      size = 8;
    };
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
    iconTheme = {
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    gtk4.theme = config.gtk.theme;
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;

      wallpaper = [
        {
          monitor = "";
          path = "/home/bct/images/wallpaper/View_of_Vent_in_the_Ventertal.jpg";
        }
      ];
    };
  };
}
