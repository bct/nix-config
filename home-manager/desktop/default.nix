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
    sqlite-interactive

    # gui utilities
    bzmenu
    rofi-network-manager

    # image viewer
    imv

    # media
    # https://github.com/dweymouth/supersonic/pull/898
    ((unstable.supersonic.override { waylandSupport = true; }).overrideAttrs (old: {
      version = "pr-898";
      src = fetchFromGitHub {
        owner = "ocelotsloth";
        repo = "supersonic";
        rev = "a2d3850b899a565861c46178cf3b24a5d2a4c965";
        hash = "sha256-umOGwd9HlviYMlE9i5v0tc9wnluKJnJWkeYatj86OXA=";
      };

      vendorHash = "sha256-Qg5OWg+iFcGuD8E3/7YwmmciiRGdUFNSHLrEAaqRmnQ=";

      # work around https://github.com/dweymouth/supersonic/issues/316
      nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];
      postInstall = old.postInstall + ''
        wrapProgram $out/bin/supersonic-wayland \
          --prefix PATH : ${pkgs.libnotify}/bin
      '';
    }))
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

    Host router.domus.diffeq.com router
      User root

    Host theatre.domus.diffeq.com theatre
      User root

    Host fever-dreams.domus.diffeq.com fever-dreams
      User bazzite

    # temporary - i can't connect directly to yuggoth for some reason.
    #Host yuggoth.domus.diffeq.com yuggoth
    #  ProxyJump root@router.domus.diffeq.com
  '';

  home.file."bin/mount-host".source = ./files/bin/mount-host;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
