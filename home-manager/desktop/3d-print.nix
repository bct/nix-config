{ pkgs, ... }:
let
  # Make the UI big enough to be usable. I'm not sure why it doesn't use the same
  # settings as everything else on Wayland. I'm sure there's a better way to do this!
  orca-slicer = pkgs.symlinkJoin {
    name = "orca-slicer-wrapped";
    paths = [ pkgs.orca-slicer ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/orca-slicer \
        --set GDK_SCALE 2
    '';
  };
in
{
  home.packages = [
    pkgs.unstable.cura-appimage
    pkgs.freecad
    pkgs.openscad

    orca-slicer
  ];
}
