{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkgs
}:

pkgs.buildGoModule rec {
  pname = "rtlamr-collect";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "bemasher";
    repo = "rtlamr-collect";
    rev = "v${version}";
    sha256 = "16p0bgrdlc49jz424mfjqh1bj5f51ap3nmz1v2kfl4qmwg8y1rzd";
  };

  vendorHash = "sha256-aUuKZaE31PSxJSvvJ+Ag0LXNewYLAC3nuuDV9sLUpJU=";

  meta = with lib; {
    description = "Data aggregation for rtlamr.";
    homepage = "https://github.com/bemasher/rtlamr-collect";
    platforms = platforms.linux;
  };
}
