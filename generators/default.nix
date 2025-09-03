{ inputs, outputs, nixpkgs, nixos-generators }: {
  headless-image-rpi = nixos-generators.nixosGenerate {
    system = "aarch64-linux";
    format = "sd-aarch64-installer";
    specialArgs = { inherit inputs outputs; };
    modules = [
      ../nixos/headless-images/rpi.nix
    ];
  };

  headless-image-cloud-x86_64-iso = nixos-generators.nixosGenerate {
    system = "x86_64-linux";
    format = "iso";
    specialArgs = { inherit inputs outputs; };
    modules = [
      ../nixos/headless-images/cloud-x86_64.nix
    ];
  };

  headless-image-cloud-x86_64-qcow2 = nixos-generators.nixosGenerate {
    system = "x86_64-linux";
    format = "qcow";
    specialArgs = { inherit inputs outputs; };
    modules = [
      "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
      ../nixos/headless-images/cloud-x86_64.nix
    ];
  };

  # NOTE: this is not working yet
  headless-image-cloud-x86_64 = nixos-generators.nixosGenerate {
    system = "x86_64-linux";
    format = "raw";
    specialArgs = { inherit inputs outputs; };
    modules = [
      "${nixpkgs}/nixos/modules/profiles/headless.nix"
      "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
      ../nixos/headless-images/cloud-x86_64.nix
    ];
  };
}
