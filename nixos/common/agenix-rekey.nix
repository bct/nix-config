{ inputs, config, ... }: {
  imports = [
    inputs.agenix.nixosModules.default
    inputs.agenix-rekey.nixosModules.default
  ];

  config = {
    age.rekey = {
      masterIdentities = ["/home/bct/.ssh/id_rsa"];
      extraEncryptionPubkeys = [
        # TODO backup key.
        # https://github.com/oddlama/agenix-rekey?tab=readme-ov-file#agerekeyextraencryptionpubkeys
      ];
      storageMode = "local";
      localStorageDir = ../.. + "/secrets/rekeyed/${config.networking.hostName}";
    };
  };
}
