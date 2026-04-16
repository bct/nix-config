{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.pyrosimple
  ];
}
