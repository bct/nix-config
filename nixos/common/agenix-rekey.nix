{ inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  config = {
    age.rekey = {
      masterIdentities = [ ../../secrets/yk1-nix-rage.pub ];
      extraEncryptionPubkeys = [
        # backup key, in case the yubikey is lost, etc.
        "age1rtx8k55ce7u3um2q7c2pyvaau7rqd07y25pc2xaq8tfragnx5qrs7zukgs"
      ];
      storageMode = "local";
      localStorageDir = ../.. + "/secrets/rekeyed/${config.networking.hostName}";
    };

    age.generators = {
      # like agenix-rekey's builtin "ssh-ed25519" generator, but it drops a
      # .pub file on disk too.
      # a downside of this approach is that the unencrypted private key is
      # briefly written to disk.
      ssh-ed25519-pubkey = {name, lib, pkgs, file, ...}: let
        comment = lib.escapeShellArg "${config.networking.hostName}:${name}";
        privKeyPath = lib.escapeShellArg (lib.removeSuffix ".age" file);
      in ''
        ${pkgs.openssh}/bin/ssh-keygen -qt ed25519 -N "" -C ${comment} -f ${privKeyPath}
        priv=$(${pkgs.coreutils}/bin/cat ${privKeyPath})
        ${pkgs.coreutils}/bin/shred -u ${privKeyPath}
        echo "$priv"
      '';
    };
  };
}
