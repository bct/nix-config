# https://github.com/NixOS/nixpkgs/pull/527482
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  udev,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "usbeehive";
  version = "0.12.1";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "abrauchli";
    repo = "usbeehive";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zaGUIs/A6UXlsK8uSsMrsdTzQFfCDpsEmJB+lz2O7Pg=";
  };

  cargoHash = "sha256-4JO9WaVYvBBCt3hVdigMhXrtVOM5t7ZEvVgsOESTVhw=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    udev
  ];

  passthru.tests.dbus = rustPlatform.buildRustPackage {
    pname = "usbeehive-dbus-test";
    inherit (finalAttrs) version src cargoHash;

    cargoBuildNoDefaultFeatures = true;
    cargoBuildFeatures = [ "dbus" ];

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ udev ];

    doCheck = true;

  };

  meta = {
    description = "Inspect USB-C cables and devices on Linux";
    homepage = "https://github.com/abrauchli/usbeehive";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "usbeehive";
  };
})
