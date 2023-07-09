{ config, ... }: {
  imports = [
    ../common/nix.nix
    ../common/headless.nix

    ./hardware-configuration.nix
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "s3-proxy";
  networking.networkmanager.enable = true;

  time.timeZone = "Etc/UTC";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.05";

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "ens3";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  containers.minio-escam-biz = {
    autoStart = true;
    privateNetwork = true;

    bindMounts = {
      "/tmp/minio-root-credentials" = {
        hostPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
        isReadOnly = true;
     };
    };

    hostAddress6 = "fc00::1";
    localAddress6 = "fc00::f1";

    config = { config, pkgs, ... }: {
      system.stateVersion = "23.05";

      networking.firewall.allowedTCPPorts = [ 9000 9001 ];

      services.minio = {
        enable = true;
        rootCredentialsFile = "/tmp/minio-root-credentials";
      };
      systemd.services.minio.environment.MINIO_DOMAIN = "s3.escam.biz";
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."console.s3.escam.biz".extraConfig = ''
      reverse_proxy [fc00::f1]:9001
    '';

    virtualHosts."s3.escam.biz" = {
      serverAliases = [ "mosfet-novpet.s3.escam.biz" ];
      extraConfig = ''
        reverse_proxy [fc00::f1]:9000
      '';
    };

    virtualHosts."console.s3.diffeq.com".extraConfig = ''
      reverse_proxy [fc00::f2]:9001
    '';

    virtualHosts."s3.diffeq.com" = {
      serverAliases = [ "zardoz.s3.diffeq.com" ];
      extraConfig = ''
        reverse_proxy [fc00::f2]:9000
      '';
    };
  };

  age.secrets = {
    s3-proxy-minio-root-credentials = {
      file = ../../secrets/s3-proxy-minio-root-credentials.age;
      mode = "600";
    };
  };
}
