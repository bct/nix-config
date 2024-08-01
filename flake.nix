{
  # Based on the "minimal" config from https://github.com/Misterio77/nix-starter-configs
  description = "bct's nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Agenix
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.darwin.follows = "";

    # deploy-rs
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-generators
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # packages from flakes
    airsonic-refix-jukebox.url = "github:bct/airsonic-refix-jukebox";
    airsonic-refix-jukebox.inputs.nixpkgs.follows = "nixpkgs";

    unshittify.url = "github:bct/unshittify.nix";
    unshittify.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, agenix, deploy-rs, nixos-generators, ... }@inputs:
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
          pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          generators = import ./generators { inherit inputs outputs nixpkgs nixos-generators; };
        in import ./pkgs { inherit pkgs pkgs-unstable; } // generators
      );

      # Devshell for working on configs
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs inputs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # -- desktops
        cimmeria = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/cimmeria/configuration.nix ];
        };

        dunwich = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/dunwich/configuration.nix ];
        };

        # -- LAN hosts
        spectator = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/lan/spectator/configuration.nix ];
        };

        stereo = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/lan/stereo/configuration.nix ];
        };

        yuurei = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/lan/yuurei/configuration.nix ];
        };

        # -- cloud hosts
        megahost-one = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit self inputs outputs; };
          modules = [ ./nixos/cloud/megahost-one/configuration.nix ];
        };
      };

      deploy = let
        mkNode = { hostname, arch, config }: {
          inherit hostname;
          user = "root";
          profiles.system.path = deploy-rs.lib."${arch}".activate.nixos config;
        };
      in {
        # -- lan hosts --
        nodes.spectator = mkNode {
          hostname = "spectator.domus.diffeq.com";
          arch     = "aarch64-linux";
          config   = self.nixosConfigurations.spectator;
        };

        nodes.stereo = mkNode {
          hostname = "stereo.domus.diffeq.com";
          arch     = "aarch64-linux";
          config   = self.nixosConfigurations.stereo;
        };

        nodes.yuurei = mkNode {
          hostname = "yuurei.domus.diffeq.com";
          arch     = "x86_64-linux";
          config   = self.nixosConfigurations.yuurei;
        };

        # -- cloud hosts --
        nodes.megahost-one = mkNode {
          hostname = "megahost-one.diffeq.com";
          arch     = "x86_64-linux";
          config   = self.nixosConfigurations.megahost-one;
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

        "brendan@dunwich" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [./home-manager/dunwich];
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
