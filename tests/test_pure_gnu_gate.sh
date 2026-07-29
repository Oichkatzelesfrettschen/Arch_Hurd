#!/usr/bin/env bash
# Drive real pure-GNU product default verifier (shipped entrypoint).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
bash scripts/verify-pure-gnu-default.sh
# Negative control: product fetch must not mention debian pool
if rg -n 'deb\.debian\.org' scripts/fetch-sources.sh; then
  echo "FAIL fetch-sources polluted" >&2
  exit 1
fi
echo "PASS test_pure_gnu_gate"
