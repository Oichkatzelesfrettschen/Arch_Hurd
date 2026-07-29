#!/usr/bin/env bash
# Launch Hurd guest (overlay + SMP=1), wait for SSH, push pure sources,
# run S3 inventory + glibc configure/build probe, capture evidence.
# Requires: ARCH_HURD_QEMU_ACK=yes
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ACK=${ARCH_HURD_QEMU_ACK:-}
BASE_IMG=${ARCH_HURD_GUEST_IMAGE:-"$ROOT/external-assets/images/debian-hurd-amd64.latest.qcow2"}
SSH_PORT=${SSH_PORT:-2222}
SSH_USER=${SSH_USER:-root}
SSH_PASS=${SSH_PASS:-archhurd}
SSH_KEY=${ARCH_HURD_GUEST_SSH_KEY:-"$ROOT/build/guest-run/ssh/archhurd_guest"}
SHARE="$ROOT/build/guest-share"
EVID="$ROOT/evidence/captures"
OVDIR="$ROOT/build/guest-run"
OV="$OVDIR/overlay.qcow2"
QLOG="$OVDIR/qemu-stdout.log"
SLOG="$OVDIR/serial.log"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
GLOG="$EVID/guest-native-${STAMP}.txt"
GLIBC_MAKE_SECS=${ARCH_HURD_GLIBC_MAKE_SECS:-600}

mkdir -p "$EVID" "$OVDIR" "$ROOT/build/guest-import"

if [[ "$ACK" != "yes" ]]; then
  echo "refusing: set ARCH_HURD_QEMU_ACK=yes" >&2
  exit 3
fi

if [[ ! -e "$BASE_IMG" ]]; then
  echo "missing image $BASE_IMG; run make link-assets" >&2
  exit 4
fi
BASE_IMG=$(readlink -f "$BASE_IMG")

# Ensure share exists with real glibc tree (not sparse README-only)
if [[ ! -f "$SHARE/glibc/configure" ]]; then
  bash "$ROOT/scripts/guest-native-playbook.sh" sync-share || true
  if [[ ! -f "$SHARE/glibc/configure" && -d "$ROOT/build/cache/gnu/glibc" ]]; then
    rm -rf "$SHARE/glibc"
    git clone --shared "$ROOT/build/cache/gnu/glibc" "$SHARE/glibc" 2>/dev/null \
      || cp -a "$ROOT/build/cache/gnu/glibc" "$SHARE/glibc"
  fi
fi

ssh_base_opts=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15 -p "$SSH_PORT")

ssh_cmd() {
  if [[ -f "$SSH_KEY" ]]; then
    ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o PreferredAuthentications=publickey \
      "${ssh_base_opts[@]}" "${SSH_USER}@127.0.0.1" "$@"
  else
    sshpass -p "$SSH_PASS" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no \
      "${ssh_base_opts[@]}" "${SSH_USER}@127.0.0.1" "$@"
  fi
}

ensure_overlay() {
  if [[ ! -f "$OV" ]]; then
    qemu-img create -f qcow2 -b "$BASE_IMG" -F qcow2 "$OV"
    echo "created overlay $OV over $BASE_IMG"
  fi
}

launch_guest() {
  ensure_overlay
  if ss -ltn | rg -q ":${SSH_PORT}\\b"; then
    echo "port $SSH_PORT already open; reusing existing guest if reachable"
    return 0
  fi
  echo "launching guest overlay=$OV base=$BASE_IMG smp=1"
  # Uniprocessor Mach: default to 1 vCPU (gnu-hurd-docker ROADMAP/AGENTS).
  nohup qemu-system-x86_64 \
    -machine pc \
    -accel kvm \
    -cpu qemu64 \
    -m "${ARCH_HURD_GUEST_RAM:-2048}" \
    -smp 1 \
    -drive "file=$OV,if=ide,cache=writeback,aio=threads,format=qcow2" \
    -nic "user,model=e1000,hostfwd=tcp::${SSH_PORT}-:22" \
    -serial "file:$SLOG" \
    -monitor "telnet:127.0.0.1:9999,server,nowait" \
    -display none \
    -d guest_errors \
    -D "$OVDIR/qemu-guest-errors.log" \
    >"$QLOG" 2>&1 &
  echo $! >"$OVDIR/qemu.pid"
  echo "qemu pid $(cat "$OVDIR/qemu.pid") log=$QLOG serial=$SLOG"
}

launch_guest

echo "waiting for SSH on port $SSH_PORT ..."
ok=0
for i in $(seq 1 90); do
  if ssh_cmd 'echo guest_up; uname -a' >"$OVDIR/ssh-probe.txt" 2>/dev/null; then
    ok=1
    break
  fi
  sleep 5
done

{
  echo "utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "stage=S3"
  echo "base_image=$BASE_IMG"
  echo "overlay=$OV"
  echo "ssh_port=$SSH_PORT"
  echo "ssh_ok=$ok"
  if [[ "$ok" -eq 1 ]]; then
    cat "$OVDIR/ssh-probe.txt"
  else
    echo "ssh_failed_after_wait"
    echo "--- serial tail ---"
    tail -c 4000 "$SLOG" 2>/dev/null | tr -cd '\11\12\15\40-\176\n' || true
  fi
} | tee "$GLOG"

