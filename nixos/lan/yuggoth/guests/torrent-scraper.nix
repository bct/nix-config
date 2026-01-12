{
  self,
  pkgs,
  config,
  ...
}:
let
  rtSocketPort = 8888;
  rtUnixSocketPath = "/run/rtorrent-socket/rtorrent.sock";
in
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 1536;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 4096;
      }
    ];
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      "radarr"
      "sonarr"
    ];
  };

  users.groups.video-writers = {
    # guarantee a stable GID, since /etc is not persistent.
    gid = 989;
  };
  users.users = {
    scraper = {
      isSystemUser = true;
      group = "video-writers";

      # guarantee a stable UID, since /etc is not persistent.
      uid = 992;
    };
    bct.extraGroups = [ "video-writers" ];
    nginx.extraGroups = [ "acme" ];
  };

  networking.firewall.allowedTCPPorts = [
    # nginx
    80
    443
  ];

  # port 7878
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "scraper";
    group = "video-writers";
    # to support external auth, manually add this to the config XML:
    # <AuthenticationMethod>External</AuthenticationMethod>
    # <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  };

  # port 8989
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "scraper";
    group = "video-writers";
    # to support external auth, manually add this to the config XML:
    # <AuthenticationMethod>External</AuthenticationMethod>
    # <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  };

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
        "${automount_opts},cifsacl,uid=scraper,gid=video-writers,credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"
      ];
  };

  age.secrets = {
    fs-mi-go-torrent-scraper = {
      # username: torrent-scraper
      rekeyFile = config.diffeq.secretsPath + /fs/mi-go-torrent-scraper.age;
    };

    ssh-client-rtorrent-socket = {
      rekeyFile = config.diffeq.secretsPath + /ssh/client-rtorrent-socket.age;
    };

    rtorrent-xml-rpc-nginx-auth = {
      rekeyFile = ./secrets/rtorrent-xml-rpc-nginx-auth.age;
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };
  };

  users.groups = {
    rtorrent = { };
  };

  # https://gist.github.com/drmalex07/c0f9304deea566842490
  systemd.services.rtorrent-socket = {
    enable = true;
    description = "rTorrent socket tunnel";
    serviceConfig = {
      LoadCredential = [
        "ssh-identity:${config.age.secrets.ssh-client-rtorrent-socket.path}"
      ];
      RuntimeDirectory = "rtorrent-socket";

      ExecStart = builtins.concatStringsSep " " [
        "${pkgs.openssh}/bin/ssh"
        # ServerAliveInterval: check that the connection is alive
        "-o ServerAliveInterval=60"
        # ExitOnForwardfailure: close the connection if the tunnel fails
        "-o ExitOnForwardFailure=yes"
        # StreamLocalBindMask=0117: make a socket that group-writeable
        "-o StreamLocalBindMask=0117"
        "-i \${CREDENTIALS_DIRECTORY}/ssh-identity"
        "-N"
        "-L \${RUNTIME_DIRECTORY}/rtorrent.sock:/var/home/bct/.rtorrent/rpc.sock bct@torrent.domus.diffeq.com"
      ];

      # Restart every >2 seconds to avoid StartLimitInterval failure
      RestartSec = 5;
      Restart = "always";

      DynamicUser = true;

      # this is the group that will own the socket
      Group = "rtorrent";
    };

    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  programs.ssh.knownHosts = {
    "torrent.domus.diffeq.com".publicKey = builtins.readFile (
      config.diffeq.secretsPath + /ssh/host-torrent.pub
    );
  };

  services.nginx =
    let
      reverseProxyWithTinyAuth =
        {
          port,
          unauthed ? [ ],
        }:
        {
          # https://tinyauth.app/docs/guides/nginx-proxy-manager/#advanced-configuration
          "/" = {
            proxyPass = "http://localhost:${toString port}";
            proxyWebsockets = true;
            extraConfig = ''
              auth_request /tinyauth;
              error_page 401 = @tinyauth_login;
            '';
          };
          "/tinyauth" = {
            proxyPass = "https://${config.diffeq.hostNames.auth}/api/auth/nginx";
            extraConfig = ''
              internal;

              # ignore the request body, tinyauth isn't looking at it anyhow.
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";

              proxy_ssl_server_name on;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-Host $http_host;
              proxy_set_header X-Forwarded-Uri $request_uri;
            '';
          };

          "@tinyauth_login" = {
            return = "302 https://${config.diffeq.hostNames.auth}/login?redirect_uri=$scheme://$http_host$request_uri";
          };
        }
        // builtins.listToAttrs (
          map (l: {
            name = l;
            value = {
              proxyPass = "http://localhost:${toString port}";
            };
          }) unauthed
        );
    in
    {
      enable = true;
      group = "rtorrent";

      virtualHosts = {
        # expose rtorrent XML-RPC over HTTP, adding authentication.
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

        "radarr.domus.diffeq.com" = {
          useACMEHost = "radarr.domus.diffeq.com";
          forceSSL = true;

          locations = reverseProxyWithTinyAuth {
            port = config.services.radarr.settings.server.port;
            unauthed = [ "~ (/radarr)?/api" ];
          };
        };

        "sonarr.domus.diffeq.com" = {
          useACMEHost = "sonarr.domus.diffeq.com";
          forceSSL = true;

          locations = reverseProxyWithTinyAuth {
            port = config.services.sonarr.settings.server.port;
            unauthed = [ "~ (/sonarr)?/api" ];
          };
        };
      };
    };
}
