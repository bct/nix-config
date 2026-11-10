{ lib }:
rec {
  # "192.168.200.7" -> 7, or null if the address isn't in the /24.
  hostNumber =
    subnetPrefix: address:
    let
      m = builtins.match "${lib.escapeRegex subnetPrefix}\\.([0-9]{1,3})" address;
    in
    if m == null then null else lib.toInt (lib.head m);

  # A locally administered MAC derived from an IPv4 address, so routed guests
  # don't need one picked by hand. "192.168.200.7" -> "02:00:c0:a8:c8:07"
  macForAddress =
    address:
    "02:00:"
    + lib.concatMapStringsSep ":" (
      octet: lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString (lib.toInt octet)))
    ) (lib.splitString "." address);
}
