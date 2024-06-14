# Shell for working on nix configs.
# You can enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? (import ./nixpkgs.nix) { }, inputs ? {} }: {
  default = pkgs.mkShell {
    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    shellHook = "export PS1='\n\\[\\033[1;34m\\][nix-config:\\w]\$\\[\\033[0m\\] '";

    nativeBuildInputs = with pkgs; [ nixos-rebuild ];
  };

  nix-config = pkgs.mkShell {
    nativeBuildInputs = [
      inputs.agenix.packages.x86_64-linux.agenix
      inputs.deploy-rs.packages.x86_64-linux.deploy-rs
    ];
  };
}
