# System walkthrough and interconnected components

## Components

1. **Research layer** (`docs/research/*`)  
   Grounds product decisions in Debian 2025, FOSDEM 2026, Guix 2026, historical Arch Hurd.

2. **Claims layer** (`frontier/*`)  
   Every load-bearing statement is a row with authority and falsifier.

3. **Agent layer** (`agents/*`)  
   Token-disciplined workers for inventory and maps; no claim authority.

4. **Package layer** (`packages/base/*`)  
   PKGBUILD scaffolds for M0: gnumach, hurd, rumpdisk, pacman, filesystem.

5. **Bootstrap layer** (`scripts/*`)  
   preflight, mkhurdroot, qemu-smoke, maps, check, status.

6. **Evidence layer** (`evidence/*`)  
   Retained captures; empty until first real boot/build.

## Data flow

```
Web/oracle sources
    -> research docs + ORACLE_PINS
    -> PKGBUILD real sources
    -> cross build / host stage (mkhurdroot)
    -> QEMU smoke
    -> evidence/captures
    -> claim status transitions
```

## Deficiencies (live)

- Oracle pins unfilled (TBD-extract)
- PKGBUILD sources empty by design until pins land
- No image build path implemented
- No CI runner config yet
- C call graphs wait on C sources (tools/ empty)

## Harmonization rule

When Debian and historical Arch Hurd disagree, **modern Hurd behavior wins** for kernel/servers; **Arch packaging conventions win** for repo layout and user workflow.
