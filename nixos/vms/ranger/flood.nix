{ config, ... }:
let
  rtUnixSocketPath = "/run/rtorrent/rpc.sock";
in
{
  services.flood = {
    enable = true;
    openFirewall = false;
    host = "127.0.0.1";
    extraArgs = [
      "--auth=none"
      "--rtsocket=${rtUnixSocketPath}"
    ];
  };
  systemd.services.flood.serviceConfig.SupplementaryGroups = [
    "rtorrent" # flood can access the rtorrent socket
    "video-writers" # flood can directly modify downloaded files
  ];

  services.caddy = {
    enable = true;
    virtualHosts."flood.domus.diffeq.com" = {
      useACMEHost = "flood.domus.diffeq.com";
      # https://github.com/openappssh/openapps/blob/main/projects/authentication/tinyauth.mdx#caddy-configuration
      extraConfig = ''
        forward_auth https://auth.domus.diffeq.com {
            uri /api/auth/caddy
            copy_headers Remote-User Remote-Email Remote-Name
        }
        reverse_proxy localhost:${toString config.services.flood.port}
      '';
    };
  };
}
