#!/usr/bin/env bash
# Symlink local Hurd dev assets into this repo (no large copies).
# Sources: gnu-hurd-docker images, mig-gnu PKGBUILD, GNUHurd2025 images.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LINK="$ROOT/external-assets"
mkdir -p "$LINK/images" "$LINK/pkgbuilds" "$LINK/projects"

link_dir() {
  local src=$1 dest=$2
  if [[ -e "$src" ]]; then
    ln -sfn "$src" "$dest"
    echo "OK  $dest -> $src"
  else
    echo "MISS $src"
  fi
}

link_dir "$HOME/Github/gnu-hurd-docker" "$LINK/projects/gnu-hurd-docker"
link_dir "$HOME/Github/OS-Projects/mig-gnu" "$LINK/pkgbuilds/mig-gnu"
link_dir "$HOME/Github/OS-Projects/GNUHurd2025" "$LINK/projects/GNUHurd2025"
link_dir "$HOME/Github/OS-Projects/gnumach-headers" "$LINK/pkgbuilds/gnumach-headers"

# Prefer stable "latest" names if present
for name in \
  debian-hurd-amd64.latest.qcow2 \
  debian-hurd-amd64.qcow2 \
  hurd-working.qcow2 \
  debian-hurd-amd64-20260314.qcow2
 do
  src="$HOME/Github/gnu-hurd-docker/images/$name"
  if [[ -f "$src" ]]; then
    ln -sfn "$src" "$LINK/images/$name"
    echo "OK  images/$name"
  fi
done

# inventory
{
  echo "# external-assets inventory $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  find "$LINK" -type l -printf '%p -> %l\n' 2>/dev/null | sort
} > "$LINK/INVENTORY.txt"

cat > "$LINK/README.md" <<'EOF'
# External assets (symlinks only)

These point at workstation projects. They are **not** vendored into Arch_Hurd git.

| Link | Purpose |
|---|---|
| projects/gnu-hurd-docker | Docker/QEMU Hurd guest orchestration |
| images/*.qcow2 | Ready Hurd disks for guest tooling |
| pkgbuilds/mig-gnu | Host gnumig PKGBUILD (paru-local / makepkg) |

Product source base remains pure GNU Savannah (see SOURCE_POLICY.md).
Guest images may be Debian Hurd for **tooling only**.
EOF

echo "linked under $LINK"
cat "$LINK/INVENTORY.txt"
