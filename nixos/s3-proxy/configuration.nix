{ config, lib, pkgs, ... }: {
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

  services.minio = {
    enable = true;
    rootCredentialsFile = config.age.secrets.s3-proxy-minio-root-credentials.path;
  };

  services.caddy = {
    enable = true;

    virtualHosts."console.s3.escam.biz".extraConfig = ''
      reverse_proxy localhost:9001
    '';

    virtualHosts."s3.escam.biz" = {
      serverAliases = [ "mosfet-novpet.s3.escam.biz" ];
      extraConfig = ''
        reverse_proxy localhost:9000
      '';
    };
  };

  age.secrets = {
    s3-proxy-minio-root-credentials = {
      file = ../../secrets/s3-proxy-minio-root-credentials.age;
      owner = "minio";
      group = "minio";
      mode = "600";
    };
  };
}
