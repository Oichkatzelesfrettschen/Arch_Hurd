#!/usr/bin/env bash
# Human-readable gate dashboard for Arch GNU/Hurd rebootstrap.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

echo "=== Arch GNU/Hurd status ==="
echo "root: $ROOT"
echo "time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "source_base: pure GNU Savannah (see SOURCE_POLICY.md)"
echo "alpm_arch: hurd_x86_64 (see IDENTITY.md)"
echo "glibc_strategy: guest-native (plan option a)"
echo "debian_role: reference/bootstrap corpus only"
echo

if [[ -f frontier/CLAIMS_EVIDENCE.tsv ]]; then
  total=$(($(wc -l < frontier/CLAIMS_EVIDENCE.tsv) - 1))
  known=$(awk -F'\t' 'NR>1 && $4=="known" {c++} END{print c+0}' frontier/CLAIMS_EVIDENCE.tsv)
  hyp=$(awk -F'\t' 'NR>1 && $4=="hypothesized" {c++} END{print c+0}' frontier/CLAIMS_EVIDENCE.tsv)
  echo "claims: total=$total known=$known hypothesized=$hyp"
else
  echo "claims: MISSING frontier/CLAIMS_EVIDENCE.tsv"
fi

if [[ -f frontier/ORACLE_PINS.tsv ]]; then
  # pinned-git and pinned both count as pinned product pins
  pinned=$(awk -F'\t' 'NR>1 && ($5=="pinned" || $5=="pinned-git" || $5=="known" || $5=="policy") {c++} END{print c+0}' frontier/ORACLE_PINS.tsv)
  unpinned=$(awk -F'\t' 'NR>1 && $5=="unpinned" {c++} END{print c+0}' frontier/ORACLE_PINS.tsv)
  ref=$(awk -F'\t' 'NR>1 && ($5=="inspiration-only" || $5=="reference" || $5=="future-donor" || $5=="legacy") {c++} END{print c+0}' frontier/ORACLE_PINS.tsv)
  echo "oracle pins: pinned_or_known=$pinned unpinned=$unpinned reference_or_legacy=$ref"
else
  echo "oracle pins: MISSING"
fi

if [[ -d build/cache/gnu/gnumach/.git ]]; then
  echo "fetch cache: pure GNU clones present under build/cache/gnu/"
elif [[ -f build/cache/SHA256SUMS ]]; then
  echo "fetch cache: $(wc -l < build/cache/SHA256SUMS | tr -d ' ') legacy hash files"
else
  echo "fetch cache: absent (run make fetch)"
fi

if [[ -f build/stage0/GNUMACH.ok ]]; then
  base=$(awk -F= '/^base=/{print $2}' build/stage0/GNUMACH.ok 2>/dev/null || echo unknown)
  echo "gnumach: BUILT ($base)"
elif [[ -f build/stage0/STAGE0_HEADERS.ok ]]; then
  echo "gnumach: headers only"
else
  echo "gnumach: not built"
fi

# multi-lane readiness
echo
echo "lanes:"
if pacman -Q gnumig >/dev/null 2>&1; then
  echo "  A host-mig: gnumig $(pacman -Q gnumig | awk '{print $2}')"
else
  echo "  A host-mig: missing (use make mig)"
fi
if [[ -d external-assets/images ]] && compgen -G 'external-assets/images/*' >/dev/null; then
  echo "  B guest-images: linked ($(ls external-assets/images 2>/dev/null | wc -l | tr -d ' ') entries)"
else
  echo "  B guest-images: not linked (make link-assets)"
fi
if [[ -d "$HOME/Github/gnu-hurd-docker" ]]; then
  echo "  C gnu-hurd-docker: present"
else
  echo "  C gnu-hurd-docker: absent"
fi
if [[ -x build/stage0/bin/mig && -f build/stage0/boot/gnumach ]]; then
  echo "  E stage0: headers+mig+gnumach ready"
else
  echo "  E stage0: incomplete"
fi

echo
echo "M0 gate checklist (documentation truth, not runtime proof):"
gates=(
  "docs/research/2026-hurd-landscape.md"
  "docs/research/novel-insights.md"
  "docs/architecture/bootstrap-ladder.md"
  "docs/architecture/SOURCE_POLICY.md"
  "docs/architecture/DEV_ENVIRONMENTS.md"
  "docs/roadmap/ULTRA_ROADMAP.md"
  "packages/base/PACKAGE_SET.md"
  "scripts/mkhurdroot.sh"
  "scripts/qemu-smoke.sh"
)
for g in "${gates[@]}"; do
  if [[ -f "$g" ]]; then
    echo "  [doc] $g"
  else
    echo "  [MISS] $g"
  fi
done

if compgen -G 'evidence/captures/m0-*' >/dev/null; then
  echo "M0 evidence: PRESENT"
else
  echo "M0 evidence: ABSENT (need full boot+pacman; kernel-only is P3)"
fi
if [[ -f evidence/captures/p3-gnumach-pure-gnu-success.txt ]] || [[ -f evidence/captures/p3-gnumach-success.txt ]]; then
  echo "P3 gnumach evidence: PRESENT"
fi
if compgen -G 'evidence/captures/guest-tooling-*' >/dev/null; then
  echo "guest tooling evidence: PRESENT"
else
  echo "guest tooling evidence: ABSENT"
fi

echo
echo "Next: guest-native pure glibc+hurd (strategy a); then rump root + pacman + m0 smoke."
