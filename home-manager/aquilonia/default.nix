{ pkgs, inputs, ... }:
{
  imports = [
    ../desktop
    ./lutris.nix
  ];

  personal.user = "bct";
  personal.email = "bct@diffeq.com";

  home.packages = with pkgs; [
    brave
    libreoffice

    ansible

    gimp3
    inkscape

    # fixes missing icons in inkscape
    # https://github.com/NixOS/nixpkgs/pull/447250
    adwaita-icon-theme

    hoon-crib

    wine
    winetricks
    vulkan-tools

    moonlight-qt

    obsidian
    koodo-reader

    inputs.fjord-launcher.packages.${pkgs.stdenv.hostPlatform.system}.fjordlauncher
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
  home.stateVersion = "25.05";
}
