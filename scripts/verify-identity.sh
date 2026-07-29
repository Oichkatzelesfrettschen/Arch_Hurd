#!/usr/bin/env bash
# Enforce ArchHurd product identity: hurd_x86_64 ALPM arch + Debian-as-reference.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
fail=0

echo "== product identity gate =="

if [[ ! -f docs/architecture/IDENTITY.md ]]; then
  echo "FAIL: missing docs/architecture/IDENTITY.md" >&2
  fail=1
else
  if ! rg -q 'hurd_x86_64' docs/architecture/IDENTITY.md; then
    echo "FAIL: IDENTITY.md missing hurd_x86_64" >&2
    fail=1
  else
    echo "OK IDENTITY.md declares hurd_x86_64"
  fi
fi

if [[ ! -f config/target/pacman.conf.fragment ]]; then
  echo "FAIL: missing config/target/pacman.conf.fragment" >&2
  fail=1
else
  if ! rg -q '^Architecture = hurd_x86_64' config/target/pacman.conf.fragment; then
    echo "FAIL: pacman fragment must set Architecture = hurd_x86_64" >&2
    fail=1
  else
    echo "OK target pacman Architecture = hurd_x86_64"
  fi
  if rg -q 'archlinux\.org|mirror\.rackspace\.com/archlinux' config/target/pacman.conf.fragment; then
    echo "FAIL: target pacman must not enable Arch Linux mirrors" >&2
    fail=1
  else
    echo "OK no Arch Linux mirrors in target fragment"
  fi
fi

# Product PKGBUILDs under packages/base (except host-only notes) must use hurd_x86_64
while IFS= read -r -d '' f; do
  # skip pure docs
  if [[ "$f" == *'/host/'* ]]; then
    continue
  fi
  if rg -q "arch=\\('x86_64'\\)|arch=\\(\"x86_64\"\\)" "$f"; then
    echo "FAIL: $f still uses arch=('x86_64'); product must be hurd_x86_64" >&2
    fail=1
  elif rg -q "arch=\\('hurd_x86_64'\\)|arch=\\(\"hurd_x86_64\"\\)|arch=\\('any'\\)" "$f"; then
    echo "OK $f product arch"
  else
    # allow empty scaffolds without arch line only if marked host
    if rg -q "^arch=" "$f"; then
      echo "FAIL: $f arch= line not hurd_x86_64/any" >&2
      fail=1
    else
      echo "WARN $f has no arch= line"
    fi
  fi
done < <(find packages -name PKGBUILD -print0)

# Debian must be reference language in SOURCE_POLICY / IDENTITY
if ! rg -qi 'reference|inspiration' docs/architecture/SOURCE_POLICY.md; then
  echo "FAIL: SOURCE_POLICY must label Debian as reference/inspiration" >&2
  fail=1
else
  echo "OK SOURCE_POLICY labels Debian as non-base"
fi

if [[ "$fail" -ne 0 ]]; then
  echo "verify-identity FAILED" >&2
  exit 1
fi
echo "verify-identity PASSED"
exit 0
