{ pkgs, ... }:
{
  imports = [
    ../base

    ../modules/vim
    ../modules/dunst
    ../modules/rofi
    ../modules/hyprland

    ./beets.nix
    ./fonts.nix
    ./nix.nix
    ./shell.nix
    ./3d-print.nix

    ./screen-break-reminder.nix
  ];

  home.packages = with pkgs; [
    # terminal
    alacritty

    # tui utilities
    htop
    silver-searcher
    ruby
    pwgen
    tmux

    # gui utilities
    rofi-bluetooth
    rofi-network-manager

    # image viewer
    imv

    # media
    unstable.supersonic

    # chat
    webcord
  ];

  # Raw configuration files
  home.file.".alacritty.toml".source = ./files/alacritty.toml;

  home.file.".ssh/config".text = ''
    # 2022-08-06 many hosts (e.g. mi-go) don't have alacritty terminfo
    Host *
      SetEnv TERM=xterm-256color
  '';

  home.file."bin/mount-host".source = ./files/bin/mount-host;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
