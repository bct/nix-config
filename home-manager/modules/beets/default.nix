{ ... }:
{
  programs.beets = {
    enable = true;
    settings = {
      library = "/mnt/beets/library.db";
      directory = "/mnt/beets/library";

      plugins = "fetchart inline lastgenre permissions musicbrainz discogs albumtypes the mbsync";

      import = {
        copy = true;
        log = "/mnt/beets/log/import.log";
      };

      per_disc_numbering = true;

      item_fields = {
        hasdisctitles = "1 if disctotal > 1 and disctitle else 0";

        disclabel = "('Disc ' + str(disc)) + ('. ' + disctitle if disctitle else '')";
        disc_and_track = "f'{disc:01d}-{track:02d}' if disctotal > 1 else f'{track:02d}'";

        realyear = "original_year if original_year != 0 and original_year < year else year";
      };

      paths = {
        default = "%if{$albumartist_sort,$albumartist_sort,$albumartist}/$album%aunique{}/%if{$hasdisctitles,$disclabel/}/$disc_and_track - $title";
        comp = "0. Compilations/$album%aunique{}/%if{$hasdisctitles,$disclabel/}$disc_and_track - $artist - $title";
        "albumtype:soundtrack" =
          "0. Soundtracks/$realyear -%if{$comp,, $albumartist -} $album/%if{$hasdisctitles,$disclabel/}/$disc_and_track -%if{$comp, $artist -} $title";

        singleton = "0. Non-Album/$artist/$title";
      };

      lastgenre = {
        count = 2;
        force = false;
      };

      permissions = {
        file = 644;
        dir = 755;
      };
    };
  };
}
