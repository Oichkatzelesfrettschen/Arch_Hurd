# Contract: A-hist-pkg

## Mission

Inventory package **directory names** from historical Arch Hurd PKGBUILD repos. Do not deep-read every PKGBUILD.

## Inputs

- https://api.github.com/repos/z3ntu/archhurd_packages/contents/ (single listing, pagination max 3 pages)
- Optional: local mirror if present under `/tmp` only if path passed explicitly

Max payload: 1.5 MiB

## Output

`agents/handbacks/A-hist-pkg.tsv`

Columns: agent_id, row_id, kind, key, value, authority, confidence, notes  
kind=package_name; key=name; value=path

Max 500 rows.

## must_not_claim

- That historical packages build on x86_64
- That versions are suitable for M0

## Success criterion

>= 20 package_name rows OR explicit empty with error note.
