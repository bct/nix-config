{ ... }:
let
  port = 3003;
in
{
  users.users.cat-rater = {
    isSystemUser = true;
    group = "cat-rater";
  };
  users.groups.cat-rater = { };

  systemd.tmpfiles.rules = [
    # ensure that /srv/cat-rater exists.
    # "-" means no automatic cleanup.
    "d /srv/cat-rater 0755 cat-rater cat-rater -"
  ];

  systemd.services.cat-rater = {
    description = "cat-rater";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      PORT = toString port;
      GIN_MODE = "release";
    };

    serviceConfig = {
      ExecStart = "/srv/cat-rater/.nix-profile/bin/cat-rater";
      User = "cat-rater";
      Group = "cat-rater";
      WorkingDirectory = "/srv/cat-rater";
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts."cats.birdlor.biz".extraConfig = ''
      reverse_proxy localhost:${toString port}
    '';
  };
}
