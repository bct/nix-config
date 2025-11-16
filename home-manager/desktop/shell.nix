{ ... }:

{
  home.sessionPath = [
    "$HOME/.local/share/gem/ruby/3.0.0/bin"
    "$HOME/bin"
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    LANG = "en_CA.utf8";

    # we can't run Pythons downloaded by uv, don't even attempt it.
    UV_PYTHON_DOWNLOADS = "never";
  };

  home.shellAliases = {
    # switch to qwerty
    aoeu = "hyprctl switchxkblayout current 1";

    # switch to dvorak
    asdf = "hyprctl switchxkblayout current 0";

    grep = "grep --color=auto";

    wg-up = "sudo systemctl start wg-quick-wg0.service";
    wg-down = "sudo systemctl stop wg-quick-wg0.service";
  };

  programs.bash = {
    enable = true;
    historyControl = ["ignoredups"];

    initExtra = ''
      # go to the root of the current repository
      r() {
        cd "$(git rev-parse --show-toplevel 2>/dev/null)"
      }

      # make ^L work
      bind -m vi-insert 'Control-l: clear-screen'
    '';
  };

  programs.z-lua = {
    enable = true;
    enableAliases = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
    config = {
      global = {
        hide_env_diff = true;
      };
    };
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };
}
