#!/usr/bin/env bash
# Inventory host tools, paru/pacman Hurd-related packages, and local assets.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-"$ROOT/evidence/captures/host-tooling-scan-$(date -u +%Y%m%dT%H%M%SZ).tsv"}
mkdir -p "$(dirname "$OUT")"

echo -e "kind\tname\tstatus\tdetail" > "$OUT"

row() { echo -e "$1\t$2\t$3\t$4" | tee -a "$OUT"; }

echo "== Host tooling scan =="

# commands
for c in bash git make gcc mig qemu-system-x86_64 docker podman paru pacman guix curl; do
  if command -v "$c" >/dev/null 2>&1; then
    path=$(command -v "$c")
    ver=$("$c" --version 2>&1 | head -1 | tr '\t' ' ' | cut -c1-80)
    row cmd "$c" present "$path | $ver"
  else
    row cmd "$c" missing ""
  fi
done

# pacman packages
if command -v pacman >/dev/null 2>&1; then
  for p in gnumig mig gnu-mig gnumach hurd qemu-base qemu-system-x86 docker podman; do
    if pacman -Q "$p" >/dev/null 2>&1; then
      ver=$(pacman -Q "$p" | awk '{print $2}')
      row pacman "$p" installed "$ver"
    else
      row pacman "$p" not-installed ""
    fi
  done
fi

# AUR/repo name probes via paru (quiet, exact-ish)
if command -v paru >/dev/null 2>&1; then
  # gnumig is the real name; "mig" is noise
  if paru -Ss '^gnumig$' 2>/dev/null | grep -q gnumig; then
    row paru gnumig searchable "paru -Ss gnumig hit"
  else
    row paru gnumig no-repo-hit "use local OS-Projects/mig-gnu or stage0 make mig"
  fi
fi

# local sibling projects
for p in \
  "$HOME/Github/gnu-hurd-docker" \
  "$HOME/Github/OS-Projects/mig-gnu" \
  "$HOME/Github/OS-Projects/GNUHurd2025" \
  "$HOME/Github/OS-Projects/gnumach-headers"
 do
  if [[ -e "$p" ]]; then
    row local-path "$(basename "$p")" present "$p"
  else
    row local-path "$(basename "$p")" absent "$p"
  fi
done

# qcow2 / img under known dirs
shopt -s nullglob
imgs=(
  "$HOME"/Github/gnu-hurd-docker/images/*.{qcow2,img,img.tar.xz,img.tar.gz}
  "$HOME"/Github/OS-Projects/GNUHurd2025/*.{qcow2,img}
)
n=0
for img in "${imgs[@]}"; do
  [[ -f "$img" ]] || continue
  n=$((n+1))
  bytes=$(wc -c < "$img" | tr -d ' ')
  row local-image "$(basename "$img")" present "$img bytes=$bytes"
done
row local-image_count total "$n" "under gnu-hurd-docker and GNUHurd2025"

# pure stage0
if [[ -f "$ROOT/build/stage0/boot/gnumach" ]]; then
  row stage0 gnumach present "$(file -b "$ROOT/build/stage0/boot/gnumach" | tr '\t' ' ')"
else
  row stage0 gnumach absent ""
fi
if [[ -x "$ROOT/build/stage0/bin/mig" ]]; then
  row stage0 mig present "$ROOT/build/stage0/bin/mig"
else
  row stage0 mig absent ""
fi

echo
echo "wrote $OUT"
echo "See docs/architecture/DEV_ENVIRONMENTS.md"
