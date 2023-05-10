{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkgs
}:

pkgs.buildGoModule rec {
  pname = "rtlamr";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "bemasher";
    repo = "rtlamr";
    rev = "v${version}";
    sha256 = "1i36m8sh35jlwjf1fkmm9fzw6jg5c3909l1rm68n0kph9wnrzfyh";
  };

  vendorHash = "sha256-uT6zfsWgIot0EMNqwtwJNFXN/WaAyOGfcYJjuyOXT4g=";

  meta = with lib; {
    description = "An rtl-sdr receiver for Itron ERT compatible smart meters operating in the 900MHz ISM band";
    homepage = "https://github.com/bemasher/rtlamr";
    platforms = platforms.linux;
  };
}
