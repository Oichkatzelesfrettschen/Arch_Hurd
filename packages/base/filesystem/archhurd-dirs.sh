#!/usr/bin/env bash
# Create Arch-like directory layout for GNU/Hurd root.
# Translator attachment is a separate step (xattrs / settrans on Hurd).
set -euo pipefail

ROOT=${1:-}
if [[ -z "${ROOT}" ]]; then
  echo "usage: $0 <destdir>" >&2
  exit 2
fi

dirs=(
  bin boot dev etc etc/pacman.d home lib libexec mnt opt proc root run
  sbin srv tmp usr usr/bin usr/include usr/lib usr/libexec usr/local
  usr/local/bin usr/local/include usr/local/lib usr/local/sbin usr/local/share
  usr/sbin usr/share usr/share/hurd usr/share/man var var/cache var/lib
  var/lib/pacman var/log var/spool var/tmp
  servers servers/socket
)

for d in "${dirs[@]}"; do
  mkdir -p "${ROOT}/${d}"
done

# Sticky and permission baselines (host-side staging).
chmod 1777 "${ROOT}/tmp" "${ROOT}/var/tmp" || true
chmod 0755 "${ROOT}/home" "${ROOT}/root" || true

# Minimal hosts/passwd placeholders for staging (overwritten by packages).
if [[ ! -e "${ROOT}/etc/hosts" ]]; then
  printf '127.0.0.1\tlocalhost\n' > "${ROOT}/etc/hosts"
fi

cat > "${ROOT}/usr/share/hurd/README.layout" <<'EOF'
Arch GNU/Hurd directory layout scaffold.
On a live Hurd system, attach translators per translator-policy.txt
using settrans or xattr-encoded translator records for host-side bootstrap.
EOF

echo "layout created under ${ROOT}"
