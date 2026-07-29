#!/usr/bin/env bash
# Assemble a host-side bootstrap disk image skeleton for ArchHurd.
# Embeds pure stage0 gnumach + mkhurdroot layout. Not a full M0 root yet.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
STAGE="$ROOT/build/stage0"
OUT_DIR="$ROOT/build/images"
IMG=${1:-"$OUT_DIR/archhurd-bootstrap.img"}
SIZE_MB=${ARCH_HURD_IMG_MB:-512}
MNT="$ROOT/build/mnt-bootstrap"
LOG="$ROOT/evidence/captures/assemble-image-$(date -u +%Y%m%dT%H%M%SZ).log"

mkdir -p "$OUT_DIR" "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "assemble-bootstrap-image start $(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ ! -f "$STAGE/boot/gnumach" ]]; then
  echo "missing stage0 gnumach; run make gnumach" >&2
  exit 1
fi

# Stage root tree first
bash "$ROOT/scripts/mkhurdroot.sh" "$ROOT/build/hurd-root-bootstrap"

need_root=0
if ! command -v mkfs.ext2 >/dev/null 2>&1; then
  echo "mkfs.ext2 missing; producing tarball only" >&2
  need_root=1
fi

# Always produce a bootstrap tarball (no root required)
TAR="$OUT_DIR/archhurd-bootstrap-root.tar.gz"
tar -C "$ROOT/build/hurd-root-bootstrap" -czf "$TAR" .
test -s "$TAR"
sha256sum "$TAR" > "$TAR.sha256"
cat "$TAR.sha256"
echo "tarball=$TAR"

if [[ "$need_root" -eq 1 ]] || [[ "$(id -u)" -ne 0 ]]; then
  # Non-root path: raw image file with only kernel payload section note
  {
    echo "status=partial"
    echo "image=none"
    echo "tarball=$TAR"
    echo "note=run as root with mkfs.ext2 to create $IMG"
    echo "log=$LOG"
  } > "$OUT_DIR/ASSEMBLE.partial"
  echo "assemble: tarball only (no root/mkfs). OK for offline progress."
  exit 0
fi

# Root path: create sparse image and populate
rm -f "$IMG"
dd if=/dev/zero of="$IMG" bs=1M count="$SIZE_MB" status=none
mkfs.ext2 -F -L archhurd "$IMG"
mkdir -p "$MNT"
mount -o loop "$IMG" "$MNT"
trap 'umount "$MNT" 2>/dev/null || true' EXIT
rsync -a "$ROOT/build/hurd-root-bootstrap"/ "$MNT"/
umount "$MNT"
trap - EXIT
sha256sum "$IMG" | tee "$IMG.sha256"
{
  echo "status=ok"
  echo "image=$IMG"
  echo "tarball=$TAR"
  echo "log=$LOG"
} > "$OUT_DIR/ASSEMBLE.ok"
echo "assemble: image $IMG"
