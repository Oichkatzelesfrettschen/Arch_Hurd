#!/usr/bin/env bash
# Drive real legacy verifier and integrity schema.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
bash scripts/verify-legacy.sh
# Schema columns present
hdr=$(head -n1 legacy/INTEGRITY.tsv)
echo "$hdr" | rg -q $'path\tsha256\tbytes\tsource_url\tcaptured_utc'
# At least one hashed row with real sha256 (64 hex)
awk -F'\t' 'NR>1 && $2 ~ /^[0-9a-f]{64}$/ {c++} END{if(c<1){exit 1}}' legacy/INTEGRITY.tsv
echo "PASS test_legacy"
