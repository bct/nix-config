{ ... }: {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = "medley.domus.diffeq.com:8082";
    settings = {
    };
    services = [
      {
        blackbeard = [
          {
            flood = {
              icon = "flood";
              href = "https://flood.domus.diffeq.com/";
              siteMonitor = "https://flood.domus.diffeq.com/";
            };
          }
          {
            radarr = {
              icon = "radarr";
              href = "https://radarr.domus.diffeq.com/";
              siteMonitor = "https://radarr.domus.diffeq.com/";
            };
          }
          {
            sonarr = {
              icon = "sonarr";
              href = "https://sonarr.domus.diffeq.com/";
              siteMonitor = "https://sonarr.domus.diffeq.com/";
            };
          }
        ];
      }

      {
        media = [
          {
            books = {
              icon = "calibre-web";
              href = "https://books.domus.diffeq.com/";
              siteMonitor = "https://books.domus.diffeq.com/";
            };
          }

          {
            jellyfin = {
              icon = "jellyfin";
              href = "https://jellyfin.domus.diffeq.com/";
              siteMonitor = "https://jellyfin.domus.diffeq.com/";
            };
          }
        ];
      }

      {
        network = [
          {
            router = {
              icon = "openwrt";
              href = "http://router.domus.diffeq.com/";
              siteMonitor = "http://router.domus.diffeq.com/";
            };
          }

          {
            mi-go = {
              icon = "truenas-core";
              href = "http://mi-go.domus.diffeq.com/";
              siteMonitor = "http://mi-go.domus.diffeq.com/";
            };
          }

          {
            unifi = {
              icon = "unifi";
              href = "http://unifi.domus.diffeq.com/";
              siteMonitor = "http://unifi.domus.diffeq.com/";
            };
          }
        ];
      }

      {
        extra = [
          {
            bookmarks = {
              icon = "karakeep";
              href = "https://bookmarks.domus.diffeq.com/";
              siteMonitor = "https://bookmarks.domus.diffeq.com/";
            };
          }

          {
            lubelogger = {
              icon = "lubelogger";
              href = "https://lubelogger.domus.diffeq.com/";
              siteMonitor = "https://lubelogger.domus.diffeq.com/";
            };
          }

          {
            recipes = {
              icon = "tandoor-recipes";
              href = "https://recipes.domus.diffeq.com/";
              siteMonitor = "https://recipes.domus.diffeq.com/";
            };
          }
        ];
      }
    ];
  };
}
