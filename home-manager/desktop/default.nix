# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)

{ outputs, pkgs, ... }: {
  imports = [
    ../base

    ../modules/dunst
    ../modules/rofi
    ../modules/vim
    ../modules/xmonad
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

  home.packages = with pkgs; [
    # fonts
    ubuntu_font_family
    (nerdfonts.override { fonts = [ "UbuntuMono" ]; })

    # terminal
    alacritty

    # utilities
    htop
    silver-searcher
    ruby

    # screen locking
    xss-lock
    sxlock

    # background
    feh
  ];

  fonts.fontconfig.enable = true;

  home.sessionPath = [
    "$HOME/.local/share/gem/ruby/3.0.0/bin"
    "$HOME/bin"
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "en_CA.utf8";

    # scale chromium/brave browser UIs.
    # maybe I should figure out how to scale the UI more generally?
    CHROME_EXTRA_FLAGS = "--force-device-scale-factor=1.5";
  };

  home.shellAliases = {
    aoeu = "setxkbmap -layout us";
    asdf = "setxkbmap -layout us -variant dvorak";

    ls = "ls --color=auto";
    grep = "grep --color=auto";
  };

  xsession = {
    enable = true;
    initExtra = ''
      # hook up sxlock to the screen saver extension and systemd's login manager
      xss-lock -- sxlock &

      # set desktop background
      ~/.fehbg &

      xset dpms 0 120 180 &

      # set minimum brightness higher than 0
      ${pkgs.light}/bin/light -N 0.1
    '';
  };

  programs.bash = {
    enable = true;
    historyControl = ["ignoredups"];

    initExtra = ''
      # autojump
      eval "$(${pkgs.z-lua}/bin/z --init bash)"

      # go to the root of the current repository
      r() {
        cd "$(git rev-parse --show-toplevel 2>/dev/null)"
      }

      . ~/.nix-profile/share/git/contrib/completion/git-prompt.sh

      # bct@cimmeria:~/projects/nixfiles (master) $
      PS1='\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] $(__git_ps1 "(%s)")\$ '

      # If this is a GUI terminal, set the title to user@host:dir
      case "$TERM" in
      xterm*|rxvt*|alacritty*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
          ;;
      *)
          ;;
      esac

      # make ^L work
      bind -m vi-insert 'Control-l: clear-screen'

      export NIX_PATH=$HOME/.nix-defexpr/channels:/nix/var/nix/profiles/per-user/root/channels''${NIX_PATH:+:$NIX_PATH}
    '';
  };

  # Raw configuration files
  home.file.".alacritty.yml".source = ./files/alacritty.yml;

  home.file.".ssh/config".text = ''
    # 2022-08-06 many hosts (e.g. mi-go) don't have alacritty terminfo
    Host *
      SetEnv TERM=xterm-256color
  '';

  home.file."bin/mount-host".source = ./files/bin/mount-host;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
