{ outputs, pkgs, ... }:
{
  imports = [
    ../base

    ../modules/vim
    ../modules/dunst
    ../modules/rofi
    ../modules/hyprland

    ./shell.nix
    ./3d-print.nix

    ./screen-break-reminder.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    package = pkgs.nix;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
    };
  };

  # allow using unfree packages with nix-shell, `nix run`, etc.
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';

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
