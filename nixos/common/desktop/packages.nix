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
    mpv
    epdfview

    # for "strings"
    binutils

    # other utilities
    nmap
    file

    sane-backends
    sane-airscan
    xsane

    # archivers
    p7zip
    unzip
    unrar
  ];
}
