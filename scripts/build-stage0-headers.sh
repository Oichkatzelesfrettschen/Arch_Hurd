#!/usr/bin/env bash
# Build and install pure GNU Mach headers into build/stage0.
# Source: Savannah gnumach.git (NOT Debian tarballs).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GNU_CACHE="$ROOT/build/cache/gnu"
SRC="$ROOT/build/src"
STAGE="$ROOT/build/stage0"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 2)}
LOG="$ROOT/evidence/captures/stage0-headers-$(date -u +%Y%m%dT%H%M%SZ).log"
APPLY_DEBIAN_INSPIRATION_PATCHES=${APPLY_DEBIAN_INSPIRATION_PATCHES:-0}

mkdir -p "$SRC" "$STAGE" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "stage0-headers start $(date -u +%Y-%m-%dT%H:%M:%SZ) base=pure-GNU"

GMACH_SRC="$GNU_CACHE/gnumach"
if [[ ! -d "$GMACH_SRC/.git" ]]; then
  echo "missing pure gnumach; run: make fetch" >&2
  exit 1
fi

# Work tree copy so we never dirty the cache clone unless user wants
WORK="$SRC/gnumach-pure"
rm -rf "$WORK"
mkdir -p "$SRC"
git clone --local "$GMACH_SRC" "$WORK"
GMACH_SRC="$WORK"
echo "gnumach HEAD=$(git -C "$GMACH_SRC" rev-parse HEAD)"

if [[ "$APPLY_DEBIAN_INSPIRATION_PATCHES" == "1" ]]; then
  echo "WARN: applying Debian inspiration patches (non-default)"
  DEB="$ROOT/build/cache/debian-inspiration"
  if [[ -f "$DEB"/gnumach_*.debian.tar.xz ]]; then
    mkdir -p "$SRC/gnumach-debian"
    tar -C "$SRC/gnumach-debian" -xf "$(ls "$DEB"/gnumach_*.debian.tar.xz | head -1)"
    if [[ -f "$SRC/gnumach-debian/debian/patches/series" ]]; then
      while read -r p; do
        [[ -z "$p" || "$p" =~ ^# ]] && continue
        patch -d "$GMACH_SRC" -p1 < "$SRC/gnumach-debian/debian/patches/$p" || echo "WARN patch $p"
      done < "$SRC/gnumach-debian/debian/patches/series"
    fi
  else
    echo "no debian-inspiration cache; skip"
  fi
else
  echo "pure GNU: no Debian patches (set APPLY_DEBIAN_INSPIRATION_PATCHES=1 to experiment)"
fi

BUILD="$SRC/gnumach-build"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

if [[ ! -x "$GMACH_SRC/configure" ]]; then
  (cd "$GMACH_SRC" && autoreconf -fi)
elif [[ -f "$GMACH_SRC/configure.ac" && "$GMACH_SRC/configure.ac" -nt "$GMACH_SRC/configure" ]]; then
  (cd "$GMACH_SRC" && autoreconf -fi)
fi

# Platform is PC/AT; CPU is host x86_64 for freestanding kernel/headers.
CFG_ARGS=(--prefix="$STAGE" --exec-prefix="$STAGE" --enable-platform=at)
echo "configure ${CFG_ARGS[*]}"
"$GMACH_SRC/configure" "${CFG_ARGS[@]}"

make -j"$JOBS" install-data

echo "stage0 tree sample:"
find "$STAGE/include/mach" -type f 2>/dev/null | head -20 || true

if [[ -d "$STAGE/include/mach" ]]; then
  echo "stage0-headers: SUCCESS (pure GNU)"
  {
    echo "status=ok"
    echo "base=pure-gnu-savannah"
    echo "gnumach_sha=$(git -C "$GMACH_SRC" rev-parse HEAD)"
    echo "debian_patches=$APPLY_DEBIAN_INSPIRATION_PATCHES"
    echo "log=$LOG"
  } > "$STAGE/STAGE0_HEADERS.ok"
  exit 0
fi

echo "stage0-headers: FAILED" >&2
exit 2
