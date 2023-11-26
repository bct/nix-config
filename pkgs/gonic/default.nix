{ lib, stdenv, buildGo121Module, fetchFromGitHub
, nixosTests
, pkg-config, taglib, zlib

# Disable on-the-fly transcoding,
# removing the dependency on ffmpeg.
# The server will (as of 0.11.0) gracefully fall back
# to the original file, but if transcoding is configured
# that takes a while. So best to disable all transcoding
# in the configuration if you disable transcodingSupport.
, transcodingSupport ? true, ffmpeg
, mpv }:

buildGo121Module rec {
  pname = "gonic";
  version = "0.16.1";
  src = fetchFromGitHub {
    owner = "sentriz";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-WkkuskGuvKq59qJJqkjvEBx+THDQtU/K0SuLYimxF9w=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ taglib zlib ];
  vendorHash = "sha256-R3ocp4lIcd2zJnKYw26t9+mVWsino1bOU//FARcEUnA=";

  # TODO(Profpatsch): write a test for transcoding support,
  # since it is prone to break
  postPatch = lib.optionalString transcodingSupport ''
    substituteInPlace \
      transcode/transcode.go \
      --replace \
        '`ffmpeg' \
        '`${lib.getBin ffmpeg}/bin/ffmpeg'
  '' + ''
    substituteInPlace \
      jukebox/jukebox.go \
      --replace \
        '"mpv"' \
        '"${lib.getBin mpv}/bin/mpv"'
  '';

  # a bunch of irrelevant failures - audio/flac vs audio/x-flac
  doCheck = false;

  passthru = {
    tests.gonic = nixosTests.gonic;
  };

  meta = {
    homepage = "https://github.com/sentriz/gonic";
    description = "Music streaming server / subsonic server API implementation";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux;
  };
}
