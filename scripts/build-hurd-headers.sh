#!/usr/bin/env bash
# Install pure GNU Hurd public headers into build/stage0 (stage 4).
# Copy-first strategy: full configure needs glibc and can hang on host.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GNU_CACHE="$ROOT/build/cache/gnu"
SRC="$ROOT/build/src"
STAGE="$ROOT/build/stage0"
LOG="$ROOT/evidence/captures/hurd-headers-$(date -u +%Y%m%dT%H%M%SZ).log"

mkdir -p "$SRC" "$STAGE/include" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "hurd-headers start $(date -u +%Y-%m-%dT%H:%M:%SZ) base=pure-GNU mode=copy-first"

[[ -d "$GNU_CACHE/hurd/.git" ]] || { echo "run make fetch first" >&2; exit 1; }
[[ -d "$STAGE/include/mach" ]] || { echo "run make stage0 first" >&2; exit 1; }

rm -rf "$SRC/hurd-pure"
git clone --local "$GNU_CACHE/hurd" "$SRC/hurd-pure"
HURD_SRC="$SRC/hurd-pure"
SHA=$(git -C "$HURD_SRC" rev-parse HEAD)
echo "hurd HEAD=$SHA"

# 1) Top-level include/
if [[ -d "$HURD_SRC/include" ]]; then
  cp -a "$HURD_SRC/include/." "$STAGE/include/"
  echo "copied $HURD_SRC/include"
fi

# 2) hurd/*.h and hurd/hurd/*.h public surface
mkdir -p "$STAGE/include/hurd"
find "$HURD_SRC/hurd" -maxdepth 1 -type f \( -name '*.h' -o -name '*.defs' \) \
  -exec cp -a {} "$STAGE/include/hurd/" \; 2>/dev/null || true

# 3) lib* headers commonly required
for lib in libshouldbeinlibc libihash libiohelp libfshelp libports libthreads \
           libpager libstore libtrivfs libnetfs libdiskfs libpipe libps; do
  if [[ -d "$HURD_SRC/$lib" ]]; then
    find "$HURD_SRC/$lib" -maxdepth 2 -type f -name '*.h' | while read -r h; do
      base=$(basename "$h")
      # avoid clobbering with private names unless under include
      if [[ "$h" == *"/include/"* ]]; then
        mkdir -p "$STAGE/include/$(dirname "${h#$HURD_SRC/*/include/}")" 2>/dev/null || true
        cp -a "$h" "$STAGE/include/" 2>/dev/null || cp -a "$h" "$STAGE/include/hurd/"
      else
        cp -a "$h" "$STAGE/include/hurd/" 2>/dev/null || true
      fi
    done
  fi
done

# Count results
nh=$(find "$STAGE/include/hurd" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "headers under include/hurd: $nh"
find "$STAGE/include/hurd" -type f | head -30

if [[ "$nh" -lt 1 ]]; then
  echo "status=fail" > "$STAGE/HURD_HEADERS.fail"
  echo "hurd-headers FAILED: no headers copied" >&2
  exit 2
fi

{
  echo "status=ok"
  echo "base=pure-gnu-savannah"
  echo "mode=copy-first"
  echo "hurd_sha=$SHA"
  echo "header_files=$nh"
  echo "log=$LOG"
} > "$STAGE/HURD_HEADERS.ok"
echo "hurd-headers: SUCCESS ($nh files)"
exit 0
