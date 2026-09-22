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

    # TODO(unstable): revert to stable for bash-preexec >= 0.7.0
    # https://github.com/nix-community/home-manager/issues/5958
    bash-preexec = final.unstable.bash-preexec;

    # TODO(unstable): revert to stable for pkgs.rahasher
    # romm's NixOS module (imported from nixpkgs-unstable, since it isn't in
    # our pinned nixpkgs yet) references pkgs.rahasher directly, which only
    # exists in nixpkgs-unstable.
    rahasher = final.unstable.rahasher;
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = (unstable final);
  };
}
