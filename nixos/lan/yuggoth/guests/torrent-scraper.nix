{ self, inputs, pkgs, config, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-client"
    "${inputs.nixpkgs-unstable}/nixos/modules/services/torrent/flood.nix"
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
    bct.extraGroups = ["video-writers"];
    nginx.extraGroups = ["acme"];
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
  };

  # port 8989
  services.sonarr = {
    enable = true;
    openFirewall = false;
    user = "scraper";
    group = "video-writers";
  };

  fileSystems."/mnt/video" = {
    device = "//mi-go.domus.diffeq.com/video";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},cifsacl,uid=scraper,gid=video-writers,credentials=${config.age.secrets.fs-mi-go-torrent-scraper.path}"];
  };

  # TODO: pull from the .pub on disk?
  age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILwu2O9ulPoL1YYEIkbDOjA5B7h/efXYjrPPV0xNpOxY root@torrent-scraper";

  age.secrets = {
    fs-mi-go-torrent-scraper = {
      rekeyFile = ../../../../secrets/fs/mi-go-torrent-scraper.age;
    };

    ssh-client-rtorrent-socket = {
      rekeyFile = ../../../../secrets/ssh/client-rtorrent-socket.age;
    };

    rtorrent-xml-rpc-nginx-auth = {
      rekeyFile = ./secrets/rtorrent-xml-rpc-nginx-auth.age;
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };

    lego-proxy-flood = {
      generator.script = "ssh-ed25519";
      rekeyFile = ../../../../secrets/lego-proxy/flood.age;
      owner = "acme";
      group = "acme";
    };

    lego-proxy-radarr = {
      generator.script = "ssh-ed25519";
      rekeyFile = ../../../../secrets/lego-proxy/radarr.age;
      owner = "acme";
      group = "acme";
    };

    lego-proxy-sonarr = {
      generator.script = "ssh-ed25519";
      rekeyFile = ../../../../secrets/lego-proxy/sonarr.age;
      owner = "acme";
      group = "acme";
    };
  };

  services.lego-proxy-client = {
    enable = true;
    domains = [
      { domain = "flood.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-flood.path; }
      { domain = "radarr.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-radarr.path; }
      { domain = "sonarr.domus.diffeq.com"; identity = config.age.secrets.lego-proxy-sonarr.path; }
    ];
    dnsResolver = "ns5.zoneedit.com";
    email = "s+acme@diffeq.com";
  };

  users.groups = {
    rtorrent = {};
  };

  services.flood = {
    enable = true;
    openFirewall = false;
    host = "127.0.0.1";
  };
  systemd.services.flood.serviceConfig.SupplementaryGroups = ["rtorrent"];

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
        "-L \${RUNTIME_DIRECTORY}/rtorrent.sock:/home/bct/.rtorrent/rpc.sock bct@torrent.domus.diffeq.com"
      ];

      # Restart every >2 seconds to avoid StartLimitInterval failure
      RestartSec = 5;
      Restart = "always";

      DynamicUser = true;

      # this is the group that will own the socket
      Group = "rtorrent";
    };

    wantedBy = [ "multi-user.target" ];
  };

  programs.ssh.knownHosts = {
    "torrent.domus.diffeq.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPDMeXYu6wbZFx9ONThqwQKbK6/mq6hluZqIB6w0knqK";
  };

  services.nginx = {
    enable = true;
    group = "rtorrent";

    virtualHosts = {
      # https://github.com/jesec/flood/blob/69feefe2f97be8727de6bd2e35c6715f341aa15b/distribution/shared/nginx.md
      "flood.domus.diffeq.com" = {
        useACMEHost = "flood.domus.diffeq.com";
        forceSSL = true;

        root = "${config.services.flood.package}/lib/node_modules/flood/dist/assets";

        locations."/" = {
          tryFiles = "$uri /index.html";
        };

        locations."/api" = {
          proxyPass = "http://127.0.0.1:3000";
        };
      };

      # expose rtorrent XML-RPC over HTTP, adding authentication.
      rtorrent-xml-rpc = {
        serverName = "rtorrent.domus.diffeq.com";
        listen = [{ addr = "127.0.0.1"; port = 8888; }];

        basicAuthFile = config.age.secrets.rtorrent-xml-rpc-nginx-auth.path;

        locations."/RPC2" = {
          extraConfig = ''
            include ${config.services.nginx.package}/conf/scgi_params;
            scgi_pass unix:/run/rtorrent-socket/rtorrent.sock;
          '';
        };
      };

      "radarr.domus.diffeq.com" = {
        useACMEHost = "radarr.domus.diffeq.com";
        forceSSL = true;

        locations."/".proxyPass = "http://localhost:7878";
      };

      "sonarr.domus.diffeq.com" = {
        useACMEHost = "sonarr.domus.diffeq.com";
        forceSSL = true;

        locations."/".proxyPass = "http://localhost:8989";
      };
    };
  };
}
