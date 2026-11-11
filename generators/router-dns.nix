# Generates a script that replaces every CNAME and hostname ("domain" section)
# on the OpenWrt router with the set derived from this repo. The script only
# *stages* the changes; nothing takes effect until you commit them.
#
#   ssh root@router sh < "$(nix build --no-link --print-out-paths .#router-dns)"
#   # review the diff it prints, then either:
#   ssh root@router 'uci commit dhcp && /etc/init.d/dnsmasq reload'
#   ssh root@router 'uci revert dhcp'
#
# A machine gets a CNAME for each name it serves: its
# services.lego-proxy-client.domains plus diffeq.dnsAliases.
#
# Routed guests (see nixos/modules/guest-network) don't use the router's DHCP,
# so they get a hostname entry with their static address. Bridged guests and
# other machines are still named by their DHCP lease.
{
  lib,
  pkgs,
  outputs,
}:
let
  zone = "domus.diffeq.com";

  # CNAMEs that can't be derived from a machine's config.
  extraCnames = {
    "media.lan" = "media.${zone}";
  };

  hosts = {
    inherit (outputs.nixosConfigurations)
      auth
      mail
      medley
      mi-go
      octopi
      ranger
      stereo
      yuggoth
      ;
  };

  microvms =
    outputs.nixosConfigurations.yuggoth.config.microvm.vms
    // outputs.nixosConfigurations.mi-go.config.microvm.vms;

  machineConfigs =
    lib.mapAttrsToList (_: h: h.config) hosts
    ++ lib.mapAttrsToList (_: vm: vm.config.config) microvms;

  cnamesFor =
    config:
    let
      target = "${config.networking.hostName}.${zone}";
      # not every machine imports the lego-proxy-client module.
      lego = config.services.lego-proxy-client or { enable = false; };
      legoNames = lib.optionals lego.enable (map (d: "${d}.${zone}") lego.domains);
      aliasNames = map (a: "${a}.${zone}") config.diffeq.dnsAliases;
    in
    map (alias: { inherit alias target; }) (
      lib.filter (n: n != target) (lib.unique (legoNames ++ aliasNames))
    );

  entries =
    lib.concatMap cnamesFor machineConfigs
    ++ lib.mapAttrsToList (alias: target: { inherit alias target; }) extraCnames;

  machineNames = map (c: "${c.networking.hostName}.${zone}") machineConfigs;

  byAlias = lib.groupBy (e: e.alias) entries;
  duplicates = lib.filterAttrs (_: es: lib.length es > 1) byAlias;
  shadowing = lib.filter (e: lib.elem e.alias machineNames) entries;

  checked =
    if duplicates != { } then
      throw "router-dns: aliases claimed more than once: ${
        lib.concatStringsSep ", " (
          lib.mapAttrsToList (
            a: es: "${a} -> ${lib.concatMapStringsSep "/" (e: e.target) es}"
          ) duplicates
        )
      }"
    else if shadowing != [ ] then
      throw "router-dns: aliases collide with machine hostnames: ${
        lib.concatMapStringsSep ", " (e: e.alias) shadowing
      }"
    else
      lib.sort (a: b: a.alias < b.alias) entries;

  routedGuests = lib.concatMap (
    host: lib.filter (g: g.enabled) (lib.attrValues host.config.diffeq.guestNetwork.guests)
  ) (with outputs.nixosConfigurations; [ yuggoth mi-go ]);

  hostRecords = lib.sort (a: b: a.name < b.name) (
    map (g: {
      name = "${g.hostName}.${zone}";
      ip = g.address;
    }) routedGuests
  );

  duplicateHostRecords = lib.filterAttrs (_: rs: lib.length rs > 1) (
    lib.groupBy (r: r.name) hostRecords
  );

  checkedHostRecords =
    if duplicateHostRecords != { } then
      throw "router-dns: hostnames defined more than once: ${lib.concatStringsSep ", " (lib.attrNames duplicateHostRecords)}"
    else
      hostRecords;

  uciAdds =
    lib.concatMapStrings (e: ''
      add dhcp cname
      set dhcp.@cname[-1].cname='${e.alias}'
      set dhcp.@cname[-1].target='${e.target}'
    '') checked
    + lib.concatMapStrings (r: ''
      add dhcp domain
      set dhcp.@domain[-1].name='${r.name}'
      set dhcp.@domain[-1].ip='${r.ip}'
    '') checkedHostRecords;
in
pkgs.writeText "router-dns.sh" ''
  set -eu

  # refuse to run if there are unrelated staged changes, so that committing
  # afterwards only commits what this script did.
  if [ -n "$(uci changes dhcp)" ]; then
    echo "dhcp has uncommitted changes; commit or 'uci revert dhcp' first." >&2
    exit 1
  fi

  # list_pairs <section type> <key> <value key>: "key -> value", one per section
  list_pairs() {
    uci show dhcp \
      | sed -nE "s/^dhcp\.(@$1\[[0-9]+\])\.($2|$3)='(.*)'$/\1 \2 \3/p" \
      | awk -v k="$2" -v v="$3" '$2 == k { a[$1] = $3 } $2 == v { b[$1] = $3 }
             END { for (s in a) print a[s] " -> " b[s] }' \
      | sort
  }

  list_all() {
    list_pairs cname cname target | sed 's/^/CNAME /'
    list_pairs domain name ip | sed 's/^/host  /'
  }

  list_all > /tmp/router-dns.before

  while uci -q delete dhcp.@cname[0]; do :; done
  while uci -q delete dhcp.@domain[0]; do :; done
  # `add` prints each new section's name; only errors (stderr) are interesting.
  uci batch > /dev/null <<'EOF'
  ${uciAdds}EOF

  list_all > /tmp/router-dns.after

  count() { grep -c "^$1 " "$2" || true; }
  echo "== CNAMEs: $(count CNAME /tmp/router-dns.before) before, $(count CNAME /tmp/router-dns.after) after (expected ${toString (lib.length checked)})"
  echo "== hosts:  $(count host /tmp/router-dns.before) before, $(count host /tmp/router-dns.after) after (expected ${toString (lib.length checkedHostRecords)})"
  echo "== changes (staged, not committed):"
  if cmp -s /tmp/router-dns.before /tmp/router-dns.after; then
    echo "(none)"
  elif command -v diff >/dev/null; then
    diff -u /tmp/router-dns.before /tmp/router-dns.after || true
  else
    echo "-- before"; cat /tmp/router-dns.before
    echo "-- after"; cat /tmp/router-dns.after
  fi

  echo
  echo "to apply:   uci commit dhcp && /etc/init.d/dnsmasq reload"
  echo "to discard: uci revert dhcp"
''
