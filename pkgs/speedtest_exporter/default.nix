{ lib, fetchFromGitHub, pkgs }:

pkgs.buildGoModule rec {
  pname = "speedtest_exporter";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "danopstech";
    repo = "speedtest_exporter";
    rev = "v${version}";
    sha256 = "sha256-v7FdjWdGMhzXr5dPpiRW/vWMnKT+O+h1I/BE+ArDjU8=";
  };

  vendorHash = "sha256-w113vWnXM4h3zckmj39Qx/oZFaH9Mq0xUSqNxopdQO0=";

  meta = with lib; {
    description = "Prometheus exporter that runs speedtest and exposes results";
    homepage = "https://github.com/danopstech/speedtest_exporter";
    platforms = platforms.linux;
  };
}
