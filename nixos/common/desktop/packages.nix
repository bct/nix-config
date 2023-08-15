{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    git
    wget

    home-manager

    sshfs
    exfat
    ntfs3g

    # killall, etc.
    psmisc
  ];

  users.users.bct.packages = with pkgs; [
    chromium
    brave
    mpv
    epdfview
    libreoffice

    cura5
    freecad

    ansible
    nmap

    # for "strings"
    binutils

    androidStudioPackages.canary
  ];
}
