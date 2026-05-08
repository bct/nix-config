{ pkgs, ... }:
{
  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    settings = {
      replication_factor = 1;

      rpc_bind_addr = "127.0.0.1:3901";
      # TODO: secret
      rpc_secret = "d2612c86302c83539b7cdb111a1ae164b428b8a03ec6772be4dbe223d5fd25b1";

      s3_api = {
        api_bind_addr = "127.0.0.1:3900";
        s3_region = "us-east-1";
      };

      # s3_web is only required if we want to be able to serve a website directly from a bucket.

      admin = {
        api_bind_addr = "127.0.0.1:3903";
      };
    };
  };

  services.caddy = {
    enable = true;

    virtualHosts."s3-new.diffeq.com" = {
      extraConfig = ''
        reverse_proxy localhost:3900 {
          health_uri       /health
          health_port      3903
        }
      '';
    };

    # the admin console runs on container port 9001
    virtualHosts."console.s3-new.diffeq.com" = {
      extraConfig = ''
        reverse_proxy localhost:3903 {
          health_uri       /health
          health_port      3903
        }
      '';
    };
  };
}
