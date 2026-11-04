{ config, ... }: {
  config.diffeq.oidc = {
    services = {
      grafana = {
        redirectURIs = [ "https://grafana.domus.diffeq.com/login/generic_oauth" ];
      };
      # https://homebox.software/en/quick-start/configure/oidc/
      homebox = {
        redirectURIs = [ "https://inventory.domus.diffeq.com/api/v1/users/login/oidc/callback" ];
      };
      # https://docs.immich.app/administration/oauth/
      immich = {
        redirectURIs = [
          "app.immich:///oauth-callback"
          "https://immich.domus.diffeq.com/auth/login"
          "https://immich.domus.diffeq.com/user-settings"
        ];
      };

      paperless = {
        redirectURIs = [
          "https://paperless.domus.diffeq.com/accounts/oidc/oidc.domus.diffeq.com/login/callback/"
        ];
      };
      romm = {
        displayName = "RomM";
        redirectURIs = [ "https://romm.domus.diffeq.com/api/oauth/openid" ];
      };
      tandoor = {
        redirectURIs = [
          "https://recipes.domus.diffeq.com/accounts/oidc/oidc.domus.diffeq.com/login/callback/"
        ];
      };
      vikunja = {
        redirectURIs = [
          "https://${config.diffeq.hostNames.tasks}/auth/openid/domus"
        ];
      };
      netbird = {
        public = true;
        redirectURIs = [
          # this is the URL documented at https://docs.netbird.io/selfhosted/identity-providers/generic-oidc
          "https://viator.diffeq.com/oauth2/callback/oidc.domus.diffeq.com"
          # this is the URL I see in practice
          "https://viator.diffeq.com/#callback"
          # android app / "netbird up"
          "http://localhost:53000"
        ];
      };
    };
  };
}
