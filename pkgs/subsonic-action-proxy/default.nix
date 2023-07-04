{ lib
, fetchFromGitHub
, pkgs
}:

pkgs.buildGoModule rec {
  pname = "subsonic-action-proxy";
  version = "19693984119451b5cbaeb1f0c54460d2f81f4b18";

  src = fetchFromGitHub {
    owner = "bct";
    repo = "subsonic-action-proxy";
    rev = version;
    sha256 = "0i8xr66ax37vy4g2xlyghbfk0v4dncylbnlz3sz68x253340n66c";
  };

  vendorHash = "sha256-oXy9rgCRpuNHsqLW2sRylUamjPjOcHjC66noG4koLXk=";

  meta = with lib; {
    description = "Proxy that executes commands when certain Subsonic API methods are executed.";
    homepage = "https://github.com/bct/subsonic-action-proxy";
    platforms = platforms.linux;
  };
}
