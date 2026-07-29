# Contract: A-map-scripts

## Mission

Produce lexical call maps for all `scripts/*.sh` using cflow and cscope. Structure only.

## Inputs

- `scripts/*.sh` in repo root only
- Max aggregate source: 512 KiB

## Allowed tools

cflow, cscope, ctags, rg, sha256sum

## Output

- `analysis/maps/scripts.cflow.txt`
- `analysis/maps/scripts.cscope.files`
- `analysis/maps/MAP_MANIFEST.tsv` (path, tool, sha256, bytes)

## must_not_claim

- Runtime reachability
- Security properties
- That scripts successfully bootstrap Hurd

## Success criterion

Manifest lists every scripts/*.sh; cflow file non-empty if any functions exist.
