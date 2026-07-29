#!/usr/bin/env bash
# Import guest-native S3 results into hurd_x86_64 package/stage metadata (S4-S8 path).
# Does not claim M0 closed; records provenance for package PKGBUILDs and stage notes.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
IMP="$ROOT/build/guest-import"
EVID="$ROOT/evidence/captures"
PKG="$ROOT/packages/base"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$EVID/guest-import-${STAMP}.txt"
META="$IMP/IMPORT_META.txt"

mkdir -p "$IMP" "$EVID"

{
  echo "utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "stage=S4_import_scaffold"
  echo "import_dir=$IMP"

  # Scan guest logs / build dirs
  if [[ -d "$IMP/archhurd-logs" ]]; then
    echo "logs:"
    find "$IMP/archhurd-logs" -type f | sort
  else
    echo "logs: none under $IMP/archhurd-logs"
  fi

  glibc_cfg=0 hurd_cfg=0 make_ok=0
  if rg -q "configure_exit=0" "$IMP/archhurd-logs" 2>/dev/null || rg -q "configure_exit=0" "$IMP/archhurd-logs"/*.log 2>/dev/null; true "$IMP/archhurd-logs" 2>/dev/null; then glibc_cfg=1; fi
  if rg -q 'hurd_configure_exit=0' "$IMP/archhurd-logs" 2>/dev/null; then hurd_cfg=1; fi
  if rg -q 'make_exit=0' "$IMP/archhurd-logs" 2>/dev/null; then make_ok=1; fi
  echo "glibc_configure_ok=$glibc_cfg"
  echo "hurd_configure_ok=$hurd_cfg"
  echo "glibc_make_ok=$make_ok"

  # Pin SHAs from share manifest if present
  if [[ -f "$ROOT/build/guest-share/MANIFEST.txt" ]]; then
    echo "--- guest-share MANIFEST ---"
    cat "$ROOT/build/guest-share/MANIFEST.txt"
  fi

  # Update package SOURCE docs with import stamp (non-claiming)
  for name in glibc hurd gnumach mig rumpdisk; do
    d="$PKG/$name"
    [[ -d "$d" ]] || continue
    note="$d/GUEST_IMPORT.txt"
    {
      echo "utc=$STAMP"
      echo "package=$name"
      echo "arch=hurd_x86_64"
      echo "import_meta=$OUT"
      echo "status=scaffold"
      echo "notes=Guest S3 artifacts staged under build/guest-import; not yet installed as ALPM package."
      if [[ -f "$ROOT/build/guest-share/MANIFEST.txt" ]]; then
        rg "^${name}=" "$ROOT/build/guest-share/MANIFEST.txt" || true
      fi
    } >"$note"
    echo "wrote $note"
  done

  # S4-S8 checklist snapshot
  cat <<'EOF'
--- S4-S8 next gates ---
S4: install pure hurd servers into product root once glibc+hurd build
S5: wire rumpdisk; document noide if IDE path hangs
S6: pacman 7.x on Hurd (PKGBUILD packages/base/pacman)
S7: assemble disk image (ext2 + translators)
S8: QEMU smoke + evidence/captures/m0-*
EOF

  # Cross binutils status (S2)
  if [[ -f "$ROOT/build/cross/CROSS_BINUTILS.ok" ]]; then
    echo "--- S2 cross-binutils ---"
    cat "$ROOT/build/cross/CROSS_BINUTILS.ok"
  fi
} | tee "$OUT" | tee "$META"

# Refresh PACKAGE_SET status line if S2/S3 advanced
if [[ -f "$PKG/PACKAGE_SET.md" ]]; then
  python3 - <<'PY'
from pathlib import Path
from datetime import datetime, timezone
p = Path("packages/base/PACKAGE_SET.md")
text = p.read_text(encoding="ascii", errors="replace")
stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")
# Ensure S2/S3 notes exist once
needle = "## Build status"
if needle in text and "cross-binutils S2" not in text:
    insert = (
        f"\n### Runtime progress ({stamp})\n\n"
        "- cross-binutils S2: see `build/cross/CROSS_BINUTILS.ok` and "
        "`evidence/captures/cross-binutils-*.log`\n"
        "- guest-native S3: see `evidence/captures/guest-native-*.txt` and "
        "`build/guest-import/`\n"
        "- package import scaffold: `packages/base/*/GUEST_IMPORT.txt`\n"
    )
    text = text.replace(needle, insert + "\n" + needle, 1)
    p.write_text(text, encoding="ascii")
    print("updated", p)
else:
    print("PACKAGE_SET unchanged or already annotated")
PY
fi

echo "import capture: $OUT"
