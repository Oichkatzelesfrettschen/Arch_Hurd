#!/usr/bin/env bash
# Build pure GNU MIG from Savannah into build/stage0.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
GNU_CACHE="$ROOT/build/cache/gnu"
SRC="$ROOT/build/src"
STAGE="$ROOT/build/stage0"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 2)}
LOG="$ROOT/evidence/captures/mig-build-$(date -u +%Y%m%dT%H%M%SZ).log"
APPLY_DEBIAN_INSPIRATION_PATCHES=${APPLY_DEBIAN_INSPIRATION_PATCHES:-0}

mkdir -p "$SRC" "$STAGE" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "mig-build start $(date -u +%Y-%m-%dT%H:%M:%SZ) base=pure-GNU"

[[ -d "$STAGE/include/mach" ]] || { echo "run make stage0 first" >&2; exit 1; }
[[ -d "$GNU_CACHE/mig/.git" ]] || { echo "run make fetch first" >&2; exit 1; }

WORK="$SRC/mig-pure"
rm -rf "$WORK"
git clone --local "$GNU_CACHE/mig" "$WORK"
MIG_SRC="$WORK"
echo "mig HEAD=$(git -C "$MIG_SRC" rev-parse HEAD)"

if [[ "$APPLY_DEBIAN_INSPIRATION_PATCHES" == "1" ]]; then
  echo "WARN: Debian inspiration patches enabled (non-default)"
  DEB="$ROOT/build/cache/debian-inspiration"
  if ls "$DEB"/mig_*.debian.tar.xz >/dev/null 2>&1; then
    mkdir -p "$SRC/mig-debian"
    tar -C "$SRC/mig-debian" -xf "$(ls "$DEB"/mig_*.debian.tar.xz | head -1)"
    if [[ -f "$SRC/mig-debian/debian/patches/series" ]]; then
      while read -r p; do
        [[ -z "$p" || "$p" =~ ^# ]] && continue
        patch -d "$MIG_SRC" -p1 < "$SRC/mig-debian/debian/patches/$p" || echo "WARN $p"
      done < "$SRC/mig-debian/debian/patches/series"
    fi
  fi
fi

find "$MIG_SRC" -name 'Makefile.in' -exec touch {} +
touch "$MIG_SRC/configure" 2>/dev/null || true
if [[ ! -x "$MIG_SRC/configure" ]]; then
  (cd "$MIG_SRC" && autoreconf -fi)
fi

BUILD="$SRC/mig-build"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cd "$BUILD"

export TARGET_CPPFLAGS="-I$STAGE/include"
export TARGET_CFLAGS="-I$STAGE/include -ffreestanding"
export CPPFLAGS="-I$STAGE/include ${CPPFLAGS:-}"
export CFLAGS="-I$STAGE/include ${CFLAGS:-}"

"$MIG_SRC/configure" --prefix="$STAGE" --libexecdir="$STAGE/libexec"
make -j"$JOBS" migcom
make -j"$JOBS" install-exec 2>/dev/null || true
make -j"$JOBS" install 2>/dev/null || {
  mkdir -p "$STAGE/bin" "$STAGE/libexec"
  install -m755 migcom "$STAGE/libexec/migcom" 2>/dev/null || install -m755 .libs/migcom "$STAGE/libexec/migcom"
  [[ -f mig ]] && install -m755 mig "$STAGE/bin/mig"
}

test -x "$STAGE/bin/mig"
"$STAGE/bin/mig" --version || true
{
  echo "status=ok"
  echo "base=pure-gnu-savannah"
  echo "mig_sha=$(git -C "$MIG_SRC" rev-parse HEAD)"
  echo "log=$LOG"
} > "$STAGE/MIG.ok"
echo "mig-build SUCCESS (pure GNU)"
