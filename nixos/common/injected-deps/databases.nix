{ ... }: {
  # TODO: this only sets up postgres on db.domus
  # TODO: it also implicitly creates databases with the same names
  config.diffeq.databases = {
    users = {
      homebox = { };
      immich = { };
      miniflux = { };
      paperless = { };
      romm = { };
      vikunja = { };
    };
  };
}
