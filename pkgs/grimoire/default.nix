{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  python3,
  makeWrapper,
  stdenv,
}:
let
  version = "1.8.0";
  src = fetchFromGitHub {
    owner = "hunter-read";
    repo = "grimoire";
    rev = "v${version}";
    hash = "sha256-UXuy2NqbveI669wJWEm51m0mbrHQmHvL7nmfTouhjwg=";
  };

  frontend = buildNpmPackage {
    pname = "grimoire-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";

    npmDepsHash = "sha256-p9FkYCQT/7edTxqBIVRhrhbPwPpDfJu2Lf5BEWo8auc=";

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

  python = python3.withPackages (
    ps: with ps; [
      fastapi
      uvicorn
      sqlalchemy
      alembic
      aiosqlite
      pymupdf
      python-multipart
      watchdog
      httpx
      pillow
      pydantic
      passlib
      bcrypt
      pyjwt
      authlib
      redis
      slowapi
      markdownify
      mutagen
      rarfile
      py7zr
      striprtf
      pytesseract
      pathspec
      tzdata
      pyyaml
    ]
  );
in
stdenv.mkDerivation {
  pname = "grimoire";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  # backend/file_cache.py imports starlette's private md5_hexdigest helper,
  # which newer starlette (nixpkgs is currently on 1.1, grimoire was built
  # against ~0.41) dropped. It was only ever a FIPS-safe wrapper around
  # hashlib.md5(usedforsecurity=False), so inline that instead of pinning
  # starlette/fastapi to older versions.
  postPatch = ''
        substituteInPlace backend/file_cache.py \
          --replace-fail \
            "from starlette.responses import md5_hexdigest" \
            "from hashlib import md5 as _md5

    def md5_hexdigest(data: bytes, *, usedforsecurity: bool = True) -> str:
        return _md5(data, usedforsecurity=usedforsecurity).hexdigest()"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/grimoire
    cp -r backend $out/share/grimoire/backend
    cp alembic.ini VERSION CHANGELOG.md $out/share/grimoire/

    mkdir -p $out/share/grimoire/frontend
    cp -r ${frontend} $out/share/grimoire/frontend/dist

    makeWrapper ${python}/bin/python $out/bin/grimoire \
      --chdir "$out/share/grimoire" \
      --add-flags "-m uvicorn backend.main:app --host 0.0.0.0 --port 9481"

    runHook postInstall
  '';

  passthru = {
    inherit python frontend;
  };

  meta = {
    description = "Self-hosted web app for your tabletop RPG library";
    homepage = "https://github.com/hunter-read/grimoire";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "grimoire";
  };
}
