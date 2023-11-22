{pkgs, python3}:

python3.pkgs.buildPythonPackage rec {
  pname = "aws2-wrap";
  version = "1.3.1";
  src = pkgs.fetchPypi {
    inherit pname version;
    sha256 = "sha256-z67hjkL1OCCFN8JZoCAmOoVpI1INBgl+ZvDkHvQEyuc=";
  };

  propagatedBuildInputs = [
    python3.pkgs.psutil
  ];
}
