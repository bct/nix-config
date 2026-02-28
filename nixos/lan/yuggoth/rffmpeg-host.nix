{ pkgs, config, ... }:
let
  rffmpeg = pkgs.writeShellApplication {
    name = "rffmpeg";
    runtimeInputs = [ pkgs.jellyfin-ffmpeg ];
    text = builtins.readFile ./rffmpeg.sh;
  };
in
{
  systemd.tmpfiles.rules = [
    "d /var/cache/jellyfin 0700 rffmpeg rffmpeg -"
  ];

  users.users.rffmpeg = {
    isSystemUser = true;
    group = "rffmpeg";

    # TODO: this needs to be the same user as jellyfin in the jellyfin VM.
    # make sure they're synchronized.
    uid = 993;

    # system users default to nologin.
    # sshd won't let us execute commands without a shell.
    useDefaultShell = true;

    openssh.authorizedKeys.keys =
      let
        jellyfin = (builtins.readFile (config.diffeq.secretsPath + /ssh/rffmpeg-yuggoth.pub));
      in
      [
        "command=\"${toString rffmpeg}/bin/rffmpeg\" ${jellyfin}"

        # temporary key for testing.
        "command=\"${toString rffmpeg}/bin/rffmpeg\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOEx8Hxam+kN/wBLF4Qnuxg7K21nEze/71IRm2EMwmax bct@aquilonia"
      ];
  };
  users.groups.rffmpeg = { };

  fileSystems."/mnt/video" = {
    device = "//mi-go.domus.diffeq.com/video";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,x-systemd.after=network-online.target";

        # the defaults of a CIFS mount are not documented anywhere that I can see.
        # you can run "mount" after mounting to see what options were actually used.
        # cifsacl is required for the server-side permissions to show up correctly.
      in
      [
        "${automount_opts},ro,cifsacl,uid=rffmpeg,credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"
      ];
  };

  age.secrets = {
    # TODO: separate users?
    fs-mi-go-torrent-scraper = {
      # username: torrent-scraper
      rekeyFile = config.diffeq.secretsPath + /fs/mi-go-torrent-scraper.age;
    };
  };

  hardware.graphics.enable = true;
}
