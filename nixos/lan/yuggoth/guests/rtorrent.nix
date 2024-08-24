{ inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 512;

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
    enable = true;
    user = "rtorrent";
    group = "rtorrent";
    downloadDir = "/mnt/video/downloads/rtorrent";
    configText = ''
    '';
  };

  # expose rtorrent XML-RPC over HTTP, adding authentication.
  networking.firewall.allowedTCPPorts = [ 8888 ];
  services.nginx = {
    enable = true;
    group = "rtorrent";

    httpConfig = ''
      server {
        listen 8888;
        auth_basic secured;
        auth_basic_user_file ${config.age.secrets.rtorrent-xml-rpc-nginx-auth.path};

        location /RPC2 {
          include ${config.services.nginx.package}/conf/scgi_params;
          scgi_pass unix:${config.services.rtorrent.rpcSocket};
        }
      }
    '';
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
