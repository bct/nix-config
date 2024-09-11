#!/bin/sh
#
# https://go-acme.github.io/lego/dns/exec/

set -euo pipefail

authorization="$ZONEEDIT_ID:$ZONEEDIT_TOKEN"

do_add() {
  fqdn=$1
  record=$2

  # strip trailing "."
  host=${fqdn::-1}

  # https://dynamic.zoneedit.com/txt-create.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
  url="https://dynamic.zoneedit.com/txt-create.php?host=${host}&rdata=${record}"

  result=$(curl -s -u "$authorization" "$url")

  if [[ ! $result =~ 'SUCCESS CODE="200"' ]]; then
    echo "zoneedit API call failed:"
    echo "$result"
    exit 1
  else
    echo "${host}: TXT record submitted."
  fi
}

do_cleanup() {
  fqdn=$1
  record=$2

  # strip trailing "."
  host=${fqdn::-1}

  # https://dynamic.zoneedit.com/txt-delete.php?host=_acme-challenge.example.com&rdata=depE1VF_xshMm1IVY1Y56Kk9Zb_7jA2VFkP65WuNgu8W
  url="https://dynamic.zoneedit.com/txt-delete.php?host=${host}&rdata=${record}"

  result=$(curl -s -u "$authorization" "$url")

  if [[ ! $result =~ 'SUCCESS CODE="200"' ]]; then
    echo "zoneedit API call failed:"
    echo "$result"
    exit 1
  else
    echo "${host}: TXT record cleaned up"
  fi
}

operation=$1

case $operation in
  present)
    fqdn=$2
    record=$3
    do_add "$fqdn" "$record"
    ;;
  cleanup)
    fqdn=$2
    record=$3
    do_cleanup "$fqdn" "$record"
    ;;
  *)
    echo "Unknown operation $operation"
    exit 1
    ;;
esac
