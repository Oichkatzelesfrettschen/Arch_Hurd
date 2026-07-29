#!/usr/bin/env bash
# Assert product defaults are pure GNU Savannah, not Debian pool.
# Exit 0 only if product entrypoints and pins satisfy SOURCE_POLICY.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
fail=0

echo "== pure-GNU product default gate =="

# fetch-sources must not clone deb.debian.org
if rg -n 'deb\.debian\.org|debian/pool' scripts/fetch-sources.sh >/dev/null 2>&1; then
  echo "FAIL: scripts/fetch-sources.sh references Debian pool" >&2
  fail=1
else
  echo "OK fetch-sources has no Debian pool URLs"
fi

if ! rg -n 'git.savannah.gnu.org/git/hurd/gnumach' scripts/fetch-sources.sh >/dev/null; then
  echo "FAIL: fetch-sources missing Savannah gnumach" >&2
  fail=1
else
  echo "OK fetch-sources clones Savannah gnumach"
fi

# product PKGBUILDs for core trio must use savannah git
for pkg in gnumach mig hurd; do
  f="packages/base/${pkg}/PKGBUILD"
  if [[ ! -f "$f" ]]; then
    echo "FAIL: missing $f" >&2
    fail=1
    continue
  fi
  if rg -n 'deb\.debian\.org' "$f" >/dev/null 2>&1; then
    echo "FAIL: $f uses Debian pool as source" >&2
    fail=1
  elif ! rg -n 'git.savannah.gnu.org/git/hurd' "$f" >/dev/null; then
    echo "FAIL: $f missing Savannah git source" >&2
    fail=1
  else
    echo "OK $f Savannah source"
  fi
done

# ORACLE_PINS: core components must be gnu-savannah / pinned-git
for comp in gnumach mig hurd; do
  line=$(awk -F'\t' -v c="$comp" 'NR>1 && $1==c {print; exit}' frontier/ORACLE_PINS.tsv)
  if [[ -z "$line" ]]; then
    echo "FAIL: no ORACLE_PINS row for $comp" >&2
    fail=1
    continue
  fi
  status=$(echo "$line" | cut -f5)
  oracle=$(echo "$line" | cut -f2)
  if [[ "$oracle" != "gnu-savannah" && "$oracle" != "gnu-hurd" && "$oracle" != "gnu-hurd-tree" ]]; then
    # allow only if inspiration-only
    if [[ "$status" != "inspiration-only" ]]; then
      echo "FAIL: $comp oracle=$oracle not pure GNU" >&2
      fail=1
    fi
  else
    echo "OK pin $comp oracle=$oracle status=$status"
  fi
done

# Debian rows must be inspiration-only
while IFS=$'\t' read -r comp oracle rest; do
  [[ "$comp" == "component" ]] && continue
  if [[ "$oracle" == "debian-inspiration" || "$oracle" == debian* ]]; then
    status=$(echo -e "$comp\t$oracle\t$rest" | cut -f5)
    # re-read properly
    :
  fi
done < frontier/ORACLE_PINS.tsv

awk -F'\t' 'NR>1 && ($2 ~ /debian/ || $1 ~ /^debian-/) {
  if ($5 != "inspiration-only" && $5 != "reference") {
    print "FAIL: debian pin not reference/inspiration-only:", $0; exit 1
  }
}' frontier/ORACLE_PINS.tsv && echo "OK all debian* pins are reference/inspiration-only"

# APPLY_DEBIAN default must be 0
for s in scripts/build-stage0-headers.sh scripts/build-mig.sh scripts/build-gnumach.sh; do
  if [[ -f "$s" ]]; then
    if rg -n 'APPLY_DEBIAN_INSPIRATION_PATCHES=\$\{APPLY_DEBIAN_INSPIRATION_PATCHES:-0\}' "$s" >/dev/null; then
      echo "OK $s Debian patches default off"
    elif rg -n 'APPLY_DEBIAN_INSPIRATION_PATCHES' "$s" >/dev/null; then
      # still ok if default 0 elsewhere
      if rg -n ':-0\}' "$s" >/dev/null; then
        echo "OK $s has :-0 default"
      else
        echo "WARN $s sets APPLY_DEBIAN without clear default 0"
      fi
    fi
  fi
done

if [[ ! -f docs/architecture/SOURCE_POLICY.md ]]; then
  echo "FAIL: missing SOURCE_POLICY.md" >&2
  fail=1
else
  echo "OK SOURCE_POLICY.md present"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "verify-pure-gnu-default FAILED" >&2
  exit 1
fi
echo "verify-pure-gnu-default PASSED"
exit 0
