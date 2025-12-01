{ self, config, pkgs, lib, ... }:

let
  acme-zoneedit = pkgs.writeShellApplication {
    name = "acme-zoneedit";
    runtimeInputs = [ pkgs.curl ];
    text = builtins.readFile ../../../modules/acme-zoneedit/acme-zoneedit.sh;
  };
  acme-zoneedit-with-creds = pkgs.writeShellScript "acme-zoneedit-with-creds" ''
    # source credentials to pass through to the script
    set -a
    source ${config.age.secrets.zoneedit.path}

    # TODO: quoting?
    ${acme-zoneedit}/bin/acme-zoneedit $@
  '';
  clients = import ../../../modules/lego-proxy-client/clients.nix;

  deploy-unifi = pkgs.writeShellApplication {
    name = "deploy-unifi";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      set -euo pipefail

      DEPLOY_KEY=${config.age.secrets.ssh-acme-deploy.path}
      TARGET_HOST=unifi.domus.diffeq.com

      # where does this come from? found it by looking at /data/unifi-core/config/
      UNIFI_SSL_UUID=16e920b6-5a8c-46fa-859b-282daecb1470

      echo "copying key to $TARGET_HOST..."
      ssh -i $DEPLOY_KEY root@$TARGET_HOST "rm -rf /tmp/acme && mkdir /tmp/acme"
      scp -i $DEPLOY_KEY "$LEGO_CERT_PATH" root@$TARGET_HOST:/tmp/acme/cert.pem
      scp -i $DEPLOY_KEY "$LEGO_CERT_KEY_PATH" root@$TARGET_HOST:/tmp/acme/key.pem

      # nginx terminates SSL for the admin UI.
      #
      # I don't know what import_key_cert does - maybe it's important for the captive portal?
      # We may also need a "service unifi restart" at the end.
      # https://gist.github.com/hdml/8a446dc1b0ad4f94b7a17a67a33286ab?permalink_comment_id=5059713#gistcomment-5059713
      echo "deploying..."
      ssh -i $DEPLOY_KEY root@$TARGET_HOST \
        "echo 'updating nginx...' && \
        cp /tmp/acme/key.pem /data/unifi-core/config/$UNIFI_SSL_UUID.key && \
        cp /tmp/acme/cert.pem /data/unifi-core/config/$UNIFI_SSL_UUID.crt && \
        service nginx reload && \
        echo 'updating unifi...' && \
        java -jar /usr/lib/unifi/lib/ace.jar import_key_cert /tmp/acme/key.pem /tmp/acme/cert.pem && \
        rm -rf /tmp/acme"
    '';
  };
in {
  imports = [
    "${self}/nixos/common/agenix-rekey.nix"
    "${self}/nixos/modules/lego-proxy-host"
  ];

  system.stateVersion = "24.05";

  microvm = {
    vcpu = 1;
    mem = 256;
  };

  age.secrets = {
    zoneedit = {
      rekeyFile = ./lego-proxy/secrets/zoneedit.age;
      owner = "lego-proxy";
      group = "acme";
      mode = "440";
    };

    ssh-acme-deploy = {
      rekeyFile = config.diffeq.secretsPath + /ssh/lego-proxy-acme-deploy.age;
      generator.script = "ssh-ed25519-pubkey";
      owner = "acme";
    };
  };

  services.lego-proxy-host = {
    enable = true;
    execCommand = "${acme-zoneedit}/bin/acme-zoneedit";

    clients = lib.mapAttrsToList (name: clientConfig: {
      domain = clientConfig.domain;
      pubKey = if clientConfig ? "pubKey"
                then clientConfig.pubKey
                else builtins.readFile (config.diffeq.secretsPath + /lego-proxy/${name}.pub);
    }) clients;
  };

  security.acme.acceptTerms = true;
  security.acme.certs."unifi.domus.diffeq.com" = {
    email = "s+acme@diffeq.com";
    dnsProvider = "exec";
    dnsResolver = "ns5.zoneedit.com";
    environmentFile = pkgs.writeText "" ''
      EXEC_PATH=${acme-zoneedit-with-creds}
      EXEC_PROPAGATION_TIMEOUT=180
    '';
    extraLegoRunFlags = ["--run-hook=${deploy-unifi}/bin/deploy-unifi"];
  };

  programs.ssh.knownHosts = {
    "unifi.domus.diffeq.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDNJJO5UWuslJ4vKm8i+g1O+ElLsgCKKKXbUKp/2nh2/";
  };
}
