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
    openscad

    ansible
    nmap

    # for "strings"
    binutils

    unstable.androidStudioPackages.canary
    gcc # Android Studio needs cc.

    gimp

    sane-backends
    sane-airscan
    xsane

    hoon-crib
  ];
}
