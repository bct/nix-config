{
  self,
  config,
  lib,
  ...
}:
let
  gonicPort = 4747;
in
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "25.11";

  microvm = {
    vcpu = 1;
    mem = 1024;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];

    shares = [
      {
        tag = "video";
        source = "/mnt/bulk/video";
        mountPoint = "/mnt/video";
        proto = "virtiofs";
      }

      {
        tag = "beets";
        source = "/mnt/bulk/beets/library";
        mountPoint = "/mnt/beets";
        proto = "virtiofs";
        readOnly = true;
      }
    ];
  };

  age.secrets = {
    # a hashed password.
    passwd-blackbeard.rekeyFile = ./secrets/passwd-media-blackbeard.age;
  };

  # -- sshfs host --
  services.openssh = {
    settings.PasswordAuthentication = lib.mkForce true;
    # TODO: add a chroot here.
    extraConfig = ''
      Match user blackbeard
        ForceCommand internal-sftp
    '';
  };

  users.users.blackbeard = {
    isSystemUser = true;
    group = "blackbeard";
    hashedPasswordFile = config.age.secrets.passwd-blackbeard.path;

    # system users default to nologin.
    # sshd won't let us execute commands without a shell.
    useDefaultShell = true;

    # kodi uses passwords to connect to this account.
    openssh.authorizedKeys.keys = [ ];
  };
  users.groups.blackbeard = {
    gid = 1005;
    members = [ "blackbeard" ];
  };

  # -- gonic / subsonic --
  services.lego-proxy-client = {
    enable = true;
    domains = [ "media" ];
  };

  networking.firewall.allowedTCPPorts = [
    gonicPort
  ];

  services.gonic = {
    enable = true;
    settings = {
      listen-addr = "0.0.0.0:${toString gonicPort}";
      cache-path = "/var/cache/gonic";

      playlists-path = "/var/lib/gonic";
      music-path = [ "/mnt/beets" ];
      podcast-path = "/var/empty";
      scan-interval = 60; # minutes

      multi-value-genre = "delim ,";

      tls-cert = "${config.security.acme.certs."media.domus.diffeq.com".directory}/fullchain.pem";
      tls-key = "${config.security.acme.certs."media.domus.diffeq.com".directory}/key.pem";
    };
  };
  systemd.services.gonic.serviceConfig.SupplementaryGroups = [ "acme" ];
}
