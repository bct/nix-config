{

  # Based on the "minimal" config from https://github.com/Misterio77/nix-starter-configs
  description = "bct's nix config";

  nixConfig = {
    extra-substituters = [
      "https://microvm.cachix.org"
      "https://unmojang.cachix.org"
    ];
    extra-trusted-public-keys = [
      "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys="
      "unmojang.cachix.org-1:OfHnbBNduZ6Smx9oNbLFbYyvOWSoxb2uPcnXPj4EDQY="
    ];
  };

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # bug fixes & new packages
    shaunren-tinyauth.url = "github:shaunren/nixpkgs/tinyauth";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # flake-parts
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Agenix
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    agenix.inputs.darwin.follows = "";

    # agenix-rekey
    agenix-rekey.url = "github:oddlama/agenix-rekey";
    agenix-rekey.inputs.nixpkgs.follows = "nixpkgs";

    # deploy-rs
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-generators
    nixos-generators.url = "github:nix-community/nixos-generators";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";

    # disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # nixos-hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # microvm
    # doesn't follow nixpkgs, so that we can take advantage of the cache.
    microvm.url = "github:astro/microvm.nix";

    # nixvirt
    nixvirt.url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
    nixvirt.inputs.nixpkgs.follows = "nixpkgs";

    # simple-nixos-mailserver
    # https://nixos-mailserver.readthedocs.io/en/latest/index.html
    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-25.11";

    # minecraft
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    # packages from flakes
    airsonic-refix-jukebox.url = "github:bct/airsonic-refix-jukebox";
    airsonic-refix-jukebox.inputs.nixpkgs.follows = "nixpkgs";

    grid-select.url = "github:bct/grid-select";
    grid-select.inputs.nixpkgs.follows = "nixpkgs";

    fjord-launcher.url = "github:unmojang/FjordLauncher";
    drasl.url = "github:unmojang/drasl";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-parts,
      deploy-rs,
      nixos-generators,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.agenix-rekey.flakeModule
      ];

      systems = [
        "aarch64-linux"
        "x86_64-linux"

        # other systems that I'm not using right now:
        # "i686-linux"
        # "aarch64-darwin"
        # "x86_64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          # Your custom packages
          # Acessible through 'nix build', 'nix shell', etc
          packages =
            let
              inherit (self) outputs;
              generators = import ./generators {
                inherit
                  inputs
                  outputs
                  nixpkgs
                  nixos-generators
                  ;
              };
            in
            import ./pkgs { inherit pkgs; } // generators;

          # Devshell for working on configs
          # Acessible through 'nix develop'
          devShells = import ./shell.nix { inherit config pkgs inputs; };

          # agenix-rekey configuration
          # see https://flake.parts/options/agenix-rekey
          agenix-rekey.nodes =
            let
              # TODO: what if the hosts have overlapping VM names?
              allVms =
                self.nixosConfigurations.yuggoth.config.microvm.vms
                // self.nixosConfigurations.mi-go.config.microvm.vms;
              agenixVms =
                nixpkgs.lib.filterAttrs
                  # only look at VMs with "age" attributes set.
                  (containerName: { config, ... }: config.config ? age)
                  allVms;
            in
            {
              inherit (self.nixosConfigurations)
                aquilonia
                auth
                mail
                medley
                megahost-one
                mi-go
                ranger
                stereo
                yuggoth
                ;
            }
            // nixpkgs.lib.mapAttrs (containerName: instanceConfig: instanceConfig.config) agenixVms;
        };

      flake = {
        # Your custom packages and modifications, exported as overlays
        overlays = import ./overlays { inherit inputs; };

        # NixOS configuration entrypoint
        # Available through 'nixos-rebuild --flake .#your-hostname'
        nixosConfigurations =
          let
            inherit (self) outputs;
            injectDeps = {
              imports = [ ./nixos/common/injected-deps.nix ];
              config.diffeq.secretsPath = ./secrets;
            };
          in
          {
            # -- desktops
            aquilonia = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/aquilonia/configuration.nix
              ];
            };

            cimmeria = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/cimmeria/configuration.nix
              ];
            };

            stygia = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/stygia/configuration.nix
              ];
            };

            # -- LAN hosts
            auth = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/vms/auth/configuration.nix
              ];
            };

            mail = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/vms/mail/configuration.nix
              ];
            };

            mi-go = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/lan/mi-go/configuration.nix
              ];
            };

            medley = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/vms/medley/configuration.nix
              ];
            };

            ranger = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/vms/ranger/configuration.nix
              ];
            };

            stereo = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/lan/stereo/configuration.nix
              ];
            };

            yuggoth = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/lan/yuggoth/configuration.nix
              ];
            };

            # -- cloud hosts
            megahost-one = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit self inputs outputs; };
              modules = [
                injectDeps
                ./nixos/cloud/megahost-one/configuration.nix
              ];
            };
          };

        deploy =
          let
            mkNode =
              {
                hostname,
                arch,
                config,
              }:
              {
                inherit hostname;
                user = "root";
                profiles.system.path = deploy-rs.lib."${arch}".activate.nixos config;
              };
          in
          {
            # -- lan hosts --
            nodes.auth = mkNode {
              hostname = "auth.domus.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.auth;
            };

            nodes.mail = mkNode {
              hostname = "mail.domus.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.mail;
            };

            nodes.medley = mkNode {
              hostname = "medley.domus.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.medley;
            };

            nodes.mi-go = mkNode {
              hostname = "mi-go.domus.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.mi-go;
            };

            nodes.ranger = mkNode {
              hostname = "ranger.domus.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.ranger;
            };

            nodes.stereo = mkNode {
              hostname = "stereo.domus.diffeq.com";
              arch = "aarch64-linux";
              config = self.nixosConfigurations.stereo;
            };

            nodes.yuggoth = mkNode {
              hostname = "yuggoth.domus.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.yuggoth;
            };

            # -- cloud hosts --
            nodes.megahost-one = mkNode {
              hostname = "megahost-one.diffeq.com";
              arch = "x86_64-linux";
              config = self.nixosConfigurations.megahost-one;
            };
          };

        # Standalone home-manager configuration entrypoint
        # Available through 'home-manager --flake .#your-username@your-hostname'
        homeConfigurations =
          let
            inherit (self) outputs;
          in
          {
            "bct@aquilonia" = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
              extraSpecialArgs = { inherit inputs outputs; };
              modules = [ ./home-manager/aquilonia ];
            };

            "bct@cimmeria" = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
              extraSpecialArgs = { inherit inputs outputs; };
              modules = [ ./home-manager/cimmeria ];
            };

            "bct@stygia" = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
              extraSpecialArgs = { inherit inputs outputs; };
              modules = [ ./home-manager/stygia ];
            };
          };

        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      };
    };
}
