# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  # example = pkgs.callPackage ./example { };

  # my fork of the Hoon LSP
  # https://github.com/bct/hoon-language-server/tree/fix-issue-30
  hoonLanguageServer = let hoonLsp = pkgs.fetchFromGitHub {
#        owner  = "urbit";
      owner  = "bct";
      repo   = "hoon-language-server";
      rev    = "89b2328796d6e1df41ec06534fd4f5b43af7c5a5";
      sha256 = "sha256-RN3dxJhFZeryNtEG9ZUOHziuYffHhUq+x2y+4lHsaYk=";
    };
  in
    pkgs.callPackage "${hoonLsp}/default.nix" {};
}
