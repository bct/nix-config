{ pkgs, ... }:

{
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

    grep = "grep --color=auto";

    wg-up = "sudo systemctl start wg-quick-wg0.service";
    wg-down = "sudo systemctl stop wg-quick-wg0.service";
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

  programs.direnv = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    icons = true;
    git = true;
  };
}
