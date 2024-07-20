{ lib, config, ... }:

with lib;

let
  cfg = config.megahost.container-secrets;
in {
  options.megahost.container-secrets = mkOption {
    type = types.attrsOf (types.attrsOf (types.submodule (
      {config, options, name, ...}: {
        options = {
          hostPath = mkOption {
            type = types.path;
          };

          containerPath = mkOption {
            type = types.path;
            default = "/tmp/secret-${name}";
          };
        };
      }
    )));
  };

  config = {
    containers = lib.mapAttrs (containerName: containerSecretsByName: {
      bindMounts = lib.concatMapAttrs (secretName: containerSecret: {
        ${containerSecret.containerPath} = {
          hostPath = containerSecret.hostPath;
          isReadOnly = true;
        };
      }) containerSecretsByName;
    }) cfg;
  };
}
