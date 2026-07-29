# legacy/ -- historical ArchHurd preservation (read-only intent)

This namespace preserves **prior ArchHurd public material** for archaeology:
patches, package names, design decisions, wiki text, and timestamps.

## Rules

1. Product bootstrap paths **must not** install or depend on binaries under `legacy/`.
2. Never treat legacy i686 packages as a current rolling distribution.
3. Capture digests into `legacy/INTEGRITY.tsv` (or via `scripts/legacy-capture.sh`).
4. Content under subdirectories may be incomplete offline; the schema still holds.

## Layout

```text
legacy/
├── README.md                 # this file
├── INTEGRITY.tsv             # SHA-256 ledger (schema)
├── INTEGRITY.schema.md       # field definitions
├── website/                  # snapshots of archhurd.org surfaces
├── wiki/                     # wiki export / notes
├── package-database/         # package list dumps
├── package-sources/          # PKGBUILD archaeology (optional clones)
├── binary-packages/          # never used as product deps
├── mailing-list-material/    # optional
└── git/                      # optional mirrors of historical git
```

## Classification

**Archival but recoverable as source history.** Not a functioning distribution.
