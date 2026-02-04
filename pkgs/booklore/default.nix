# https://github.com/NixOS/nixpkgs/pull/425872/changes#diff-135ff8f5c186966e300bff4d762409c7ea3ec8c275e1924d3c8380ab63d5364a
{
  lib,
  stdenvNoCC,
  nixosTests,
  fetchFromGitHub,
  buildNpmPackage,
  gradle_8,
  makeWrapper,
  openjdk21,
}:
let
  version = "1.18.5";

  src = fetchFromGitHub {
    owner = "booklore-app";
    repo = "booklore";
    tag = "v${version}";
    hash = "sha256-6IJCtpkeqojfhJw/8zz1VfpIg37abmQlWjZ8sC2ceSY=";
  };

  webui = buildNpmPackage {
    pname = "booklore-ui";
    inherit version;

    src = src + "/booklore-ui";

    npmFlags = [ "--legacy-peer-deps" ];
    npmDepsHash = "sha256-5cpWoCBqoUpYY5Ru9YgoJuQN1zOCA2TLBkEfCOlcB+E=";

    installPhase = ''
      runHook preInstall

      cp -r dist/booklore/browser $out

      runHook postInstall
    '';
  };

  gradle = gradle_8.override {
    java = openjdk21;
    javaToolChains = [ openjdk21 ];
  };

  booklore = stdenvNoCC.mkDerivation (final: {
    pname = "booklore";
    inherit version;

    src = src + "/booklore-api";

    postPatch = ''
      substituteInPlace src/main/resources/application.yaml \
        --replace-fail "'/app/data'" "\''${BOOKLORE_DATA_DIR:/var/lib/booklore/data}" \
        --replace-fail "'/bookdrop'" "\''${BOOKLORE_BOOKDROP_DIR:/var/lib/booklore/bookdrop}" \
        --replace-fail "version: 'development'" "version: 'v${version}'"
    '';

    nativeBuildInputs = [
      gradle
      makeWrapper
    ];

    mitmCache = gradle.fetchDeps {
      inherit (final) pname;
      pkg = booklore;
      data = ./deps.json;
    };

    gradleBuildTask = "build";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/booklore-api
      cp build/libs/booklore-api-*-SNAPSHOT.jar $out/share/booklore-api/booklore-api.jar
      ln -s ${webui} $out/share/booklore-ui

      makeWrapper ${lib.getExe' openjdk21 "java"} $out/bin/booklore \
        --add-flags "-jar $out/share/booklore-api/booklore-api.jar"

      runHook postInstall
    '';

    passthru.tests = nixosTests.booklore;

    meta = {
      description = "Web app for hosting, managing, and exploring books, with support for PDFs, eBooks, reading progress, metadata, and stats";
      mainProgram = "booklore";
      homepage = "https://github.com/adityachandelgit/BookLore";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ jvanbruegge ];
      platforms = [ "x86_64-linux" ];
    };
  });
in
booklore