if [[ "$ok" -ne 1 ]]; then
  echo "guest SSH failed; see $GLOG" >&2
  echo "hint: inject key with scripts/guest-inject-ssh.sh or set ARCH_HURD_GUEST_SSH_KEY" >&2
  exit 5
fi

# Inventory toolchain on guest
ssh_cmd 'set +e; echo "== inventory =="; uname -a; command -v gcc; gcc --version | head -1; command -v make; make --version | head -1; dpkg -l gnumach hurd libc0.3 build-essential 2>/dev/null | cat; df -h; nproc; ls /hurd 2>/dev/null | head -20; command -v autoconf automake bison flex git python3' \
  | tee -a "$GLOG"

# Push pure source trees
echo "pushing pure sources to guest /root/archhurd-src ..."
ssh_cmd 'mkdir -p /root/archhurd-src /root/archhurd-build /root/archhurd-logs /root/archhurd-sysroot'
for comp in gnumach mig hurd glibc; do
  if [[ -d "$SHARE/$comp" ]]; then
    echo "  upload $comp"
    tar -C "$SHARE" -cf - "$comp" | ssh_cmd "tar -C /root/archhurd-src -xf -"
  fi
done

# Guest-side S3 script
ssh_cmd 'cat > /root/archhurd-s3.sh << "EOS"
#!/bin/bash
set -euo pipefail
LOG=/root/archhurd-logs/s3-$(date -u +%Y%m%dT%H%M%SZ).log
exec > >(tee -a "$LOG") 2>&1
echo "S3 guest build start $(date -u -Iseconds)"
export DEBIAN_FRONTEND=noninteractive
apt-get update || true
apt-get install -y build-essential autoconf automake gawk bison flex texinfo git python3 rsync gnumach-dev mig 2>&1 | tail -30 || true
echo "tools:"
gcc --version | head -1
for d in gnumach mig hurd glibc; do
  if [[ -d /root/archhurd-src/$d/.git ]]; then
    echo "$d=$(git -C /root/archhurd-src/$d rev-parse HEAD)"
  elif [[ -d /root/archhurd-src/$d ]]; then
    echo "$d=present-no-git"
  else
    echo "$d=missing"
  fi
done

mkdir -p /root/archhurd-build/glibc
cd /root/archhurd-build/glibc
set +e
if [[ -x /root/archhurd-src/glibc/configure ]]; then
  /root/archhurd-src/glibc/configure --prefix=/usr --disable-werror 2>&1 | tee /root/archhurd-logs/glibc-configure.txt | tail -80
  echo configure_exit=$?
else
  echo "glibc configure missing; tree incomplete"
  ls -la /root/archhurd-src/glibc 2>&1 | head -20
fi
set -e
MAKE_SECS=${GLIBC_MAKE_SECS:-600}
if [[ -f Makefile ]]; then
  if command -v timeout >/dev/null; then
    timeout "$MAKE_SECS" make -j$(nproc 2>/dev/null || echo 1) 2>&1 | tee /root/archhurd-logs/glibc-make.txt | tail -120
    echo make_exit=$?
  else
    make -j1 2>&1 | tee /root/archhurd-logs/glibc-make.txt | tail -80
  fi
fi

mkdir -p /root/archhurd-build/hurd
cd /root/archhurd-build/hurd
set +e
if [[ -x /root/archhurd-src/hurd/configure ]]; then
  /root/archhurd-src/hurd/configure --prefix=/usr 2>&1 | tee /root/archhurd-logs/hurd-configure.txt | tail -40
  echo hurd_configure_exit=$?
elif [[ -f /root/archhurd-src/hurd/configure.ac ]]; then
  (cd /root/archhurd-src/hurd && autoreconf -fi) 2>&1 | tail -20
  /root/archhurd-src/hurd/configure --prefix=/usr 2>&1 | tee /root/archhurd-logs/hurd-configure.txt | tail -40
  echo hurd_configure_exit=$?
fi
set -e
echo "S3 guest build end $(date -u -Iseconds)"
echo "LOG=$LOG"
EOS
chmod +x /root/archhurd-s3.sh
'

echo "running guest S3 build script (glibc make up to ${GLIBC_MAKE_SECS}s) ..."
ssh_cmd "GLIBC_MAKE_SECS=$GLIBC_MAKE_SECS bash /root/archhurd-s3.sh" | tee -a "$GLOG" || true

ssh_cmd 'ls -la /root/archhurd-logs; echo ---; for f in /root/archhurd-logs/*; do echo "== $f =="; tail -80 "$f"; done' \
  | tee -a "$GLOG" || true

mkdir -p "$ROOT/build/guest-import"
ssh_cmd 'tar -C /root -cf - archhurd-logs archhurd-build 2>/dev/null' \
  >"$OVDIR/guest-import.tar" 2>/dev/null || true
if [[ -s "$OVDIR/guest-import.tar" ]]; then
  tar -C "$ROOT/build/guest-import" -xf "$OVDIR/guest-import.tar" 2>/dev/null || true
fi

# Promote import metadata into packages (S4 scaffolding)
if [[ -x "$ROOT/scripts/import-guest-artifacts.sh" ]]; then
  bash "$ROOT/scripts/import-guest-artifacts.sh" || true
fi

echo "guest S3 capture: $GLOG"
echo "status=ssh_ok; see evidence and build/guest-import"
