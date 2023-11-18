{ stdenv, fetchFromGitHub, fetchYarnDeps, fixup_yarn_lock, nodejs }:

# I couldn't get mkYarnPackage working (some strangeness with vue-demi imports)
# This is cribbed from https://github.com/NixOS/nixpkgs/blob/25b33e9c7040986ba1b3ae4c8873543f88b57258/pkgs/applications/misc/tandoor-recipes/frontend.nix
stdenv.mkDerivation rec {
  pname = "airsonic-refix";
  version = "bc4920fa57a20236ad7eef6f4483e50726b845c6";

  src = fetchFromGitHub {
    owner = "tamland";
    repo = "airsonic-refix";
    rev = version;
    sha256 = "sha256-Z0gvjpoWA9EfQP2M6WRn0Avcr4Mydk+mNO5RlJZ6YiE=";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-RjniI8ZVGv7i1ec6cR1ssm+wcVyO4nXOG7/rNwd6YLY=";
  };

  nativeBuildInputs = [
    fixup_yarn_lock
    nodejs
    nodejs.pkgs.yarn
  ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    yarn config --offline set yarn-offline-mirror "$yarnOfflineCache"
    fixup_yarn_lock yarn.lock
    command -v yarn
    yarn install --frozen-lockfile --offline --no-progress --non-interactive
    patchShebangs node_modules/

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    yarn --offline run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -R dist/ $out

    runHook postInstall
  '';
}
