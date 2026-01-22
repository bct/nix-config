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
    };
  };
}
