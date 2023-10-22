{ pkgs, ... }:

{
  users.users.bct.packages = with pkgs; [
    pollymc
  ];
}
