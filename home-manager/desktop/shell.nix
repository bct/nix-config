{
  config,
  pkgs,
  ...
}:

{
  personal.enableFancyShell = true;

  home.sessionPath = [
    "$HOME/.local/share/gem/ruby/3.0.0/bin"
    "$HOME/bin"
  ];

  home.sessionVariables =
    let
      XDG_DATA_HOME = config.xdg.dataHome;
    in
    {
      EDITOR = "vim";
      LANG = "en_CA.utf8";

      # we can't run Pythons downloaded by uv, don't even attempt it.
      UV_PYTHON_DOWNLOADS = "never";

      GOPATH = "${XDG_DATA_HOME}/go";
      CARGO_HOME = "${XDG_DATA_HOME}/cargo";
      RUSTUP_HOME = "${XDG_DATA_HOME}/rustup";
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
    historyControl = [ "ignoredups" ];
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

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;

    # TODO(unstable): revert to stable for atuin >= 18.21.0
    package = pkgs.unstable.atuin;

    # https://docs.atuin.sh/configuration/config/
    # Writes ~/.config/atuin/config.toml
    settings = {
      prefers_reduced_motion = true; # No automatic time updates
      inline_height = 16; # Allow me to see some of the terminal history
      filter_mode_shell_up_key_binding = "session"; # Up only searches the current session
    };
  };

  programs.oh-my-posh = {
    enable = true;
    enableBashIntegration = true;

    settings = builtins.fromJSON (
      builtins.unsafeDiscardStringContext (builtins.readFile ./files/oh-my-posh.json)
    );
  };
}
