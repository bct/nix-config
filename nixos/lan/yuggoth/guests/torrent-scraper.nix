{
  self,
  config,
  ...
}:
{
  imports = [
    "${self}/nixos/modules/lego-proxy-client"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 2304;

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
      "seerr"
      "sonarr"
    ];
  };

  users.users = {
    torrent-scraper = {
      isSystemUser = true;
      group = "video-writers";
      uid = config.diffeq.accounts.userIds.torrent-scraper;
      # we need to be able to read & write the downloads in order to create hard links to them.
      # (kernel parameter fs.protected_hardlinks)
      extraGroups = [ "blackbeard" ];
    };
    bct.extraGroups = [
      "blackbeard"
      "video-writers"
    ];
    caddy.extraGroups = [ "acme" ];
  };
  users.groups.blackbeard.gid = config.diffeq.accounts.groupIds.blackbeard;
  users.groups.video-writers.gid = config.diffeq.accounts.groupIds.video-writers;

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  # port 7878
  services.radarr = {
    enable = true;
    openFirewall = false;
    user = "torrent-scraper";
    group = "blackbeard";
    # to support external auth, manually add this to the config XML:
    # <AuthenticationMethod>External</AuthenticationMethod>
    # <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  };

  # port 8989
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "torrent-scraper";
    group = "blackbeard";
    # to support external auth, manually add this to the config XML:
    # <AuthenticationMethod>External</AuthenticationMethod>
    # <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired>
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = false;
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
      in
      [
        "${automount_opts},uid=torrent-scraper,gid=blackbeard,posix,file_mode=0664,dir_mode=0775,credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"
      ];
  };

  age.secrets = {
    fs-mi-go-torrent-scraper = {
      # username: torrent-scraper
      rekeyFile = config.diffeq.secretsPath + /fs/mi-go-torrent-scraper.age;
    };
  };

  users.groups = {
    rtorrent = { };
  };

  services.caddy = {
    enable = true;
    virtualHosts."radarr.domus.diffeq.com" = {
      useACMEHost = "radarr.domus.diffeq.com";
      # https://github.com/openappssh/openapps/blob/main/projects/authentication/tinyauth.mdx#caddy-configuration
      extraConfig = ''
        # the API is authed with an API key that is obtained from the frontend.
        # we only need to control access to the frontend.
        @not-api {
          not path_regexp (/radarr)?/api
        }
        forward_auth @not-api https://auth.domus.diffeq.com {
            uri /api/auth/caddy
            copy_headers Remote-User Remote-Email Remote-Name Remote-Groups
        }
        reverse_proxy localhost:${toString config.services.radarr.settings.server.port}
      '';
    };

    virtualHosts."sonarr.domus.diffeq.com" = {
      useACMEHost = "sonarr.domus.diffeq.com";
      # https://github.com/openappssh/openapps/blob/main/projects/authentication/tinyauth.mdx#caddy-configuration
      extraConfig = ''
        # the API is authed with an API key that is obtained from the frontend.
        # we only need to control access to the frontend.
        @not-api {
          not path_regexp (/sonarr)?/api
        }
        forward_auth @not-api https://auth.domus.diffeq.com {
            uri /api/auth/caddy
            copy_headers Remote-User Remote-Email Remote-Name Remote-Groups
        }
        reverse_proxy localhost:${toString config.services.sonarr.settings.server.port}
      '';
    };

    virtualHosts."seerr.domus.diffeq.com" = {
      useACMEHost = "seerr.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.jellyseerr.port}";
    };
  };
}
