#!/usr/bin/env bash
# QEMU smoke harness scaffold for Arch GNU/Hurd images.
# Refuses to run without an image path and explicit ACK.
set -euo pipefail

IMAGE=${1:-}
ACK=${ARCH_HURD_QEMU_ACK:-}

usage() {
  cat <<EOF
usage: ARCH_HURD_QEMU_ACK=yes $0 /path/to/disk.img

Boots a Hurd disk image under qemu-system-x86_64 -M q35 for smoke testing.
Requires explicit ACK to avoid accidental long-running VMs.
EOF
}

if [[ -z "$IMAGE" || "$IMAGE" == "-h" || "$IMAGE" == "--help" ]]; then
  usage
  exit 2
fi

if [[ "$ACK" != "yes" ]]; then
  echo "refusing: set ARCH_HURD_QEMU_ACK=yes to run" >&2
  exit 3
fi

if [[ ! -f "$IMAGE" ]]; then
  echo "image not found: $IMAGE" >&2
  exit 4
fi

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
  echo "qemu-system-x86_64 missing" >&2
  exit 5
fi

# Conservative defaults inspired by Guix/Debian Hurd practice.
exec qemu-system-x86_64 \
  -M q35 \
  -m 2048 \
  -smp 1 \
  -drive "file=${IMAGE},format=raw,if=virtio" \
  -device e1000,netdev=n0 \
  -netdev user,id=n0 \
  -serial stdio \
  -no-reboot \
  -display none
