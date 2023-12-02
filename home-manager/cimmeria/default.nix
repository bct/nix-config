{ pkgs, inputs, ... }: {
  imports = [
    ../desktop
  ];

  personal.user = "bct";
  personal.email = "bct@diffeq.com";

  personal.xmonad.extraWorkspaces = ./files/ExtraWorkspaces.hs;
  home.file.".xmobarrc".source = ./files/xmobarrc.hs;

  home.packages = with pkgs; [
    pollymc

    brave
    libreoffice

    ansible

    gimp

    hoon-crib

    inputs.deploy-rs.packages.x86_64-linux.deploy-rs
  ];

  systemd.user.mounts.bulk = {
    Unit = {
      Description = "Mount /bulk";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = { WantedBy = [ "default.target" ]; };

    Mount = {
      What = "bct@mi-go.domus.diffeq.com:/mnt/bulk/media";
      Where = "/bulk";
      Type = "fuse.sshfs";
      Options = "_netdev,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount";
      TimeoutSec = 60;
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
