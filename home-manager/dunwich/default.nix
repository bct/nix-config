{ pkgs, ... }: {
  imports = [
    ../desktop
  ];

  personal.user = "brendan";
  personal.email = "brendan@artificial.agency";

  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.packages = with pkgs; [
    slack
    _1password
    _1password-gui

    vscode

    python311
    pipenv
    awscli2

    scrot
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
