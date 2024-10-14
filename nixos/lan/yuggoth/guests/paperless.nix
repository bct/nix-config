{ self, config, ... }: {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 2;
    mem = 2000;

    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 1024;
      }
    ];
  };

  services.paperless = {
    enable = true;
    mediaDir = "/mnt/paperless/media";
    consumptionDir = "/mnt/paperless/consume";

    address = "0.0.0.0";
  };

  networking.firewall.allowedTCPPorts = [
    config.services.paperless.port
  ];

  age.secrets = {
    fs-mi-go-paperless = {
      rekeyFile = ../../../../secrets/fs/mi-go-paperless.age;
    };
  };

  fileSystems."/mnt/paperless" = {
    device = "//mi-go.domus.diffeq.com/paperless";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

    # the defaults of a CIFS mount are not documented anywhere that I can see.
    # you can run "mount" after mounting to see what options were actually used.
    # cifsacl is required for the server-side permissions to show up correctly.
    in ["${automount_opts},cifsacl,uid=${config.services.paperless.user},credentials=${config.age.secrets.fs-mi-go-paperless.path}"];
  };
}
