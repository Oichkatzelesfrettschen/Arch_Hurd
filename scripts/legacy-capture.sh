#!/usr/bin/env bash
# Record digests for files under legacy/. Optional network capture of known URLs.
# Usage:
#   scripts/legacy-capture.sh              # rehash local legacy tree
#   ARCH_HURD_LEGACY_NET=1 scripts/legacy-capture.sh   # also try public snapshots
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LEGACY="$ROOT/legacy"
UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NET=${ARCH_HURD_LEGACY_NET:-0}

mkdir -p "$LEGACY"/{website,wiki,package-database,package-sources,binary-packages,mailing-list-material,git}

if [[ "$NET" == "1" ]]; then
  # Best-effort public surfaces (do not fail product build if unreachable)
  mkdir -p "$LEGACY/website"
  curl -fsSL --max-time 30 -o "$LEGACY/website/archhurd.org-index.html" \
    https://archhurd.org/ 2>/dev/null || \
    echo "WARN: could not fetch archhurd.org" >&2
fi

python3 - "$LEGACY" "$UTC" <<'PY'
import hashlib, sys
from pathlib import Path
legacy = Path(sys.argv[1])
utc = sys.argv[2]
rows = ["path\tsha256\tbytes\tsource_url\tcaptured_utc\toriginal_timestamp\tnotes"]
for p in sorted(legacy.rglob("*")):
    if not p.is_file():
        continue
    if p.name == "INTEGRITY.tsv":
        continue
    rel = str(p.relative_to(legacy))
    data = p.read_bytes()
    h = hashlib.sha256(data).hexdigest()
    url = "local:repo"
    notes = ""
    if rel.startswith("binary-packages/"):
        notes = "never product deps"
    if rel.endswith(".html"):
        url = "https://archhurd.org/"
    rows.append(f"{rel}\t{h}\t{len(data)}\t{url}\t{utc}\t\t{notes}")
(legacy / "INTEGRITY.tsv").write_text("\n".join(rows) + "\n", encoding="ascii")
print(f"legacy integrity rows: {len(rows)-1}")
PY

echo "legacy capture complete: $LEGACY/INTEGRITY.tsv"
