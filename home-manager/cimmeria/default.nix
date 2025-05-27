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

    inputs.deploy-rs.packages.${pkgs.system}.deploy-rs

    wine
    winetricks
    vulkan-tools

    moonlight-embedded
  ];

  systemd.user.mounts.bulk = {
    Unit = {
      Description = "Mount /bulk";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = { WantedBy = [ "default.target" ]; };

    Mount = {
      What = "bct@mi-go.domus.diffeq.com:/mnt/bulk";
      Where = "/bulk";
      Type = "fuse.sshfs";
      Options = "_netdev,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount";
      TimeoutSec = 60;
    };
  };

  systemd.user.mounts.mnt-beets = {
    Unit = {
      Description = "Mount /mnt/beets";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Install = { WantedBy = [ "default.target" ]; };

    Mount = {
      What = "bct@mi-go.domus.diffeq.com:/mnt/bulk/beets";
      Where = "/mnt/beets";
      Type = "fuse.sshfs";
      Options = "_netdev,reconnect,ServerAliveInterval=30,ServerAliveCountMax=5,x-systemd.automount";
      TimeoutSec = 60;
    };
  };

  programs.beets = {
    enable = true;
    settings = {
      library = "/mnt/beets/library.db";
      directory = "/mnt/beets/library";

      plugins = "fetchart inline lastgenre permissions";

      import = {
        copy = true;
        log = "/mnt/beets/log/import.log";
      };

      per_disc_numbering = true;

      pathfields = {
        disc_and_track = "u'%01i-%02i' % (disc, track) if disctotal > 1 else u'%02i' % (track)";
      };

      paths = {
        default = "%if{$albumartist_sort,$albumartist_sort,$albumartist}/$album%aunique{}/$disc_and_track - $title";
        comp = "Compilations/$album%aunique{}/$disc_and_track - $artist - $title";
      };

      lastgenre = {
        count = 2;
        force = false;
      };

      permissions = {
        file = 644;
        dir = 755;
      };
    };
  };

  programs.oh-my-posh = {
    enable = true;
    settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./oh-my-posh.json));
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "22.11";
}
