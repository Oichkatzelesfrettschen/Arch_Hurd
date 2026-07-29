#!/usr/bin/env bash
# Fetch pure GNU/Hurd sources from Savannah (base).
# Debian pool downloads are NOT the default; see fetch-debian-inspiration.sh.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CACHE="$ROOT/build/cache/gnu"
PINS="$ROOT/frontier/ORACLE_PINS.tsv"
LOG="$ROOT/evidence/captures/fetch-gnu-$(date -u +%Y%m%dT%H%M%SZ).log"
DEPTH=${GIT_DEPTH:-1}

mkdir -p "$CACHE" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "fetch-gnu start $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "cache=$CACHE (pure Savannah)"

clone_or_update() {
  local name=$1 url=$2
  local dest="$CACHE/$name"
  if [[ -d "$dest/.git" ]]; then
    echo "-- update $name"
    git -C "$dest" fetch --depth="$DEPTH" origin master 2>/dev/null || \
      git -C "$dest" fetch --depth="$DEPTH" origin main 2>/dev/null || \
      git -C "$dest" fetch origin
    git -C "$dest" checkout -f FETCH_HEAD 2>/dev/null || git -C "$dest" pull --ff-only || true
  else
    echo "-- clone $name from $url"
    git clone --depth="$DEPTH" "$url" "$dest"
  fi
  local sha
  sha=$(git -C "$dest" rev-parse HEAD)
  local subj
  subj=$(git -C "$dest" log -1 --oneline)
  echo "   HEAD=$sha"
  echo "   $subj"
  echo "$sha  $name" >> "$CACHE/GIT_SHAS"
  # write pin fragment
  echo "$name $sha" >> "$CACHE/PINS.txt"
}

: > "$CACHE/GIT_SHAS"
: > "$CACHE/PINS.txt"

clone_or_update gnumach https://git.savannah.gnu.org/git/hurd/gnumach.git
clone_or_update mig     https://git.savannah.gnu.org/git/hurd/mig.git
clone_or_update hurd    https://git.savannah.gnu.org/git/hurd/hurd.git

# glibc: pin path for product userspace (guest-native strategy a).
# Default FETCH_GLIBC=1 so pins can advance; set FETCH_GLIBC=0 to skip large clone.
if [[ "${FETCH_GLIBC:-1}" == "1" ]]; then
  clone_or_update glibc https://git.savannah.gnu.org/git/hurd/glibc.git || \
    echo "WARN: hurd/glibc clone failed; try upstream glibc later"
else
  echo "-- skip glibc (FETCH_GLIBC=0)"
fi

# Update ORACLE_PINS git SHAs for the three cores
python3 - "$PINS" "$CACHE" <<'PY'
import re, sys
from pathlib import Path
pins = Path(sys.argv[1])
cache = Path(sys.argv[2])
sha_map = {}
for line in (cache / "GIT_SHAS").read_text().splitlines():
    parts = line.split()
    if len(parts) >= 2:
        sha_map[parts[1]] = parts[0]
lines = pins.read_text(encoding="ascii", errors="replace").splitlines()
out = []
for i, ln in enumerate(lines):
    if i == 0:
        out.append(ln)
        continue
    cols = ln.split("\t")
    while len(cols) < 7:
        cols.append("")
    name = cols[0]
    if name in sha_map and cols[1] in ("gnu-savannah", "gnu-hurd"):
        cols[2] = f"git:master@{sha_map[name]}"
        cols[4] = "pinned-git"
    out.append("\t".join(cols))
pins.write_text("\n".join(out) + "\n", encoding="ascii")
print("updated", pins)
PY

echo "fetch-gnu done. Pure GNU trees under $CACHE"
echo "Debian is NOT used. Optional: scripts/fetch-debian-inspiration.sh"
