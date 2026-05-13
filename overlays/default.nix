# This file defines overlays
{ inputs, ... }:
let
  unstable =
    final:
    import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
in
{
  # This one brings our custom packages from the 'pkgs' directory
  additions =
    final: _prev:
    import ../pkgs {
      pkgs = final;
    };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });

    # https://github.com/nix-community/home-manager/issues/5958#issuecomment-4370328706
    # can remove once bash-preexec is bumped past 0.6.0
    bash-preexec = prev.bash-preexec.overrideAttrs {
      src = prev.fetchFromGitHub {
        owner = "rcaloras";
        repo = "bash-preexec";
        rev = "35fead9f3442bed7d096332c7845223f5dbf7faa";
        hash = "sha256-NcZxx7k2OkaeLtN2Iiu/fbstAIAA0QYRDEt37HAH/mg=";
      };
    };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = (unstable final);
  };
}
