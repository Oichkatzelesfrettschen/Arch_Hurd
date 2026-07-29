#!/usr/bin/env bash
# Host preflight for Arch GNU/Hurd bootstrap work.
# Exit 0 if minimum host tools exist; non-zero lists gaps.
set -euo pipefail

need_cmd() {
  local c=$1
  if command -v "$c" >/dev/null 2>&1; then
    printf 'OK  %s -> %s\n' "$c" "$(command -v "$c")"
    return 0
  fi
  printf 'MISS %s\n' "$c"
  return 1
}

echo "== Arch GNU/Hurd host preflight =="
echo "date_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "uname: $(uname -a)"

miss=0
for c in bash git make python3 rg curl sha256sum qemu-system-x86_64; do
  need_cmd "$c" || miss=$((miss + 1))
done

echo "-- analysis tools (recommended) --"
for c in cflow cscope gtags ctags; do
  need_cmd "$c" || true
done

echo "-- cross / Hurd tooling (may be missing on day one) --"
for c in mig x86_64-pc-gnu-gcc x86_64-gnu-gcc; do
  need_cmd "$c" || true
done

echo "-- package identity for mig --"
if command -v pacman >/dev/null 2>&1 && pacman -Q gnumig >/dev/null 2>&1; then
  echo "OK  pacman package gnumig -> $(pacman -Q gnumig)"
else
  echo "NOTE gnumig package not installed (AUR empty; use OS-Projects/mig-gnu or make mig)"
fi

echo "-- local guest environments (optional) --"
if [[ -d "$HOME/Github/gnu-hurd-docker" ]]; then
  echo "OK  gnu-hurd-docker present (Docker/QEMU Hurd guest project)"
else
  echo "NOTE gnu-hurd-docker absent"
fi
if [[ -d "$HOME/Github/OS-Projects/mig-gnu" ]]; then
  echo "OK  mig-gnu PKGBUILD tree present"
fi

if [[ "$miss" -gt 0 ]]; then
  echo "preflight: ${miss} required command(s) missing" >&2
  exit 1
fi
echo "preflight: required tools present"
echo "tip: make scan-tools && make link-assets && make guest-hint"
exit 0
