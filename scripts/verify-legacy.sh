#!/usr/bin/env bash
# Validate legacy preservation surface schema and product isolation.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
fail=0

echo "== legacy surface gate =="

for req in legacy/README.md legacy/INTEGRITY.tsv legacy/INTEGRITY.schema.md; do
  if [[ ! -f "$req" ]]; then
    echo "FAIL missing $req" >&2
    fail=1
  else
    echo "OK $req"
  fi
done

if [[ -f legacy/INTEGRITY.tsv ]]; then
  hdr=$(head -n1 legacy/INTEGRITY.tsv)
  exp=$'path\tsha256\tbytes\tsource_url\tcaptured_utc\toriginal_timestamp\tnotes'
  if [[ "$hdr" != "$exp" ]]; then
    echo "FAIL INTEGRITY.tsv header mismatch" >&2
    echo " got: $hdr" >&2
    fail=1
  else
    echo "OK INTEGRITY.tsv header"
  fi
  rows=$(($(wc -l < legacy/INTEGRITY.tsv) - 1))
  if [[ "$rows" -lt 1 ]]; then
    echo "FAIL INTEGRITY.tsv has no data rows" >&2
    fail=1
  else
    echo "OK INTEGRITY.tsv rows=$rows"
  fi
  if ! rg -q 'sha256' legacy/INTEGRITY.schema.md; then
    echo "FAIL schema missing sha256 field docs" >&2
    fail=1
  fi
fi

# Product build/fetch scripts must not install from legacy/binary-packages
# Exclude verifiers and docs that only mention the ban.
hits=$(rg -n 'legacy/binary-packages' scripts packages \
  --glob '!scripts/verify-*.sh' \
  --glob '!scripts/legacy-capture.sh' \
  --glob '!legacy/**' \
  2>/dev/null | rg -v 'never|must not|ignore|placeholder|schema' || true)
if [[ -n "$hits" ]]; then
  echo "FAIL product path references legacy/binary-packages:" >&2
  echo "$hits" >&2
  fail=1
else
  echo "OK product paths do not depend on legacy binaries"
fi

for d in website wiki package-database package-sources binary-packages; do
  if [[ ! -d "legacy/$d" ]]; then
    echo "FAIL missing legacy/$d" >&2
    fail=1
  fi
done

if [[ "$fail" -ne 0 ]]; then
  echo "verify-legacy FAILED" >&2
  exit 1
fi
echo "verify-legacy PASSED"
exit 0
