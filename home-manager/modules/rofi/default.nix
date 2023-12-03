# This is originally based on this config:
# https://github.com/considerate/home/blob/aca9a752e749fcfd5bab4f2bf694947ade814c0a/rofi/default.nix
{ pkgs, ... }:
let
  rofi-launcher = pkgs.writeShellApplication {
    name = "rofi-launcher";
    runtimeInputs = [ ];
    text = builtins.readFile ./bin/launcher;
  };
  rofi-runner = pkgs.writeShellApplication {
    name = "rofi-runner";
    runtimeInputs = [ ];
    text = builtins.readFile ./bin/runner;
  };
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
    rofi-launcher
    rofi-runner
    rofi-screenshot
  ];

  programs = {
    rofi = {
      package = pkgs.rofi.override {
        plugins = [ pkgs.rofi-calc ];
      };

      enable = true;
      font = "UbuntuMono Nerd Font 18";
      extraConfig = {
        display-combi = "Go";
        modi = "combi,calc";
        combi-modi = "window,run,ssh";
      };

      terminal = "${pkgs.alacritty}/bin/alacritty";
    };
  };
}
