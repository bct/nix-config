{ outputs, pkgs, ... }:
{
  nix = {
    package = pkgs.nix;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
    };
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];

    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);

      # temporary until 26.05 is out
      permittedInsecurePackages = [
        "python3.13-beets-2.5.1"
      ];
    };
  };

  # allow using unfree packages with nix-shell, `nix run`, etc.
  xdg.configFile."nixpkgs/config.nix".text = ''
    { allowUnfree = true; }
  '';
}
