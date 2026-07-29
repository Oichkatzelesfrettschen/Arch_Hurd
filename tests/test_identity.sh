#!/usr/bin/env bash
# Drive real identity verifier and assert hurd_x86_64 in product metadata.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
bash scripts/verify-identity.sh
# Sample product PKGBUILD must declare hurd_x86_64
rg -q "arch=\\('hurd_x86_64'\\)" packages/base/gnumach/PKGBUILD
rg -q "Architecture = hurd_x86_64" config/target/pacman.conf.fragment
# Negative: fragment must not list archlinux.org
if rg -q 'archlinux\.org' config/target/pacman.conf.fragment; then
  echo "FAIL archlinux.org in target pacman" >&2
  exit 1
fi
echo "PASS test_identity"
