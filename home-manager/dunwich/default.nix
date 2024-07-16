{ pkgs, ... }: {
  imports = [
    ../desktop
  ];

  personal.user = "brendan";
  personal.email = "brendan@artificial.agency";

  personal.xmonad.extraWorkspaces = ./files/ExtraWorkspaces.hs;
  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.pointerCursor = {
    package = pkgs.unstable.hackneyed;
    name = "Hackneyed";
    size = 24;
    x11.enable = true;
  };

  home.packages = with pkgs; [
    slack
    _1password
    _1password-gui

    vscode

    python311
    pipenv
    awscli2
    ansible
    process-compose

    terraform

    prismlauncher
  ];

  programs.git.lfs.enable = true;

  # set the urgent flag on Slack when it sends a notification
  # https://gist.github.com/andreycizov/738f80a16c9e401d6a9e77b863e67066
  services.dunst.settings.slack = let
    setUrgent = pkgs.writeScript "dunst-set-urgent" ''
      ${pkgs.wmctrl}/bin/wmctrl -r $1 -b add,demands_attention
    '';
  in {
    appname = "Slack";
    summary = "*";

    script = toString setUrgent;
  };

  programs.autorandr = {
    enable = true;
  };

  services.autorandr = {
    enable = false;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
