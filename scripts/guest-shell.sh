#!/usr/bin/env bash
# Thin wrapper: prefer gnu-hurd-docker launcher for Hurd guest tooling.
# Product sources remain pure Savannah; guest is lab only.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
DOCKER_ROOT="${GNU_HURD_DOCKER:-$HOME/Github/gnu-hurd-docker}"
RUNNER="$DOCKER_ROOT/scripts/run-hurd-qemu.sh"
LINK_IMG_DIR="$ROOT/external-assets/images"
ACK=${ARCH_HURD_QEMU_ACK:-}
MODE=${1:-hint}

usage() {
  cat <<EOF
usage: $0 [hint|run|print-ssh]

hint   Print how to launch guest (default; no VM start)
run    Launch guest (requires ARCH_HURD_QEMU_ACK=yes)
print-ssh
       Print ssh hint for default port forwarding

Guest is tooling only. See docs/architecture/SOURCE_POLICY.md and
docs/architecture/DEV_ENVIRONMENTS.md.
EOF
}

prefer_image() {
  local c
  for c in \
    "$LINK_IMG_DIR/debian-hurd-amd64.latest.qcow2" \
    "$LINK_IMG_DIR/debian-hurd-amd64-20260314.qcow2" \
    "$LINK_IMG_DIR/hurd-working.qcow2" \
    "$LINK_IMG_DIR/debian-hurd-amd64.qcow2"
  do
    if [[ -e "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

case "$MODE" in
  -h|--help|help) usage; exit 0 ;;
esac

IMG=$(prefer_image || true)

echo "=== Arch_Hurd guest shell (tooling lane) ==="
echo "docker_project: $DOCKER_ROOT"
if [[ -n "${IMG:-}" ]]; then
  echo "preferred_image: $IMG"
else
  echo "preferred_image: none (run make link-assets)"
fi

if [[ -x "$RUNNER" ]]; then
  echo "launcher: $RUNNER (preferred)"
else
  echo "launcher: missing $RUNNER; fallback scripts/qemu-guest-hint.sh"
fi

if [[ "$MODE" == "print-ssh" ]]; then
  echo "ssh -p 2222 root@127.0.0.1   # gnu-hurd-docker default"
  echo "ssh -p 10022 root@127.0.0.1  # Arch_Hurd guest-hint default"
  exit 0
fi

if [[ "$MODE" == "hint" ]]; then
  echo
  echo "To launch with gnu-hurd-docker:"
  if [[ -x "$RUNNER" ]]; then
    if [[ -n "${IMG:-}" ]]; then
      echo "  ARCH_HURD_QEMU_ACK=yes $0 run"
      echo "  # or directly:"
      echo "  $RUNNER -i $(printf %q "$IMG") -m 2048 -c 1 -p 2222"
    else
      echo "  $RUNNER   # auto-detect image under gnu-hurd-docker"
    fi
  else
    echo "  make guest-hint"
    echo "  ARCH_HURD_QEMU_ACK=yes bash scripts/qemu-guest-hint.sh"
  fi
  echo
  echo "After login, capture toolchain:"
  echo "  uname -a; gcc -v 2>&1 | tail -3; dpkg -l gnumach hurd 2>/dev/null | cat"
  echo "  # save host-side into evidence/captures/guest-tooling-*.txt"
  exit 0
fi

if [[ "$MODE" != "run" ]]; then
  usage >&2
  exit 2
fi

if [[ "$ACK" != "yes" ]]; then
  echo "refusing: set ARCH_HURD_QEMU_ACK=yes to launch a VM" >&2
  exit 3
fi

if [[ -x "$RUNNER" ]]; then
  if [[ -n "${IMG:-}" ]]; then
    exec "$RUNNER" -i "$IMG" -m 2048 -c 1 -p 2222
  else
    exec "$RUNNER" -m 2048 -c 1 -p 2222
  fi
fi

# Fallback minimal launcher
if [[ -z "${IMG:-}" ]]; then
  echo "no image available" >&2
  exit 4
fi
exec bash "$ROOT/scripts/qemu-guest-hint.sh" "$IMG"
