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

  users.users.brendan.packages = with pkgs; [
    chromium
    mpv
    epdfview

    # for "strings"
    binutils

    # other utilities
    nmap
    file

    # archivers
    p7zip
    unzip
    unrar
  ];
}
