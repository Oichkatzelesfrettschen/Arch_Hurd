#!/usr/bin/env bash
# Offline: inject lab SSH pubkey + known root password into a qcow2 overlay.
# Requires: qemu-nbd, root via sudo -n, guest not running on the image.
# Usage: scripts/guest-inject-ssh.sh [overlay.qcow2]
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OV=${1:-"$ROOT/build/guest-run/overlay.qcow2"}
KEYDIR="$ROOT/build/guest-run/ssh"
MNT=${ARCH_HURD_MNT:-/tmp/hurd-mnt-inject}
PASS=${ARCH_HURD_GUEST_PASS:-archhurd}

if [[ ! -f "$OV" ]]; then
  echo "missing overlay $OV" >&2
  exit 2
fi

mkdir -p "$KEYDIR"
if [[ ! -f "$KEYDIR/archhurd_guest" ]]; then
  ssh-keygen -t ed25519 -N '' -f "$KEYDIR/archhurd_guest" -C 'archhurd-s3-lab'
fi
PUB=$(cat "$KEYDIR/archhurd_guest.pub")
HASH=$(openssl passwd -6 "$PASS")
DAYS=$(($(date +%s) / 86400))

sudo -n qemu-nbd -d /dev/nbd0 2>/dev/null || true
sleep 1
sudo -n qemu-nbd -c /dev/nbd0 "$OV"
sleep 1
sudo -n mkdir -p "$MNT"
sudo -n mount -o rw /dev/nbd0p2 "$MNT"

sudo -n mkdir -p "$MNT/root/.ssh"
echo "$PUB" | sudo -n tee "$MNT/root/.ssh/authorized_keys" >/dev/null
sudo -n chmod 700 "$MNT/root/.ssh"
sudo -n chmod 600 "$MNT/root/.ssh/authorized_keys"

if sudo -n test -d "$MNT/home/user"; then
  sudo -n mkdir -p "$MNT/home/user/.ssh"
  echo "$PUB" | sudo -n tee "$MNT/home/user/.ssh/authorized_keys" >/dev/null
  sudo -n chmod 700 "$MNT/home/user/.ssh"
  sudo -n chmod 600 "$MNT/home/user/.ssh/authorized_keys"
  uid=$(sudo -n awk -F: '$1=="user"{print $3}' "$MNT/etc/passwd" || echo 1000)
  gid=$(sudo -n awk -F: '$1=="user"{print $4}' "$MNT/etc/passwd" || echo 1000)
  sudo -n chown -R "$uid:$gid" "$MNT/home/user/.ssh" || true
fi

sudo -n mkdir -p "$MNT/etc/ssh/sshd_config.d"
sudo -n tee "$MNT/etc/ssh/sshd_config.d/99-archhurd.conf" >/dev/null <<'CFG'
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin yes
AuthenticationMethods any
CFG

# OPENSSL_ia32cap workaround for some Hurd sshd/libcrypto paths
if sudo -n test -f "$MNT/etc/default/ssh"; then
  if ! sudo -n grep -q OPENSSL_ia32cap "$MNT/etc/default/ssh"; then
    echo 'export OPENSSL_ia32cap="~0:0"' | sudo -n tee -a "$MNT/etc/default/ssh" >/dev/null
  fi
else
  echo 'export OPENSSL_ia32cap="~0:0"' | sudo -n tee "$MNT/etc/default/ssh" >/dev/null
fi

export HASH DAYS MNT
sudo -n -E python3 - <<'PY'
import os
from pathlib import Path
p = Path(os.environ["MNT"]) / "etc/shadow"
h = os.environ["HASH"]
days = os.environ["DAYS"]
lines = []
for ln in p.read_text().splitlines():
    if ln.startswith("root:") or ln.startswith("user:"):
        parts = ln.split(":")
        parts[1] = h
        parts[2] = days
        while len(parts) < 9:
            parts.append("")
        lines.append(":".join(parts))
    else:
        lines.append(ln)
p.write_text("\n".join(lines) + "\n")
print("shadow updated for root/user")
PY

sync
sudo -n umount "$MNT"
sudo -n qemu-nbd -d /dev/nbd0
echo "injected key=$KEYDIR/archhurd_guest.pub into $OV"
echo "ssh -i $KEYDIR/archhurd_guest -p 2222 root@127.0.0.1"
echo "password fallback: $PASS"
