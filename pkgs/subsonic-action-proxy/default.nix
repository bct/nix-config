{ lib
, fetchFromGitHub
, pkgs
}:

pkgs.buildGoModule rec {
  pname = "subsonic-action-proxy";
  version = "87b1282a58acda855d1702d307ffc97a596749ad";

  src = fetchFromGitHub {
    owner = "bct";
    repo = "subsonic-action-proxy";
    rev = version;
    sha256 = "0gqa69879dlvgmzk6b0cz5cazp0al18bn8kvap698d6mw5fhqx5x";
  };

  vendorHash = "sha256-oXy9rgCRpuNHsqLW2sRylUamjPjOcHjC66noG4koLXk=";

  meta = with lib; {
    description = "Proxy that executes commands when certain Subsonic API methods are executed.";
    homepage = "https://github.com/bct/subsonic-action-proxy";
    platforms = platforms.linux;
  };
}
