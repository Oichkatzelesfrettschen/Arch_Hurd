#!/usr/bin/env bash
# Print (or optionally run) QEMU for a linked Hurd guest image.
# Default: print only. Run requires ARCH_HURD_QEMU_ACK=yes.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
LINK="$ROOT/external-assets/images"
IMG=${1:-}
ACK=${ARCH_HURD_QEMU_ACK:-}

if [[ -z "$IMG" ]]; then
  # pick first available linked image
  shopt -s nullglob
  cands=("$LINK"/*.qcow2 "$LINK"/*.img)
  if [[ ${#cands[@]} -eq 0 ]]; then
    echo "No linked images. Run: ./scripts/link-local-dev-assets.sh" >&2
    echo "Or pass image path as argv1." >&2
    exit 2
  fi
  IMG=${cands[0]}
fi

if [[ ! -e "$IMG" ]]; then
  echo "image not found: $IMG" >&2
  exit 3
fi

# format
fmt=raw
case "$IMG" in
  *.qcow2) fmt=qcow2 ;;
esac

# Prefer gnu-hurd-docker runner if present
DOCKER_RUN="$HOME/Github/gnu-hurd-docker/scripts/run-hurd-qemu.sh"
if [[ -x "$DOCKER_RUN" ]]; then
  echo "# Recommended: use existing mature launcher"
  echo "#   $DOCKER_RUN"
  echo "# Or Arch_Hurd minimal:"
fi

CMD=(
  qemu-system-x86_64
  -M q35
  -m 2048
  -smp 1
  -drive "file=${IMG},format=${fmt},if=virtio"
  -device e1000,netdev=n0
  -netdev user,id=n0,hostfwd=tcp:127.0.0.1:10022-:22
  -serial stdio
  -display none
)

echo "# image: $IMG"
echo "# ssh hint: ssh -p 10022 root@127.0.0.1  (if guest sshd listens)"
printf '%q ' "${CMD[@]}"
echo

if [[ "$ACK" == "yes" ]]; then
  if ! command -v qemu-system-x86_64 >/dev/null; then
    echo "qemu-system-x86_64 missing" >&2
    exit 5
  fi
  exec "${CMD[@]}"
else
  echo "# dry-run only. To launch: ARCH_HURD_QEMU_ACK=yes $0 $(printf %q "$IMG")"
fi
