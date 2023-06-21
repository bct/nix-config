# Shell for working on nix configs.
# You can enter it through 'nix develop' or (legacy) 'nix-shell'

{ pkgs ? (import ./nixpkgs.nix) { } }: {
  default = pkgs.mkShell {
    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    nativeBuildInputs = with pkgs; [ nixos-generators nixos-rebuild ];
    shellHook = "export PS1='\n\\[\\033[1;34m\\][nix-config:\\w]\$\\[\\033[0m\\] '";
  };
}
