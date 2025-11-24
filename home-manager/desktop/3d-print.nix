{ pkgs, ... }: {
  home.packages = [
    pkgs.unstable.cura-appimage
    pkgs.freecad
    pkgs.openscad
  ];
}
