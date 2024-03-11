{ outputs, pkgs, ... }: {
  imports = [
    ../base

    ../modules/dunst
    ../modules/rofi
    ../modules/vim
    ../modules/xmonad

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

    # media
    supersonic
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

    wg-up = "sudo systemctl start wg-quick-wg0.service";
    wg-down = "sudo systemctl stop wg-quick-wg0.service";
  };

  xsession = let
    # https://gist.github.com/erfanio/eec67e1a538eeef3ff72562412030b6a
    # "adapted from xss-lock documantation"
    # https://bitbucket.org/raymonad/xss-lock/src/1e158fb20108058dbd62bd51d8e8c003c0a48717/doc/dim-screen.sh
    dim-screen = pkgs.writeScript "dim-screen" ''
      #!/bin/sh

      set -euo pipefail

      # Brightness will be lowered to this value.
      min_brightness=0

      ###############################################################################

      get_brightness() {
          ${pkgs.light}/bin/light -G
      }

      set_brightness() {
          ${pkgs.light}/bin/light -S $1
      }

      trap "exit 0" INT TERM
      # kill background processes and set the brightness back to the original value
      trap "kill \$(jobs -p); set_brightness $(get_brightness);" EXIT

      set_brightness $min_brightness

      sleep 2147483647 &
      wait
    '';
  in {
    enable = true;
    initExtra = ''
      # Dim the screen after three minutes of inactivity.
      # Lock the screen two minutes later.
      xset s 180 120

      # hook up sxlock to the screen saver extension and systemd's login manager
      xss-lock -n "${dim-screen}" -- sxlock &

      # set desktop background
      ~/.fehbg &

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
