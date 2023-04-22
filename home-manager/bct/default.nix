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

    ignores = [
      ".*.s[a-w][a-z]"
      ".s[a-w][a-z]"
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
