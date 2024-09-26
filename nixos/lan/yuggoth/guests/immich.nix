{ self, config, lib, pkgs, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 2;
    mem = 4096;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  age.rekey.hostPubkey = lib.mkIf (builtins.pathExists ../../../../secrets/ssh/host-immich.pub) ../../../../secrets/ssh/host-immich.pub;
  age.secrets = {
    fs-mi-go-immich = {
      rekeyFile = ../../../../secrets/fs/mi-go-immich.age;
    };
  };

  fileSystems."/mnt/photos" = {
    device = "//mi-go.domus.diffeq.com/photos";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},cifsacl,uid=immich,credentials=${config.age.secrets.fs-mi-go-immich.path}"];
  };

  # TODO: remove this once service.immich is enabled
  users.users = {
    immich = {
      name = "immich";
      group = "immich";
      isSystemUser = true;
    };
  };
  users.groups = { immich = { }; };
}
