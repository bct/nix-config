args@{ self, inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    ./hardware-configuration.nix

    (
      import ./minio-instance.nix (
        args
        // {
          containerName = "minio-escam-biz";
          minioDomain = "s3.escam.biz";
          buckets = [ "mosfet-novpet" ];
          hostAddress6 = "fc00::1";
          containerAddress6 = "fc00::f1";
          rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
        }
      )
    )

    (
      import ./minio-instance.nix (
        args
        // {
          containerName = "minio-diffeq-com";
          minioDomain = "s3.diffeq.com";
          buckets = [ "zardoz" "middel-salbyt" ];
          hostAddress6 = "fc00::2";
          containerAddress6 = "fc00::f2";
          rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
        }
      )
    )
  ];

  boot.loader.grub.device = "/dev/vda";

  networking.hostName = "s3-proxy";
  networking.networkmanager.enable = true;

  time.timeZone = "Etc/UTC";

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "23.05";

  networking.nat = {
    enable = true;
    internalInterfaces = ["ve-+"];
    externalInterface = "ens3";
    # Lazy IPv6 connectivity for the container
    enableIPv6 = true;
  };

  age.secrets = {
    s3-proxy-minio-root-credentials = {
      file = ../../../secrets/s3-proxy-minio-root-credentials.age;
      mode = "600";
    };
  };
}
