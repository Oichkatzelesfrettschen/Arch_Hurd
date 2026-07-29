#!/usr/bin/env bash
# Drive real gen-maps.sh and assert inventory covers every scripts/*.sh.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
bash scripts/gen-maps.sh >/dev/null
n_scripts=$(find scripts -maxdepth 1 -name '*.sh' | wc -l | tr -d ' ')
n_inv=$(awk 'NR>1' analysis/maps/scripts.inventory.tsv | wc -l | tr -d ' ')
if [[ "$n_scripts" -eq 0 ]]; then
  echo "FAIL no scripts" >&2
  exit 1
fi
if [[ "$n_scripts" -ne "$n_inv" ]]; then
  echo "FAIL script count $n_scripts != inventory $n_inv" >&2
  exit 1
fi
# every path exists
while IFS=$'\t' read -r path funcs bytes sha; do
  [[ "$path" == "path" ]] && continue
  test -f "$path" || { echo "FAIL missing $path" >&2; exit 1; }
  actual=$(sha256sum "$path" | awk '{print $1}')
  if [[ "$actual" != "$sha" ]]; then
    echo "FAIL hash mismatch $path" >&2
    exit 1
  fi
done < analysis/maps/scripts.inventory.tsv
test -s analysis/maps/MAP_MANIFEST.tsv
test -f analysis/maps/NONCLAIM.txt
echo "PASS test_maps_inventory ($n_scripts scripts)"
