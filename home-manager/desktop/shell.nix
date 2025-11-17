{ pkgs, lib, config, ... }:

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

  programs.atuin = {
    enable = true;

    # https://github.com/nix-community/home-manager/issues/5958
    # also see below.
    enableBashIntegration = false;
    # https://docs.atuin.sh/configuration/config/
    # Writes ~/.config/atuin/config.toml
    settings = {
      prefers_reduced_motion = true;  # No automatic time updates
    };
  };

  # ensure that we source bash-preexec after direnv - otherwise atuin doesn't work.
  # https://github.com/nix-community/home-manager/issues/5958
  programs.bash.initExtra = lib.mkOrder 1510 ''
    # go to the root of the current repository
    r() {
      cd "$(git rev-parse --show-toplevel 2>/dev/null)"
    }

    # make ^L work
    bind -m vi-insert 'Control-l: clear-screen'

    # like programs.atuin.enableBashIntegration.
    source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
    eval "$(${config.programs.atuin.package}/bin/atuin init bash )"
  '';
}
