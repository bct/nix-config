{ lib
, fetchFromGitHub
, pkgs
}:

pkgs.buildGoModule rec {
  pname = "wgsd";
  version = "0.3.5";

  src = fetchFromGitHub {
    owner = "jwhited";
    repo = "wgsd";
    rev = "v${version}";
    sha256 = "sha256-mHB9QeRet/OlmdTKetu3O8jDAG2xWA2bS098jY9VpwU=";
  };

  vendorHash = "sha256-4K+k79igvlVTTMn1sIbcNTZLJiT7tXsH+epREyv5QiE=";

  meta = with lib; {
    description = "A CoreDNS plugin that provides WireGuard peer information via DNS-SD semantics, and a client for configuring WireGuard";
    homepage = "https://github.com/jwhited/wgsd";
    platforms = platforms.linux;
  };
}
