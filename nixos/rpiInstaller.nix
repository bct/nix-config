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
}
