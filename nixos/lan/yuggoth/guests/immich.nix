{ self, inputs, config, lib, pkgs, ... }:

let
  immich-nixpkgs = inputs.nixpkgs-immich;
in {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${immich-nixpkgs}/nixos/modules/services/web-apps/immich.nix"
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

    immich-env = {
      rekeyFile = ./secrets/immich-env.age;
      owner = config.services.immich.user;
      group = config.services.immich.group;
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
    in ["${automount_opts},cifsacl,uid=${config.services.immich.user},credentials=${config.age.secrets.fs-mi-go-immich.path}"];
  };

  services.immich = {
    enable = true;
    package = pkgs.unstable.immich;

    openFirewall = true;
    host = "0.0.0.0";

    mediaLocation = "/mnt/photos/immich";
    secretsFile = config.age.secrets.immich-env.path;

    database = {
      # use a remote postgres server
      enable = false;
      host = "db.domus.diffeq.com";
      port = 5432;
      user = "immich";
    };
  };
}
