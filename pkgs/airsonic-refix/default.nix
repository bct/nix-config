{
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpm,
  nodejs,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "airsonic-refix";

  # this is an official release, airsonic-refix has a very simple version scheme
  version = "f5a14e3f95814c13c95deb17c061635c9247401c";

  src = fetchFromGitHub {
    owner = "tamland";
    repo = "airsonic-refix";
    rev = finalAttrs.version;
    sha256 = "sha256-rLeapw7VJHywV3PkqNALQMKDFfW7H+a6I9YPspMc0Rg=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-25YoL5Kgjhway3LQn1LKu0mpgAyR4Xb/ZHW/KLB7hBw=";
  };

  nativeBuildInputs = [
    nodejs
    pnpm
    pnpmConfigHook
  ];

  # pnpmConfigHook installs with --ignore-scripts, but vue-demi won't work
  # unless its postinstall script is run. ("pnpm rebuild" doesn't do it: pnpm 11
  # ignores upstream's onlyBuiltDependencies setting.)
  preBuild = ''
    for d in node_modules/.pnpm/vue-demi@*/node_modules/vue-demi; do
      (cd "$d" && node scripts/postinstall.js)
    done
  '';

  buildPhase = ''
    runHook preBuild

    pnpm run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -R dist/ $out

    runHook postInstall
  '';
})
