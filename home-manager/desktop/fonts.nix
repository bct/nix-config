{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    ubuntu-classic
    nerd-fonts.ubuntu-mono
    dejavu_fonts
    corefonts

    # maybe prefer https://github.com/Soft/nix-google-fonts-overlay ?
    (pkgs.google-fonts.override {
      # https://fonts.google.com/
      fonts = [
        "Crimson Text"
        "IM Fell DW Pica SC"
        "IM Fell English"
        "IM Fell English SC"
        "Parisienne"
        "Sacramento"
        "UnifrakturMaguntia"
      ];
    })
  ];
}
