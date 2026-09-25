{
  lib,
  config,
  ...
}:

let
  cfgPersonal = config.personal;
in
{
  imports = [ ./nix.nix ];

  options = {
    personal = {
      user = lib.mkOption {
        type = lib.types.str;
        description = "Username for the primary user.";
      };

      email = lib.mkOption {
        type = lib.types.str;
        description = "Email for the primary user.";
      };

      enableFancyShell = lib.mkOption {
        type = lib.types.bool;
        description = "Enable fancy shell settings?";
        default = false;
      };
    };
  };

  config = {
    home = {
      username = cfgPersonal.user;
      homeDirectory = lib.mkDefault "/home/${cfgPersonal.user}";
    };

    # Enable home-manager and git
    programs.home-manager.enable = true;
    programs.git = {
      enable = true;

      settings = {
        user.name = "Brendan Taylor";
        user.email = cfgPersonal.email;

        init.defaultBranch = "master";
        rebase.autosquash = true;

        alias = {
          bru = "!branch=\$(git rev-parse --abbrev-ref HEAD) && git config branch.\$branch.remote \${1:-origin} && git config branch.\$branch.merge refs/heads/\${2:-\$branch} && :";
          cobu = "!git checkout -b \${1:-tmp} && git bru \${2:-origin}";
          lol = "log --graph --pretty=format:\"%C(yellow)%h%Creset%C(cyan)%C(bold)%d%Creset %C(cyan)(%cr)%Creset %C(green)%ce%Creset %s\"";
          lola = "log --graph --all --pretty=format:\"%C(yellow)%h%Creset%C(cyan)%C(bold)%d%Creset %C(cyan)(%cr)%Creset %C(green)%ce%Creset %s\"";
          branches = "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(align:30,left)%(color:normal)%(refname:short)%(color:reset)%(end) %(color:normal dim)%(objectname:short)%(color:reset) %(color:green)(%(committerdate:relative))%(color:reset)'";
        };
      };

      ignores = [
        ".*.s[a-w][a-z]"
        ".s[a-w][a-z]"
        ".envrc"
        ".direnv"
      ];
    };

    programs.readline = {
      enable = true;
      variables = {
        editing-mode = "vi";
        keymap = "vi";
      };
    };

    programs.bash = {
      enable = true;

      initExtra = ''
        # make ^L work
        bind -m vi-insert 'Control-l: clear-screen'
      '';
    };

    programs.eza = lib.mkIf cfgPersonal.enableFancyShell {
      enable = true;
      icons = "auto";

      # I don't use this feature, and it makes `ls -l` slow when there area lot of untracked files.
      git = false;
    };

    programs.z-lua = lib.mkIf cfgPersonal.enableFancyShell {
      enable = true;
      enableAliases = true;
    };

    home.sessionVariables = {
      EDITOR = "vim";
    };
  };
}
