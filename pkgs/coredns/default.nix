{ lib
, stdenv
, buildGoModule
, fetchFromGitHub
, externalPlugins ? [ "wgsd" ]
, vendorSha256 ? "sha256-K2s1MrS8Ot5LFh4ZbtTtYxdYla5rUYSZ/RQ/UgA52hw="
}:

let
  availableExternalPlugins = import ./external-plugins.nix;
  generatePluginEntry = name: src: "${name}:${src}";
  getPlugin = name: generatePluginEntry name availableExternalPlugins."${name}";
  attrsToPlugins = attrs: builtins.map (x: getPlugin x) attrs;
  attrsToSources = attrs: builtins.map (x: availableExternalPlugins."${x}") attrs;
in buildGoModule rec {
  pname = "coredns";
  version = "1.10.0";

  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns";
    rev = "v${version}";
    sha256 = "sha256-Kb4nkxuyZHJT5dqFSkqReFkN8q1uYm7wbhSIiLd8Hck=";
  };

  inherit vendorSha256;

  # Override the go-modules fetcher derivation to fetch plugins
  modBuildPhase = ''
    for plugin in ${builtins.toString (attrsToPlugins externalPlugins)}; do echo $plugin >> plugin.cfg; done
    for src in ${builtins.toString (attrsToSources externalPlugins)}; do go get $src; done
    go generate
    go mod vendor
  '';

  # Copy over the lockfiles as well, because the source
  # doesn't contain it. The fixed-output derivation is
  # probably not reproducible anyway.
  modInstallPhase = ''
    mv -t vendor go.mod go.sum plugin.cfg
    cp -r --reflink=auto vendor "$out"
  '';

  buildPhase = ''
    runHook preBuild

    chmod -R u+w vendor
    mv -t . vendor/go.{mod,sum} vendor/plugin.cfg

    go generate
    go install

    runHook postBuild
  '';

  postPatch = ''
    substituteInPlace test/file_cname_proxy_test.go \
      --replace "TestZoneExternalCNAMELookupWithProxy" \
                "SkipZoneExternalCNAMELookupWithProxy"

    substituteInPlace test/readme_test.go \
      --replace "TestReadme" "SkipReadme"
  '' + lib.optionalString stdenv.isDarwin ''
    # loopback interface is lo0 on macos
    sed -E -i 's/\blo\b/lo0/' plugin/bind/setup_test.go
  '';

  meta = with lib; {
    homepage = "https://coredns.io";
    description = "A DNS server that runs middleware";
    license = licenses.asl20;
    maintainers = with maintainers; [ rushmorem rtreffer deltaevo ];
  };
}
