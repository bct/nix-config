{
  inputs,
  outputs,
  nixpkgs,
}:
{
  headless-image-rpi =
    (nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        ../nixos/headless-images/rpi.nix
      ];
    }).config.system.build.images.sd-card;

  headless-image-cloud-x86_64-iso =
    (nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        ../nixos/headless-images/cloud-x86_64.nix
      ];
    }).config.system.build.images.iso;

  headless-image-cloud-x86_64-qcow2 =
    (nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
        ../nixos/headless-images/cloud-x86_64.nix
      ];
    }).config.system.build.images.qcow;

  # NOTE: this is not working yet
  headless-image-cloud-x86_64 =
    (nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs outputs; };
      modules = [
        "${nixpkgs}/nixos/modules/profiles/headless.nix"
        "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
        ../nixos/headless-images/cloud-x86_64.nix
      ];
    }).config.system.build.images.raw;
}
