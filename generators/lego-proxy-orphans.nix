# Lists files in secrets/lego-proxy/ that no machine uses, i.e. whose name
# isn't in any machine's services.lego-proxy-client.domains.
#
#   nix run .#lego-proxy-orphans
#
# Exits 1 if there are orphans. It only reports; it doesn't delete anything.
#
# The list of names in use comes from evaluating the flake, but the directory
# is read from the working tree when the script runs, so untracked files show
# up too.
{
  lib,
  pkgs,
  outputs,
}:
let
  hostConfigs = lib.mapAttrsToList (_: h: h.config) outputs.nixosConfigurations;
  microvmConfigs = lib.concatMap (
    c: lib.mapAttrsToList (_: vm: vm.config.config) (c.microvm.vms or { })
  ) hostConfigs;

  usedBy =
    config:
    let
      # not every machine imports the lego-proxy-client module.
      lego = config.services.lego-proxy-client or { enable = false; };
    in
    lib.optionals lego.enable (map (d: "${d} ${config.networking.hostName}") lego.domains);

  # "<name> <hostname>" lines
  used = lib.sort (a: b: a < b) (lib.concatMap usedBy (hostConfigs ++ microvmConfigs));
in
pkgs.writeShellApplication {
  name = "lego-proxy-orphans";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gawk
    pkgs.git
  ];
  text = ''
    if [ $# -gt 0 ]; then
      dir=$1
    else
      dir="$(git rev-parse --show-toplevel)/secrets/lego-proxy"
    fi

    if [ ! -d "$dir" ]; then
      echo "no such directory: $dir" >&2
      echo "usage: lego-proxy-orphans [secrets/lego-proxy dir]" >&2
      exit 2
    fi

    used=$(cat <<'EOF'
    ${lib.concatStringsSep "\n" used}
    EOF
    )

    status=0
    for f in "$dir"/*; do
      [ -f "$f" ] || continue
      base=$(basename "$f")
      name=''${base%.*}
      if ! awk -v n="$name" '$1 == n { found = 1 } END { exit !found }' <<<"$used"; then
        echo "orphan: $f"
        status=1
      fi
    done

    # every name in use should have its .age (private key) and .pub (whitelist entry).
    while read -r name host; do
      for ext in age pub; do
        if [ ! -e "$dir/$name.$ext" ]; then
          echo "missing: $dir/$name.$ext (used by $host)"
          status=1
        fi
      done
    done <<<"$used"

    if [ $status -eq 0 ]; then
      echo "no orphans in $dir"
    fi
    exit $status
  '';
}
