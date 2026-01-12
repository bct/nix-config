{ config, pkgs, ... }:
let
  rtSocketPort = 8888;
  rtUnixSocketDir = "/run/rtorrent";
  rtUnixSocketPath = "${rtUnixSocketDir}/rpc.sock";
in
{
  systemd.tmpfiles.rules = [
    "d ${rtUnixSocketDir} 0770 bct rtorrent -"
  ];

  environment.systemPackages = [
    pkgs.rtorrent
  ];

  services.nginx = {
    enable = true;
    group = "rtorrent";

    virtualHosts = {
      rtorrent-xml-rpc = {
        serverName = "rtorrent.domus.diffeq.com";
        listen = [
          {
            addr = "127.0.0.1";
            port = rtSocketPort;
          }
        ];

        basicAuthFile = config.age.secrets.rtorrent-xml-rpc-nginx-auth.path;

        locations."/RPC2" = {
          extraConfig = ''
            include ${config.services.nginx.package}/conf/scgi_params;
            scgi_pass unix:${rtUnixSocketPath};
          '';
        };
      };
    };
  };

  age.secrets = {
    rtorrent-xml-rpc-nginx-auth = {
      rekeyFile = ../../lan/yuggoth/guests/secrets/rtorrent-xml-rpc-nginx-auth.age;
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };
  };
}
