#!/usr/bin/env bash
# Create a local pacman repo skeleton under build/repo for offline bootstrap.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
REPO=${1:-"$ROOT/build/repo/core/os/x86_64"}
mkdir -p "$REPO"

# Placeholder package database (empty) -- real repo-add when packages exist.
if command -v repo-add >/dev/null 2>&1; then
  # create empty db if no packages
  shopt -s nullglob
  pkgs=("$REPO"/*.pkg.tar.*)
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    # repo-add needs at least one package; write a tiny meta note instead
    cat > "$REPO/README" <<EOF
Local Arch GNU/Hurd core repo (empty).
Drop .pkg.tar.zst packages here and run:
  repo-add core.db.tar.gz *.pkg.tar.zst
EOF
  else
    (cd "$REPO" && repo-add -R core.db.tar.gz ./*.pkg.tar.*)
  fi
else
  cat > "$REPO/README" <<EOF
repo-add not installed on host.
When packages exist, install pacman and run repo-add here.
EOF
fi

# Mirrorlist fragment for staged roots
mkdir -p "$ROOT/build/repo"
cat > "$ROOT/build/repo/mirrorlist" <<EOF
# Local bootstrap mirror
Server = file://$ROOT/build/repo/\$repo/os/\$arch
EOF

echo "seed-local-repo: $REPO"
ls -la "$REPO"
