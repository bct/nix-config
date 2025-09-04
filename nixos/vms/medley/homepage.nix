{ config, ... }: {
  services.homepage-dashboard = {
    enable = true;
    openFirewall = false;

    allowedHosts = "homepage.domus.diffeq.com";

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

          {
            immich = {
              icon = "immich";
              href = "https://immich.domus.diffeq.com/";
              siteMonitor = "https://immich.domus.diffeq.com/";
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
              # certificate doesn't work, but homepage can't handle the redirect
              siteMonitor = "https://mi-go.domus.diffeq.com/";
            };
          }

          {
            unifi = {
              icon = "unifi";
              href = "http://unifi.domus.diffeq.com/";
              # certificate doesn't work, but homepage can't handle the redirect
              siteMonitor = "https://unifi.domus.diffeq.com/";
            };
          }
        ];
      }

      {
        home = [
          {
            "home assistant" = {
              icon = "home-assistant";
              href = "https://spectator.domus.diffeq.com:8123/";
              siteMonitor = "https://spectator.domus.diffeq.com:8123/";
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
            printer = {
              icon = "printer";
              href = "http://printer.domus.diffeq.com/";
              siteMonitor = "http://printer.domus.diffeq.com/";
            };
          }

          {
            octopi = {
              icon = "octoprint";
              href = "http://octopi.domus.diffeq.com/";
              siteMonitor = "http://octopi.domus.diffeq.com/";
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
            grafana = {
              icon = "grafana";
              href = "https://grafana.domus.diffeq.com/";
              siteMonitor = "https://grafana.domus.diffeq.com/";
            };
          }

          {
            paperless = {
              icon = "paperless-ngx";
              href = "https://paperless.domus.diffeq.com/";
              siteMonitor = "https://paperless.domus.diffeq.com/";
            };
          }

          {
            recipes = {
              icon = "tandoor-recipes";
              href = "https://recipes.domus.diffeq.com/";
              siteMonitor = "https://recipes.domus.diffeq.com/";
            };
          }

          {
            tasks = {
              icon = "vikunja";
              href = "https://tasks.diffeq.com/";
              siteMonitor = "https://tasks.diffeq.com/";
            };
          }

          {
            goatcounter = {
              icon = "sh-goatcounter";
              href = "https://m.diffeq.com/";
              siteMonitor = "https://m.diffeq.com/";
            };
          }
        ];
      }
    ];
  };

  services.caddy = {
    enable = true;
    virtualHosts."homepage.domus.diffeq.com" = {
      useACMEHost = "homepage.domus.diffeq.com";
      extraConfig = "reverse_proxy localhost:${toString config.services.homepage-dashboard.listenPort}";
    };
  };
}
