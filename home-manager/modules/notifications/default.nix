{ pkgs, ... }:
{
  home.packages = [
    pkgs.dunst # dunstify
  ];

  services.mako = {
    enable = true;

    # https://github.com/emersion/mako/blob/master/doc/mako.5.scd
    settings = {
      anchor = "bottom-right";
      default-timeout = 7500;
      outer-margin = "10,0";

      # gruvbox
      background-color = "#3c3836cc";
      text-color = "#ebdbb2";
      border-color = "#83a598cc";
      border-radius = 6;
      border-size = 2;
      layer = "overlay";
    };
  };
}
