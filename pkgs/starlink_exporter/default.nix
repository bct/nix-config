{ lib, fetchFromGitHub, pkgs }:

pkgs.buildGoModule rec {
  pname = "starlink_exporter";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "DanMolz";
    repo = "starlink_exporter";
    rev = "v${version}";
    sha256 = "sha256-6YG4Tx/4llOUWE0NlLiZgZQqEH9pDBadizVJdzX3BQg=";
  };

  vendorHash = "sha256-VA3XAZVGhH9lIiag6D8INe24AhsmInVa9qvHWoRMr1A=";

  meta = with lib; {
    description = "Prometheus exporter that exposes metrics from SpaceX Starlink Dish";
    homepage = "https://github.com/danopstech/starlink_exporter";
    platforms = platforms.linux;
  };
}
