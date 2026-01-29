# https://github.com/upidapi/declarr/blob/3b357b436326f58d5baba1fc45e30c9b00c74839/nix/declarr.nix
{
  python3,
  fetchFromGitHub,
  stdenv,
  nodejs,
  buildNpmPackage,
}:
let
  version = "1.1.3";
  src = fetchFromGitHub {
    owner = "Dictionarry-Hub";
    repo = "profilarr";
    rev = "v${version}";
    hash = "sha256-aYYfMJSN76h625j/pda0G93de+c21wGIxYaeylVfq98=";
  };

  frontend = buildNpmPackage (finalAttrs: {
    inherit src version;

    pname = "profilarr-frontend";
    sourceRoot = "source/frontend";

    npmDepsHash = "sha256-xuHloznlWL9e90dfqSPQ0OA/unjSYh60+zSYGYTWOtc=";

    installPhase = ''
      cp -r dist $out
    '';
  });
  python = python3;
in
python3.pkgs.buildPythonPackage {
  inherit src version;

  pname = "profilarr";
  pyproject = true;

  unpackPhase = ''
    cp -r ${src}/backend/app ./profilarr
  '';
  postPatch = ''
    substituteInPlace profilarr/main.py \
      --replace "static_folder='static'" "static_folder='${frontend}'"

    # boo, hardcoded docker path
    substituteInPlace profilarr/config/config.py \
      --replace "/config" "."

    # we've renamed the module, maybe that was a bad choice
    substituteInPlace profilarr/db/migrations/runner.py \
      --replace "app.db.migrations" "profilarr.db.migrations"

    cat >> pyproject.toml <<EOF
      [build-system]
      requires = ["setuptools>=42","wheel"]
      build-backend = "setuptools.build_meta"


      [project]
      name = "profilarr"
      version = "${version}"
      dependencies = []

      [tool.setuptools.packages.find]
      include = ["profilarr*"]
    EOF
  '';

  nativeBuildInputs = with python3.pkgs; [
    setuptools
  ];

  dependencies =
    with python3.pkgs;
    [
      flask
      flask-cors
      apscheduler
      aiohttp
      pyyaml
      requests
      gitpython
      regex
    ]
    ++ (with pkgs; [
      pkgs.jellyseerr
    ]);

  pythonImportsCheck = [
    "profilarr"
  ];

  passthru = {
    inherit python frontend;
  };

  meta = {
    description = "";
  };
}
