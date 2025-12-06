{ pkgs, inputs, ... }:
{
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

    wine
    winetricks
    vulkan-tools

    moonlight-embedded

    obsidian
    koodo-reader
  ];

  systemd.user.mounts.bulk = {
    Unit = {
      Description = "Mount /bulk";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = {
      WantedBy = [ "default.target" ];
    };

    Mount = {
      What = "bct@mi-go.domus.diffeq.com:/mnt/bulk";
      Where = "/bulk";
      Type = "fuse.sshfs";
      Options = "_netdev,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount";
      TimeoutSec = 60;
    };
  };

  programs.zathura = {
    enable = true;
    options = {
      open-first-page = true;
      page-v-padding = 5;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
