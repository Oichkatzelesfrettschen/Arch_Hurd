#!/usr/bin/env bash
# Build pure GNU Mach kernel into build/stage0/boot/gnumach
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GNU_CACHE="$ROOT/build/cache/gnu"
SRC="$ROOT/build/src"
STAGE="$ROOT/build/stage0"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 2)}
LOG="$ROOT/evidence/captures/gnumach-build-$(date -u +%Y%m%dT%H%M%SZ).log"
APPLY_DEBIAN_INSPIRATION_PATCHES=${APPLY_DEBIAN_INSPIRATION_PATCHES:-0}

mkdir -p "$SRC" "$STAGE/boot" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "gnumach-build start $(date -u +%Y-%m-%dT%H:%M:%SZ) base=pure-GNU"

if [[ -x "$STAGE/bin/mig" ]]; then
  export PATH="$STAGE/bin:$PATH"
  export MIG="$STAGE/bin/mig"
else
  echo "need stage0 mig (make mig)" >&2
  exit 1
fi
echo "mig: $(command -v mig) $($MIG --version 2>&1 | head -1)"

# Always refresh worktree from pure GNU cache so pin tip matches product.
[[ -d "$GNU_CACHE/gnumach/.git" ]] || { echo "make fetch first" >&2; exit 1; }
rm -rf "$SRC/gnumach-pure"
git clone --local "$GNU_CACHE/gnumach" "$SRC/gnumach-pure"
GMACH_SRC="$SRC/gnumach-pure"
echo "gnumach HEAD=$(git -C "$GMACH_SRC" rev-parse HEAD)"
echo "gnumach cache HEAD=$(git -C "$GNU_CACHE/gnumach" rev-parse HEAD)"

if [[ "$APPLY_DEBIAN_INSPIRATION_PATCHES" == "1" ]]; then
  echo "WARN: Debian inspiration patches non-default path"
fi

BUILD="$SRC/gnumach-kern-build"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

if [[ ! -x "$GMACH_SRC/configure" ]]; then
  (cd "$GMACH_SRC" && autoreconf -fi)
fi

CFG=(--prefix="$STAGE" --enable-platform=at)
echo "configure ${CFG[*]}"
"$GMACH_SRC/configure" "${CFG[@]}"

make -j"$JOBS"

IMG=""
for cand in gnumach gnumach.gz; do
  [[ -f "$cand" ]] && IMG=$cand && break
done
[[ -n "$IMG" ]] || IMG=$(find "$BUILD" -maxdepth 2 -type f -name 'gnumach' | head -1 || true)
[[ -n "$IMG" && -f "$IMG" ]] || { echo "kernel not found" >&2; exit 2; }

install -Dm644 "$IMG" "$STAGE/boot/gnumach"
sha256sum "$STAGE/boot/gnumach" | tee "$STAGE/boot/gnumach.sha256"
file "$STAGE/boot/gnumach"
{
  echo "status=ok"
  echo "base=pure-gnu-savannah"
  echo "gnumach_sha=$(git -C "$GMACH_SRC" rev-parse HEAD)"
  echo "image=$STAGE/boot/gnumach"
  echo "sha256=$(sha256sum "$STAGE/boot/gnumach" | awk '{print $1}')"
  echo "log=$LOG"
} > "$STAGE/GNUMACH.ok"
echo "gnumach-build SUCCESS (pure GNU)"
