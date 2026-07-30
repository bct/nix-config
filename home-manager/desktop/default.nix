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
    ./shell.nix
    ./3d-print.nix

    ./screen-break-reminder.nix
  ];

  nix = {
    package = pkgs.nix;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
    };
  };

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
    bind

    # gui utilities
    bzmenu
    rofi-network-manager

    # image viewer
    imv

    # media
    # https://github.com/dweymouth/supersonic/issues/560#issuecomment-4898869840
    (unstable.supersonic-wayland.overrideAttrs (old: rec {
      version = "0.22.0";
      src = fetchFromGitHub {
        owner = "dweymouth";
        repo = "supersonic";
        rev = version;
        hash = "sha256-Ynw/NLDk2AVmn30llFtt/A9hEheUZ+/VZqXOIdiUSxQ=";
      };

      vendorHash = "sha256-W5Uwma72lqJB+QHkSasi7WArsYlfXLVPph9TlDSxFEk=";
      # "go mod vendor" fails to build; go-gl/glfw fails with an error like:
      # xdg-shell-client-protocol.h: No such file or directory
      proxyVendor = true;

      # work around https://github.com/dweymouth/supersonic/issues/316
      nativeBuildInputs = old.nativeBuildInputs ++ [
        pkgs.makeWrapper
      ];

      postInstall = old.postInstall + ''
        wrapProgram $out/bin/supersonic-wayland \
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
    #Host *
    #  SetEnv TERM=xterm-256color

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
