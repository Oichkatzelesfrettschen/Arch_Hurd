#!/usr/bin/env bash
# Print the active execution plan summary and gate status.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cat <<EOF
=== Arch GNU/Hurd M0 execution plan ===
See: docs/roadmap/EXECUTION_PLAN.md

Phases:
  P0 pins (Savannah)   -> frontier/ORACLE_PINS.tsv (pinned-git)
  P1 fetch pure git    -> make fetch -> build/cache/gnu/
  P2 stage0 headers    -> make stage0
  P3 gnumach kernel    -> make gnumach   [DONE pure ELF64]
  P4 root layout       -> make root
  P5 local repo        -> make repo
  P5b multi-lane       -> make scan-tools link-assets guest-shell
  P6 guest lab         -> ARCH_HURD_QEMU_ACK=yes make guest-shell-run
  P7a guest-native     -> pure glibc+hurd on guest (strategy a)
  P7b product m0       -> pacman + image + evidence/captures/m0-*

EOF
bash "$ROOT/scripts/status.sh"
echo
echo "Artifacts:"
for p in \
  build/cache/SHA256SUMS \
  build/stage0/STAGE0_HEADERS.ok \
  build/stage0/GNUMACH.ok \
  build/hurd-root/var/lib/archhurd/root-stage \
  build/repo/mirrorlist
 do
  if [[ -e "$ROOT/$p" ]]; then echo "  [OK] $p"; else echo "  [  ] $p"; fi
done
