{ inputs, lib, config, pkgs, ... }: {
  imports = [];

  home = {
    username = "bct";
    homeDirectory = "/home/bct";
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Brendan Taylor";
    userEmail = "bct@diffeq.com";

    extraConfig = {
      init.defaultBranch = "master";
      rebase.autosquash = true;
    };

    aliases = {
      bru = "!branch=\$(git rev-parse --abbrev-ref HEAD) && git config branch.\$branch.remote \${1:-origin} && git config branch.\$branch.merge refs/heads/\${2:-\$branch} && :";
      cobu = "!git checkout -b \${1:-tmp} && git bru \${2:-origin}";
      lol = "log --graph --pretty=format:\"%C(yellow)%h%Creset%C(cyan)%C(bold)%d%Creset %C(cyan)(%cr)%Creset %C(green)%ce%Creset %s\"";
      lola = "log --graph --all --pretty=format:\"%C(yellow)%h%Creset%C(cyan)%C(bold)%d%Creset %C(cyan)(%cr)%Creset %C(green)%ce%Creset %s\"";
      branches = "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(align:30,left)%(color:normal)%(refname:short)%(color:reset)%(end) %(color:normal dim)%(objectname:short)%(color:reset) %(color:green)(%(committerdate:relative))%(color:reset)'";
    };

    ignores = [
      ".*.s[a-w][a-z]"
      ".s[a-w][a-z]"
    ];
  };

  programs.readline = {
    enable = true;
    variables = {
      editing-mode = "vi";
      keymap = "vi";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}