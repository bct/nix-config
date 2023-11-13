{
  # Based on the "minimal" config from https://github.com/Misterio77/nix-starter-configs
  description = "bct's nix config";

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
        "x86_64-linux"

        # other systems that I'm not using right now:
        # "i686-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];
    in
    {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          generators = import ./generators { inherit inputs outputs nixpkgs nixos-generators; };
        in import ./pkgs { inherit pkgs; } // generators
      );

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
        cimmeria = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/cimmeria/configuration.nix ];
        };

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

        viator = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/cloud/viator/configuration.nix ];
        };
      };

      deploy = let
        mkNode = { hostname, path }: {
          inherit hostname;
          user = "root";
          profiles.system.path = path;
        };
      in {
        # -- lan hosts --
        nodes.spectator = mkNode {
          hostname = "spectator.domus.diffeq.com";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.spectator;
        };

        nodes.stereo = mkNode {
          hostname = "stereo.domus.diffeq.com";
          path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.stereo;
        };

        # -- cloud hosts --
        nodes.notes = mkNode {
          hostname = "notes.diffeq.com";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.notes;
        };

        nodes.s3-proxy = mkNode {
          hostname = "s3-proxy.diffeq.com";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.s3-proxy;
        };

        nodes.viator = mkNode {
          hostname = "viator.diffeq.com";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.viator;
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        "bct@cimmeria" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [./home-manager/cimmeria];
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
