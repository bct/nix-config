{ config, pkgs, ... }:

let cfgPersonal = config.personal;
in {
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

  users.users.${cfgPersonal.user}.packages = with pkgs; [
    chromium
    brave
    mpv
    epdfview
    libreoffice

    # 3d printing
    cura5
    freecad
    openscad

    ansible

    # for "strings"
    binutils

    # other utilities
    nmap
    file

    unstable.androidStudioPackages.canary
    gcc # Android Studio needs cc.

    gimp

    sane-backends
    sane-airscan
    xsane

    hoon-crib

    # archivers
    p7zip
    unzip
    unrar
  ];
}
