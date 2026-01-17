# This is originally based on this config:
# https://github.com/considerate/home/blob/aca9a752e749fcfd5bab4f2bf694947ade814c0a/rofi/default.nix
{ pkgs, ... }:
let
  rofi-screenshot = pkgs.writeShellApplication {
    name = "rofi-screenshot";
    runtimeInputs = [
      pkgs.maim
      pkgs.xdotool
    ];
    text = builtins.readFile ./bin/screenshot;
  };
in
{
  home.packages = [
    rofi-screenshot
  ];

  programs = {
    rofi = {
      plugins = [ pkgs.rofi-calc ];

      enable = true;
      font = "UbuntuMono Nerd Font 18";
      extraConfig = {
        display-combi = "Go";
        modi = "combi,calc";
        combi-modi = "window,run,ssh";
      };

      terminal = "${pkgs.alacritty}/bin/alacritty";
      theme = "gruvbox-light";
    };
  };

  programs = {
    fuzzel = {
      enable = true;
      settings = {
        main = {
          terminal = "alacritty";
        };

        colors = {
          background = "3c3836e6";
          text = "ebdbb2ff";
          match = "8ec07cff";
          selection = "bdae93bf";
          selection-match = "8ec07cff";
          selection-text = "fabd2fff";
        };

        border = {
          width = 0;
          radius = 5;
        };
      };
    };
  };

  xdg.desktopEntries = {
    bzmenu = {
      name = "bzmenu";
      genericName = "Bluetooth Control";
      exec = "bzmenu -l fuzzel";
      terminal = false;
    };

    rofi-calc = {
      name = "rofi calculator";
      genericName = "Calculator";
      exec = "rofi -show calc";
      terminal = false;
    };

    rofi-network-manager = {
      name = "rofi-network-manager";
      genericName = "Network Control";
      exec = "rofi-network-manager";
      terminal = false;
    };
  };
}
