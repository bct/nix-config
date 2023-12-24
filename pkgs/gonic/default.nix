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
  version = "f5b6b4d7906292f28f02aa7604cd45a8fcab720f";
  src = fetchFromGitHub {
    owner = "sentriz";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-r+HhRNNn1fdOF95ASipyPrvAAEqYug7xqjHvXSgPzD0=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ taglib zlib ];
  vendorHash = "sha256-oLWpb2WxR3Ch57jBVD72y7M0ON8oLnxfMI7dp6tqq08=";

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
