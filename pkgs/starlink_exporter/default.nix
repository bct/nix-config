{ lib, fetchFromGitHub, pkgs }:

pkgs.buildGoModule rec {
  pname = "starlink_exporter";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "DanMolz";
    repo = "starlink_exporter";
    rev = "v${version}";
    sha256 = "sha256-Z61FC/BkxmYsRRG1Jw905JKK98R3eguVZWxp5IYmpnM=";
  };

  vendorHash = "sha256-1265IxM43+FzNqSSqPke3GraZnJwu04A7oe9SUSWKJA=";

  meta = with lib; {
    description = "Prometheus exporter that exposes metrics from SpaceX Starlink Dish";
    homepage = "https://github.com/danopstech/starlink_exporter";
    platforms = platforms.linux;
  };
}
