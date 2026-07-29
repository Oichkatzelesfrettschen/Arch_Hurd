# Bounded agents

Orchestrator keeps: final claims, hazard decisions, merges, roadmap status, implementation.

Agents receive:

1. exact input paths (or URL list with byte ceiling)
2. allowed tools
3. closed output schema
4. row/byte ceilings
5. `must_not_claim` list
6. success criterion

Agents return a handback file only. They do not edit `frontier/CLAIMS_EVIDENCE.tsv` directly.

## Contracts

| File | Agent | Purpose |
|---|---|---|
| `contracts/A-oracle-pins.md` | A-oracle-pins | Pin Debian/Guix package versions |
| `contracts/A-hist-pkg.md` | A-hist-pkg | Inventory historical PKGBUILD names |
| `contracts/A-map-scripts.md` | A-map-scripts | Lexical maps for scripts |
| `contracts/A-pacman-port.md` | A-pacman-port | pacman Linuxism surface |

## Handback schema (TSV)

```
agent_id	row_id	kind	key	value	authority	confidence	notes
```

`confidence` in {known, hypothesized, speculative}.

## Invocation pattern

```bash
# Example: maps agent is implemented as make target (local)
make maps

# Future: validate handbacks
python3 scripts/validate_handback.py agents/handbacks/A-oracle-pins.tsv
```
