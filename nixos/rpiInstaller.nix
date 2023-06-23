args@{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ./users.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "23.05";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };
}
