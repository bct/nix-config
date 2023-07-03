{ lib
, fetchFromGitHub
, pkgs
}:

pkgs.buildGoModule rec {
  pname = "subsonic-action-proxy";
  version = "1ea245ac3801205370127d002cf4ad977df932d6";

  src = fetchFromGitHub {
    owner = "bct";
    repo = "subsonic-action-proxy";
    rev = version;
    sha256 = "0qqcja9xfp2d9bxdljvc27a20sq42kfks676xnklwia3mszlm7np";
  };

  vendorHash = "sha256-oXy9rgCRpuNHsqLW2sRylUamjPjOcHjC66noG4koLXk=";

  meta = with lib; {
    description = "Proxy that executes commands when certain Subsonic API methods are executed.";
    homepage = "https://github.com/bct/subsonic-action-proxy";
    platforms = platforms.linux;
  };
}
