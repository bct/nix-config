# https://jade.fyi/blog/flakes-arent-real/
{ lib, ... }:
{
  options.diffeq.secretsPath = lib.mkOption {
    type = lib.types.path;
    description = "The path to the agenix encrypted secrets. Injected by the flake.";
  };
}
