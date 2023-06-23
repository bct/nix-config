args@{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    ./users.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "23.05";

  # add some swap to try to speed up nixos-rebuild
  swapDevices = [ { device = "/var/lib/swapfile"; size = 1*1024; } ];

  environment.systemPackages = [
    pkgs.vim
    pkgs.git
  ];

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
