{ self, inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"

    ./disk-config.nix
    ./coredns-wgsd.nix
    ./minio-instance.nix
    ./postgres.nix
    ./goatcounter.nix
    ./wiki.nix
    ./wireguard-viator.nix
    ./wireguard-conductum.nix

    ./static-site.nix

    ./borgmatic.nix
  ];

  # we'll configure these using disko.
  hardware.vultr.useSwapFile = false;
  hardware.vultr.setUpDisk = false;

  networking.hostName = "megahost-one";

  time.timeZone = "Etc/UTC";

  age.secrets = {
    s3-proxy-minio-root-credentials = {
      file = ../../../secrets/s3-proxy-minio-root-credentials.age;
      mode = "600";
    };
  };

  megahost.minio = {
    enable = true;
    instances = {
      "minio-escam-biz" = {
        minioDomain = "s3.escam.biz";
        buckets = [ "mosfet-novpet" ];
        hostAddress6 = "fc00::1";
        containerAddress6 = "fc00::f1";
        rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
      };

      "minio-diffeq-com" = {
        minioDomain = "s3.diffeq.com";
        buckets = [ "zardoz" "middel-salbyt" ];
        hostAddress6 = "fc00::2";
        containerAddress6 = "fc00::f2";
        rootCredentialsPath = config.age.secrets.s3-proxy-minio-root-credentials.path;
      };
    };
  };


  system.stateVersion = "24.05";
}
