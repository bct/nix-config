{ self, inputs, pkgs, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko

    "${self}/nixos/common/nix.nix"
    "${self}/nixos/common/headless.nix"

    "${self}/nixos/hardware/vultr"

    ./disk-config.nix
    ./coredns-wgsd.nix
    ./wireguard.nix

    ./static-site.nix

    (
      import ./minio-instance.nix (
        {
          containerName = "minio-escam-biz";
          minioDomain = "s3.escam.biz";
          buckets = [ "mosfet-novpet" ];
          hostAddress6 = "fc00::1";
          containerAddress6 = "fc00::f1";
        }
      )
    )

    (
      import ./minio-instance.nix (
        {
          containerName = "minio-diffeq-com";
          minioDomain = "s3.diffeq.com";
          buckets = [ "zardoz" "middel-salbyt" ];
          hostAddress6 = "fc00::2";
          containerAddress6 = "fc00::f2";
        }
      )
    )
  ];

  # we'll configure these using disko.
  hardware.vultr.useSwapFile = false;
  hardware.vultr.setUpDisk = false;

  networking.hostName = "megahost-one";

  time.timeZone = "Etc/UTC";

  system.stateVersion = "24.05";
}
