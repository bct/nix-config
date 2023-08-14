{ lib, pkgs, fetchFromGitHub }:

pkgs.stdenv.mkDerivation rec {
  name = "sxlock";
  version = "7db1929afb299ce3a52a8c776154f247bfa72f1f";

  src = fetchFromGitHub {
    owner = "lahwaacz";
    repo = "sxlock";
    rev = version;
    sha256 = "12103lp0b97w8lalf4xb9gk24yxwx69q3qhhvchyxcvghdczqf27";
  };

  buildInputs = with pkgs; [
    pam
    pkg-config
    xorg.libX11
    xorg.libXext
    xorg.libXft
    xorg.libXrandr
  ];

  configurePhase = ''
    substituteInPlace sxlock.c --replace sxlock xlock
  '';

  installPhase = ''
    install -Dm755 sxlock $out/bin/sxlock
  '';

  meta = with lib; {
    description = "Simple screen locker utility for X";
    homepage = "https://github.com/lahwaacz/sxlock";
    platforms = platforms.linux;
  };
}
