# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs }:
rec {
  # my fork of the Hoon LSP
  # https://github.com/bct/hoon-language-server/tree/fix-issue-30
  hoonLanguageServer =
    let
      hoonLsp = pkgs.fetchFromGitHub {
        #        owner  = "urbit";
        owner = "bct";
        repo = "hoon-language-server";
        rev = "89b2328796d6e1df41ec06534fd4f5b43af7c5a5";
        sha256 = "sha256-RN3dxJhFZeryNtEG9ZUOHziuYffHhUq+x2y+4lHsaYk=";
      };
    in
    pkgs.callPackage "${hoonLsp}/default.nix" { };

  hoon-crib =
    let
      repo = pkgs.fetchFromGitHub {
        owner = "bct";
        repo = "hoon-crib";
        rev = "d0e372e2a232450fb2e156f33511808a11aee012";
        sha256 = "sha256-eVnEQ4FQv4qICRn31+yCnemFrL43jAzS6dW0am+iFo0=";
      };
    in
    pkgs.callPackage "${repo}/default.nix" { };

  onkyo-ri-send-command =
    let
      pkg = pkgs.fetchFromGitHub {
        owner = "bct";
        repo = "onkyo-ri-send-command";
        rev = "bb662ef1d45357db0f205c0b8b8acf460b1bdae1";
        sha256 = "0d6mr08d1gvpghd440sgi3j0cz4xsrdcickdnv28in21xpj34a5z";
      };
    in
    pkgs.callPackage "${pkg}/default.nix" { };

  airsonic-refix = pkgs.callPackage ./airsonic-refix { };

  lego-acme-zoneedit = pkgs.callPackage ./lego-acme-zoneedit { };

  profilarr = pkgs.callPackage ./profilarr { };
  rtlamr = pkgs.callPackage ./rtlamr { };
  rtlamr-collect = pkgs.callPackage ./rtlamr-collect { };
  speedtest_exporter = pkgs.callPackage ./speedtest_exporter { };
  starlink_exporter = pkgs.callPackage ./starlink_exporter { };
  subsonic-action-proxy = pkgs.callPackage ./subsonic-action-proxy { };
  wgsd = pkgs.callPackage ./wgsd { };
}
