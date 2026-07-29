#!/usr/bin/env bash
# S2: Build cross binutils targeting x86_64-gnu (Hurd) on Linux host.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PREFIX=${ARCH_HURD_CROSS_PREFIX:-"$ROOT/build/cross"}
SRC="$ROOT/build/src"
JOBS=${JOBS:-$(nproc 2>/dev/null || echo 2)}
TARGET=x86_64-gnu
# Use a stable binutils release suitable for freestanding/cross work
BINUTILS_VER=${BINUTILS_VER:-2.43.1}
LOG="$ROOT/evidence/captures/cross-binutils-$(date -u +%Y%m%dT%H%M%SZ).log"
URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VER}.tar.xz"

mkdir -p "$SRC" "$PREFIX" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "cross-binutils start $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "prefix=$PREFIX target=$TARGET ver=$BINUTILS_VER"

TARBALL="$SRC/binutils-${BINUTILS_VER}.tar.xz"
if [[ ! -f "$TARBALL" ]]; then
  curl -fL --retry 3 -o "$TARBALL.partial" "$URL"
  mv "$TARBALL.partial" "$TARBALL"
fi
sum=$(sha256sum "$TARBALL" | awk '{print $1}')
echo "tarball_sha256=$sum"

rm -rf "$SRC/binutils-${BINUTILS_VER}" "$SRC/binutils-build"
tar -C "$SRC" -xf "$TARBALL"
mkdir -p "$SRC/binutils-build"
cd "$SRC/binutils-build"

"$SRC/binutils-${BINUTILS_VER}/configure" \
  --prefix="$PREFIX" \
  --target="$TARGET" \
  --with-sysroot="$ROOT/build/sysroots/x86_64-gnu" \
  --disable-nls \
  --disable-werror \
  --enable-deterministic-archives

make -j"$JOBS"
make install

test -x "$PREFIX/bin/${TARGET}-as"
test -x "$PREFIX/bin/${TARGET}-ld"
"$PREFIX/bin/${TARGET}-as" --version | head -1
"$PREFIX/bin/${TARGET}-ld" --version | head -1

{
  echo "status=ok"
  echo "target=$TARGET"
  echo "prefix=$PREFIX"
  echo "binutils_ver=$BINUTILS_VER"
  echo "tarball_sha256=$sum"
  echo "log=$LOG"
} > "$PREFIX/CROSS_BINUTILS.ok"

echo "cross-binutils: SUCCESS"
echo "export PATH=$PREFIX/bin:\$PATH"
