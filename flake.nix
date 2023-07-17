{
  # Based on the "minimal" config from https://github.com/Misterio77/nix-starter-configs
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Agenix
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";

    # deploy-rs
    deploy-rs.url = "github:serokell/deploy-rs";

    # nixos-generators
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    # hardware.url = "github:nixos/nixos-hardware";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, home-manager, agenix, deploy-rs, nixos-generators, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      ) // {
        # is it correct that this is only other the one system?
        x86_64-linux = {
          headless-image-rpi = nixos-generators.nixosGenerate {
            system = "aarch64-linux";
            format = "sd-aarch64-installer";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixos/headless-images/rpi.nix
            ];
          };

          headless-image-cloud-x86_64-iso = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "iso";
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./nixos/headless-images/cloud-x86_64.nix
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
              ./nixos/headless-images/cloud-x86_64.nix
            ];
          };
        };
      };

      # Devshell for working on configs
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        notes = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/cloud/notes/configuration.nix ];
        };

        spectator = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/lan/spectator/configuration.nix ];
        };

        stereo = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/lan/stereo/configuration.nix ];
        };

        s3-proxy = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/cloud/s3-proxy/configuration.nix ];
        };
      };

      deploy.nodes.spectator = {
        hostname = "spectator.domus.diffeq.com";
        user = "root";

        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.spectator;
        };
      };

      deploy.nodes.stereo = {
        hostname = "stereo.domus.diffeq.com";
        user = "root";

        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.stereo;
        };
      };

      deploy.nodes.s3-proxy = {
        hostname = "s3-proxy.diffeq.com";
        user = "root";

        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.s3-proxy;
        };
      };

      deploy.nodes.notes = {
        hostname = "notes.diffeq.com";
        user = "root";

        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.notes;
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "bct@cimmeria" = home-manager.lib.homeManagerConfiguration {
           pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
           extraSpecialArgs = { inherit inputs outputs; }; # Pass flake inputs to our config
           # > Our main home-manager configuration file <
           modules = [ ./home-manager/desktop ];
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
