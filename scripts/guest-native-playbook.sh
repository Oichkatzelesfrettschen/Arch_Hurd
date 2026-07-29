#!/usr/bin/env bash
# Emit a guest-native build playbook for pure Savannah glibc+hurd (strategy a).
# Optionally copy sources into build/guest-share/ for 9p/virtio sharing.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SHARE="$ROOT/build/guest-share"
GNU="$ROOT/build/cache/gnu"
OUT="$ROOT/docs/architecture/GUEST_NATIVE_PLAYBOOK.md"
MODE=${1:-emit}

mkdir -p "$SHARE"

emit_doc() {
  cat > "$OUT" <<'EOF'
# Guest-native playbook: pure glibc + hurd (strategy a)

**Domain:** Hurd VM (gnu-hurd-docker or `make guest-shell-run`).  
**Product sources:** Savannah only. Guest OS may be Debian Hurd for tooling only.

## Host prep

```bash
make fetch link-assets
make guest-shell   # print launch
# Share pure trees:
scripts/guest-native-playbook.sh sync-share
```

Share directory: `build/guest-share/{gnumach,mig,hurd,glibc}` (git checkouts).

## Launch guest

```bash
ARCH_HURD_QEMU_ACK=yes make guest-shell-run
# ssh -p 2222 root@127.0.0.1
```

## On guest (outline)

```bash
# 1) build tools
apt-get update || true
apt-get install -y build-essential autoconf automake gawk bison flex texinfo git

# 2) use shared trees or re-clone Savannah
# 3) headers already usable from gnumach; rebuild mig if needed
# 4) configure glibc for Hurd --host=x86_64-gnu (see glibc Hurd docs)
# 5) build/install glibc to a sysroot
# 6) configure/build hurd against that sysroot
# 7) install rumpdisk translators; document noide if needed
# 8) scp logs back to host evidence/captures/guest-native-*.txt
```

## Host evidence after guest work

```bash
# from host, after collecting logs:
# evidence/captures/guest-native-$(date -u +%Y%m%dT%H%M%SZ).txt
```

## Exit gates

| Gate | Signal |
|---|---|
| glibc | `libc.so` for Hurd in sysroot + log |
| hurd | `/hurd/ext2fs` (or install prefix) + log |
| rump | boot note with rumpdisk |
| product | packages reimported as `hurd_x86_64` PKGBUILDs |

## Non-claims

Running Debian packages inside the guest is **not** ArchHurd M0.
EOF
  echo "wrote $OUT"
}

sync_share() {
  [[ -d "$GNU/gnumach/.git" ]] || { echo "make fetch first" >&2; exit 1; }
  for c in gnumach mig hurd glibc; do
    if [[ -d "$GNU/$c/.git" ]]; then
      rm -rf "$SHARE/$c"
      git clone --local "$GNU/$c" "$SHARE/$c"
      echo "synced $c -> $SHARE/$c @ $(git -C "$SHARE/$c" rev-parse --short HEAD)"
    else
      echo "WARN missing $GNU/$c"
    fi
  done
  {
    echo "utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "share=$SHARE"
    for c in gnumach mig hurd glibc; do
      if [[ -d "$SHARE/$c/.git" ]]; then
        echo "$c=$(git -C "$SHARE/$c" rev-parse HEAD)"
      fi
    done
  } > "$SHARE/MANIFEST.txt"
  echo "share ready: $SHARE"
}

case "$MODE" in
  emit) emit_doc ;;
  sync-share) sync_share; emit_doc ;;
  *) echo "usage: $0 [emit|sync-share]" >&2; exit 2 ;;
esac
