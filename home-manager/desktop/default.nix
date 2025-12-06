{ pkgs, ... }:
{
  imports = [
    ../base

    ../modules/vim
    ../modules/dunst
    ../modules/rofi
    ../modules/hyprland

    ./nix.nix
    ./shell.nix
    ./3d-print.nix

    ./screen-break-reminder.nix
  ];

  home.packages = with pkgs; [
    # fonts
    ubuntu-classic
    nerd-fonts.ubuntu-mono
    dejavu_fonts
    corefonts

    # maybe prefer https://github.com/Soft/nix-google-fonts-overlay ?
    (pkgs.google-fonts.override {
      # https://fonts.google.com/
      fonts = [
        "Crimson Text"
        "IM Fell DW Pica SC"
        "IM Fell English"
        "IM Fell English SC"
        "Parisienne"
        "Sacramento"
        "UnifrakturMaguntia"
      ];
    })

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
