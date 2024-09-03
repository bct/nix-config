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
  };
}
