#!/usr/bin/env bash
# Stage a Hurd root filesystem tree on the host (xattr-aware path).
# Phases: layout -> optional stage0 boot bits -> pacman conf -> local mirror.
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:-"$ROOT_DIR/build/hurd-root"}
POLICY="$ROOT_DIR/packages/base/filesystem/translator-policy.txt"
DIRS_SH="$ROOT_DIR/packages/base/filesystem/archhurd-dirs.sh"
STAGE0="$ROOT_DIR/build/stage0"
REPO_MIRROR="$ROOT_DIR/build/repo/mirrorlist"

usage() {
  cat <<EOF
usage: $0 [destdir]

Create a host-side Hurd root layout under destdir (default: build/hurd-root).
Copies stage0 gnumach into /boot when present.
Does not yet unpack .pkg.tar packages or write translator xattrs (next slice).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mkdir -p "$DEST"

bash "$DIRS_SH" "$DEST"
install -Dm644 "$POLICY" "$DEST/usr/share/hurd/translator-policy.txt"

# Boot kernel from stage0 if built
if [[ -f "$STAGE0/boot/gnumach" ]]; then
  install -Dm644 "$STAGE0/boot/gnumach" "$DEST/boot/gnumach"
  [[ -f "$STAGE0/boot/gnumach.sha256" ]] && \
    install -Dm644 "$STAGE0/boot/gnumach.sha256" "$DEST/boot/gnumach.sha256"
  echo "mkhurdroot: installed stage0 gnumach into $DEST/boot"
fi
if [[ -d "$STAGE0/include" ]]; then
  mkdir -p "$DEST/usr/include"
  cp -a "$STAGE0/include/." "$DEST/usr/include/" 2>/dev/null || true
fi

# pacman configuration
mkdir -p "$DEST/etc/pacman.d"
if [[ -f "$ROOT_DIR/config/target/pacman.conf.fragment" ]]; then
  # Early bootstrap may relax signatures until keyring exists.
  sed 's/^SigLevel.*/SigLevel    = Optional TrustAll/; s/^LocalFileSigLevel.*/LocalFileSigLevel = Optional/' \
    "$ROOT_DIR/config/target/pacman.conf.fragment" > "$DEST/etc/pacman.conf"
else
  cat > "$DEST/etc/pacman.conf" <<'EOF'
[options]
HoldPkg     = pacman glibc hurd gnumach
Architecture = hurd_x86_64
CheckSpace
SigLevel    = Optional TrustAll
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist
EOF
fi

if [[ -f "$REPO_MIRROR" ]]; then
  # rewrite Server paths for in-root use: prefer generic file path
  sed 's|^Server = file://.*|Server = file:///var/cache/archhurd/repo/$repo/os/$arch|' \
    "$REPO_MIRROR" > "$DEST/etc/pacman.d/mirrorlist" || true
fi
if [[ ! -s "$DEST/etc/pacman.d/mirrorlist" ]]; then
  cat > "$DEST/etc/pacman.d/mirrorlist" <<'EOF'
# Arch GNU/Hurd mirrorlist (bootstrap)
Server = file:///var/cache/archhurd/repo/$repo/os/$arch
EOF
fi

# Cache mount point for local repo bind
mkdir -p "$DEST/var/cache/archhurd/repo"

# Minimal fstab placeholder
cat > "$DEST/etc/fstab" <<'EOF'
# <file system> <dir> <type> <options> <dump> <pass>
EOF

# Hostname
echo 'archhurd' > "$DEST/etc/hostname"

# Marker
mkdir -p "$DEST/var/lib/archhurd"
{
  echo "stage=layout+stage0-optional"
  echo "created_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "triple=x86_64-pc-gnu"
  if [[ -f "$DEST/boot/gnumach" ]]; then
    echo "gnumach=present"
  else
    echo "gnumach=absent"
  fi
} > "$DEST/var/lib/archhurd/root-stage"

# Inventory (avoid SIGPIPE under pipefail when truncating)
{
  echo "# mkhurdroot inventory"
  find "$DEST" -printf '%y %p\n' | sort | head -200 || true
} > "$DEST/var/lib/archhurd/inventory.txt"

echo "mkhurdroot: staged $DEST"
echo "mkhurdroot: next = package unpack + xattr translators + disk image"
