#!/usr/bin/env bash
# Repository sanity checks (offline).
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
fail=0

echo "== script syntax =="
for s in scripts/*.sh; do
  bash -n "$s"
  echo "OK bash -n $s"
done

echo "== python =="
python3 -m py_compile scripts/validate_handback.py
echo "OK py_compile validate_handback.py"

echo "== claims header =="
head -n1 frontier/CLAIMS_EVIDENCE.tsv | grep -q $'^claim_id\t'
echo "OK claims header"

echo "== source manifest header =="
head -n1 frontier/SOURCE_MANIFEST.tsv | grep -q $'^component\t'
echo "OK source manifest"

echo "== ASCII check (scripts + frontier + Makefile) =="
for f in scripts/*.sh scripts/*.py frontier/*.tsv Makefile; do
  [[ -f "$f" ]] || continue
  if ! python3 -c "from pathlib import Path; Path(r'''$f''').read_text(encoding='ascii')" 2>/dev/null; then
    echo "NON-ASCII: $f" >&2
    fail=1
  fi
done

echo "== filesystem layout script dry-run =="
tmp=$(mktemp -d)
bash packages/base/filesystem/archhurd-dirs.sh "$tmp"
test -d "$tmp/usr/share/hurd"
test -d "$tmp/servers/socket"
rm -rf "$tmp"
echo "OK archhurd-dirs.sh"

echo "== mkhurdroot scaffold =="
bash scripts/mkhurdroot.sh "$ROOT/build/hurd-root-check"
test -f "$ROOT/build/hurd-root-check/var/lib/archhurd/root-stage"
test -f "$ROOT/build/hurd-root-check/etc/pacman.conf"
echo "OK mkhurdroot"

echo "== required docs =="
for d in \
  docs/roadmap/EXECUTION_PLAN.md \
  docs/roadmap/ULTRA_ROADMAP.md \
  docs/research/novel-insights.md \
  docs/architecture/SOURCE_POLICY.md \
  docs/architecture/DEV_ENVIRONMENTS.md \
  docs/architecture/GLIBC_STRATEGY.md \
  docs/architecture/IDENTITY.md \
  docs/architecture/STAGE_GRAPH.md \
  packages/base/PACKAGE_SET.md
 do
  test -f "$d" || { echo "missing $d" >&2; fail=1; }
done
echo "OK docs"

echo "== pure-GNU product default =="
bash scripts/verify-pure-gnu-default.sh || fail=1

echo "== product identity (hurd_x86_64) =="
bash scripts/verify-identity.sh || fail=1

echo "== legacy preservation =="
bash scripts/verify-legacy.sh || fail=1

echo "== handbacks (if present) =="
shopt -s nullglob
hbs=(agents/handbacks/*.tsv)
if [[ ${#hbs[@]} -eq 0 ]]; then
  echo "NOTE no handbacks present"
else
  for h in "${hbs[@]}"; do
    python3 scripts/validate_handback.py "$h" || fail=1
  done
fi

if [[ "$fail" -ne 0 ]]; then
  echo "check FAILED" >&2
  exit 1
fi
echo "check PASSED"
