# https://github.com/tomasharkema/nix-config/blob/110dd43edc84675c1d48c060e307a4eb1c0bfbf9/packages/brscan-skey/default.nix
{
  stdenv,
  dpkg,
  autoPatchelfHook,
  brscan5,
  sane-backends,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "brscan-skey";
  version = "0.3.4-0";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf006652/brscan-skey-${version}.amd64.deb";
    sha256 = "sha256-Y2D35vu1XdqdzQWgMNyhLlb42M4Dd9SoNilwhPXOqJE=";
  };

  nativeBuildInputs = [dpkg autoPatchelfHook sane-backends];
  buildInputs = [brscan5 sane-backends];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib}

    # binary is hardcoded to look for config in /opt/brother/scanner/brscan-skey/brscan-skey.config
    # patch it to look at /etc/brother/scanner/brscan-skey/brscan-skey.config instead.
    # then we can provide it with nixos `environment.etc`
    #
    # to find offsets:
    #     strings -t d brscan-skey-exe  | grep brscan-skey.config
    printf '/etc' | dd of=opt/brother/scanner/brscan-skey/brscan-skey-exe bs=1 seek=82304 conv=notrunc
    printf '/etc' | dd of=opt/brother/scanner/brscan-skey/brscan-skey-exe bs=1 seek=86512 conv=notrunc
    printf '/etc' | dd of=opt/brother/scanner/brscan-skey/brscan-skey-exe bs=1 seek=92480 conv=notrunc

    cp -r opt/brother/scanner/brscan-skey/* $out/lib/
    cp opt/brother/scanner/brscan-skey/brscan-skey $out/bin/

    substituteInPlace $out/bin/brscan-skey \
      --replace-fail "/opt/brother/scanner/brscan-skey" "$out/lib"

    substituteInPlace $out/lib/script/scantofile.sh \
      --replace-fail "/opt/brother/scanner/brscan-skey/skey-scanimage" "$out/lib/skey-scanimage"

    substituteInPlace "$out/lib/brscan-skey.config" \
      --replace-fail "/opt/brother/scanner/brscan-skey" "$out/lib"
    #substituteInPlace "$out/lib/brscan_mail.config" \
    #  --replace-fail "/opt/brother/scanner/brscan-skey" "$out/lib"
    # substituteInPlace "$out/lib/scantoemail.config" \
    #   --replace-fail "/opt/brother/scanner/brscan-skey" "$out/lib"
    # substituteInPlace "$out/lib/scantofile.config" \
    #   --replace-fail "/opt/brother/scanner/brscan-skey" "$out/lib"
    # substituteInPlace "$out/lib/scantoimage.config" \
    #   --replace-fail "/opt/brother/scanner/brscan-skey" "$out/lib"

    runHook postInstall
  '';
}
