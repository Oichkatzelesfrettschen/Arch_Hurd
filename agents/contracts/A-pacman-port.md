# Contract: A-pacman-port

## Mission

List Linux-specific APIs and features in upstream pacman/libalpm that historically block or risk Hurd builds (sandbox, mount, namespace, download backends, path assumptions).

## Inputs

- Public pacman source documentation or a single release tarball path if provided
- Historical note: z3ntu/archhurd_pacman (README only unless path given)
- Byte ceiling: 3 MiB

## Output

`agents/handbacks/A-pacman-port.tsv` with kind in {api, feature, build_flag, patch_hint}

Max 60 rows.

## must_not_claim

- That a full port is finished
- CVE analysis

## Success criterion

>= 5 concrete feature/api rows with confidence != empty
