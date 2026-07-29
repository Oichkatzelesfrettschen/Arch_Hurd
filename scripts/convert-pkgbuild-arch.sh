#!/usr/bin/env bash
# Convert Arch Linux PKGBUILD arch=('x86_64') to product arch=('hurd_x86_64').
# Usage: scripts/convert-pkgbuild-arch.sh path/to/PKGBUILD [more...]
# Does not rewrite host bootstrap packages under packages/host/.
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 PKGBUILD..." >&2
  exit 2
fi

for f in "$@"; do
  if [[ ! -f "$f" ]]; then
    echo "missing $f" >&2
    exit 1
  fi
  if [[ "$f" == *'/packages/host/'* ]]; then
    echo "skip host package $f"
    continue
  fi
  # Replace common Arch arch arrays; leave 'any' alone.
  tmp=$(mktemp)
  sed -E \
    -e "s/arch=\\(['\"]x86_64['\"]\\)/arch=('hurd_x86_64')/g" \
    -e "s/arch=\\(['\"]x86_64['\"] [[:space:]]*['\"]i686['\"]\\)/arch=('hurd_x86_64')/g" \
    "$f" > "$tmp"
  if ! cmp -s "$f" "$tmp"; then
    mv "$tmp" "$f"
    echo "converted $f -> hurd_x86_64"
  else
    rm -f "$tmp"
    echo "unchanged $f"
  fi
  # Ensure xdata provenance hints if missing
  if ! rg -q "xdata=" "$f" && rg -q "arch=\\('hurd_x86_64'\\)" "$f"; then
    # insert after arch= line
    awk '
      /^arch=\(/ && !done {
        print
        print "xdata=("
        print "  '\''osabi=hurd-gnu'\''"
        print "  '\''gnu_tuple=x86_64-gnu'\''"
        print ")"
        done=1
        next
      }
      { print }
    ' "$f" > "$tmp"
    mv "$tmp" "$f"
    echo "added xdata to $f"
  fi
done
