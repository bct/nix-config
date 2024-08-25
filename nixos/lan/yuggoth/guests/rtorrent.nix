{ inputs, config, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 1024;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 512;
      }
    ];
  };

  users.groups = {
    video-writers = {};
    rtorrent = {};
  };

  users.users = {
    rtorrent = {
      isSystemUser = true;
      group = "rtorrent";
      extraGroups = ["video-writers"];
    };
    bct.extraGroups = ["video-writers"];
  };

  services.rtorrent = {
    enable = false;
    user = "rtorrent";
    group = "rtorrent";
    downloadDir = "/mnt/video/downloads/rtorrent";
    configText = ''
    '';
  };

  networking.firewall.allowedTCPPorts = [
    # flood
    80

    # rtorrent xml-rpc
    8888
  ];

  services.nginx = {
    enable = true;
    group = "rtorrent";

    virtualHosts = {
      # https://github.com/jesec/flood/blob/69feefe2f97be8727de6bd2e35c6715f341aa15b/distribution/shared/nginx.md
      flood = {
        serverName = "rtorrent.domus.diffeq.com";
        listen = [{ addr = "0.0.0.0"; port = 80; }];
        root = "${pkgs.flood}/lib/node_modules/flood/dist/assets";

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
        listen = [{ addr = "0.0.0.0"; port = 8888; }];

        basicAuthFile = config.age.secrets.rtorrent-xml-rpc-nginx-auth.path;

        locations."/RPC2" = {
          extraConfig = ''
            include ${config.services.nginx.package}/conf/scgi_params;
            scgi_pass unix:${config.services.rtorrent.rpcSocket};
          '';
        };
      };
    };
  };

  systemd.services.flood = {
    enable = true;
    description = "Flood rTorrent Web UI";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.nodePackages.flood}/bin/flood --host 127.0.0.1 --port 3000";
      User = config.services.rtorrent.user;
      Group = config.services.rtorrent.group;
    };

    wantedBy = [ "multi-user.target" ];
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
    in ["${automount_opts},cifsacl,uid=rtorrent,gid=video-writers,credentials=${config.age.secrets.smb-fs-mi-go-rtorrent.path}"];
  };

  age.secrets = {
    smb-fs-mi-go-rtorrent = {
      rekeyFile = ../../../../secrets/fs/smb-mi-go-rtorrent.age;
    };

    rtorrent-xml-rpc-nginx-auth = {
      rekeyFile = ./secrets/rtorrent-xml-rpc-nginx-auth.age;
      owner = config.services.nginx.user;
      group = config.services.nginx.group;
    };
  };

  age.rekey = {
    masterIdentities = ["/home/bct/.ssh/id_rsa"];
    storageMode = "local";
    localStorageDir = ../../../.. + "/secrets/rekeyed/rtorrent";

    # TODO: pull from the .pub on disk?
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZkZL3circBd15wefqQULLEQSJeKwLXugzgAg702uo0 root@rtorrent";
  };
}
