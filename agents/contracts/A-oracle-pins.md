# Contract: A-oracle-pins

## Mission

Extract **exact** version strings for gnumach, hurd, glibc/libc0.3, rumpkernel, mig from public Debian and/or Guix metadata for hurd-amd64 / x86_64-gnu.

## Inputs (bounded)

- URLs only from this allowlist:
  - https://packages.debian.org/sid/gnumach
  - https://packages.debian.org/sid/hurd
  - https://packages.debian.org/sid/libc0.3
  - https://packages.debian.org/sid/rumpkernel
  - https://packages.debian.org/sid/mig
  - https://guix.gnu.org/en/blog/2026/the-64-bit-hurd/ (version class only if no package page)
- Max total downloaded HTML: 2 MiB
- Do not recurse into source packages beyond the version field

## Allowed tools

web_fetch / curl GET; local write only under `agents/handbacks/`

## Output

File: `agents/handbacks/A-oracle-pins.tsv`

Schema:

```
agent_id	row_id	kind	key	value	authority	confidence	notes
```

At most 40 rows. ASCII only.

## must_not_claim

- That versions boot Arch Hurd
- That M0 is complete
- That i686 is required
- Any security vulnerability assessment

## Success criterion

At least 3 components have non-TBD `value` with `confidence=known` and a concrete version string.
