{ pkgs, ... }: {
  imports = [
    ../desktop
  ];

  personal.user = "bct";
  personal.email = "bct@diffeq.com";

  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.packages = with pkgs; [
    pollymc

    brave
    libreoffice

    ansible

    gimp

    hoon-crib
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
