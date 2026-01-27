{ pkgs, ... }:
{
  imports = [
    ../base

    ../modules/vim
    ../modules/notifications
    ../modules/launcher
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
    bzmenu
    rofi-network-manager

    # image viewer
    imv

    # media
    (unstable.supersonic.override { waylandSupport = true; })
    # wayland is not working yet:
    # https://github.com/dweymouth/supersonic/issues/560
    (unstable.supersonic.overrideAttrs (old: {
      # work around https://github.com/dweymouth/supersonic/issues/316
      nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];
      postInstall = old.postInstall + ''
        wrapProgram $out/bin/supersonic \
          --prefix PATH : ${pkgs.libnotify}/bin
      '';
    }))

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
