#!/usr/bin/env bash
# OPTIONAL: download Debian pool artifacts for comparison only.
# These are NOT the Arch GNU/Hurd base. See docs/architecture/SOURCE_POLICY.md
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CACHE="$ROOT/build/cache/debian-inspiration"
LOG="$ROOT/evidence/captures/fetch-debian-inspiration-$(date -u +%Y%m%dT%H:%M:%SZ).log"
mkdir -p "$CACHE" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "WARNING: Debian inspiration fetch only -- not product base"
echo "See SOURCE_POLICY.md"

urls=(
  "https://deb.debian.org/debian/pool/main/g/gnumach/gnumach_1.8+git20260224.orig.tar.xz"
  "https://deb.debian.org/debian/pool/main/g/gnumach/gnumach_1.8+git20260224-11.debian.tar.xz"
  "https://deb.debian.org/debian/pool/main/h/hurd/hurd_0.9.git20260527.orig.tar.bz2"
  "https://deb.debian.org/debian/pool/main/h/hurd/hurd_0.9.git20260527-3.debian.tar.xz"
  "https://deb.debian.org/debian/pool/main/m/mig/mig_1.8+git20231217.orig.tar.xz"
  "https://deb.debian.org/debian/pool/main/m/mig/mig_1.8+git20231217-11.debian.tar.xz"
)

: > "$CACHE/SHA256SUMS"
for url in "${urls[@]}"; do
  fn=$(basename "$url")
  echo "-- $fn"
  if [[ ! -f "$CACHE/$fn" ]]; then
    curl -fL --retry 2 -o "$CACHE/$fn.partial" "$url"
    mv "$CACHE/$fn.partial" "$CACHE/$fn"
  fi
  sha256sum "$CACHE/$fn" | tee -a "$CACHE/SHA256SUMS"
done

cat > "$CACHE/README.txt" <<'EOF'
Debian inspiration cache.
Do not use these as the default Arch GNU/Hurd build input.
Pure base: build/cache/gnu/*.git from Savannah.
EOF

echo "debian-inspiration done under $CACHE"
