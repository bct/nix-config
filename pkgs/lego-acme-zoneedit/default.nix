{
  pkgs,
  ...
}:
pkgs.writeShellApplication {
  name = "lego-acme-zoneedit";
  runtimeInputs = [ pkgs.curl ];

  text = builtins.readFile ./lego-acme-zoneedit;
}
