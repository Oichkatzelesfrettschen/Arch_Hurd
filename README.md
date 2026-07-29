# Arch GNU/Hurd (modern rebootstrap)

**Status:** research-grounded greenfield rebootstrap (2026-07-26).  
**Target triple:** `x86_64-pc-gnu` (primary). Historical `i686-pc-gnu` is archival only.  
**Identity:** Arch Linux packaging model (pacman, PKGBUILD, rolling, KISS) on **pure GNU Hurd + GNU Mach** (Savannah).

**Source base:** GNU Hurd project git on Savannah (`gnumach`, `mig`, `hurd`).  
**Debian/Guix:** inspiration for process, QEMU tips, and optional patch *ideas* only — **not** the product base.  
See [`docs/architecture/SOURCE_POLICY.md`](docs/architecture/SOURCE_POLICY.md).

## Why this exists now

The prior Arch Hurd effort (forum 2010, LiveCDs ~2010-2011, z3ntu bootstrap 2018, packages last meaningfully updated ~2019) targeted **i686** with glibc ~2.29 and pre-Rump driver stacks. In parallel, GNU/Hurd crossed several hard thresholds:

| Breakthrough | When | Authority |
|---|---|---|
| Debian GNU/Hurd 2025: complete x86_64, Rump disk, USB, Rust, SMP packages, ~72% archive | 2025-08-10 | debian.org ports news |
| FOSDEM 2026: "almost there"; rump, SMP, 64-bit, ~75% Debian packages; Arch/Alpine/Guix named | 2026-02-01 | Samuel Thibault talk |
| Guix: native `x86_64-gnu` childhurds, RumpNET i8254x, installer option | 2026-03-01 | guix.gnu.org blog |
| LWN call for Arch Hurd re-bootstrap volunteers | 2025-08-12 | lwn.net |

The open gap is **not** "does Hurd boot on amd64?" It is: **can Arch rolling + pacman sit on that substrate cleanly?**

## Novel synthesis (load-bearing)

1. **Pure GNU base** -- build gnumach/mig/hurd from Savannah; Arch is packaging identity only.
2. **Distros as inspiration** -- Debian/Guix teach bootstrap process, QEMU flags, patch *candidates*; they are not the source of truth.
3. **Rump-first hardware** -- `rumpdisk` / `rumpnet` live in pure `hurd.git`; package them as first-class Arch base units.
4. **x86_64-only primary** -- abandon i686 as the default.
5. **Cross-then-native ladder** -- Linux host -> pure GNU stage0 -> rootfs -> QEMU q35 -> native rebuild.

Full derivation: [`docs/research/2026-hurd-landscape.md`](docs/research/2026-hurd-landscape.md)  
Insights and coefficients: [`docs/research/novel-insights.md`](docs/research/novel-insights.md)  
Roadmap: [`docs/roadmap/ULTRA_ROADMAP.md`](docs/roadmap/ULTRA_ROADMAP.md)  
Claims/evidence: [`frontier/CLAIMS_EVIDENCE.tsv`](frontier/CLAIMS_EVIDENCE.tsv)

## Repository map

```
docs/           research, architecture, roadmap (human + agent readable)
frontier/       claims, falsifiers, completion gates
agents/         bounded agent contracts (token-disciplined handbacks)
packages/       PKGBUILD trees for base/core (x86_64-pc-gnu)
scripts/        bootstrap, verification, map generation
evidence/       retained research captures and instrumented maps
analysis/maps/  cflow/cscope/lexical call maps (structure only)
tools/          local helpers
```

## Quick start (multi-lane)

```bash
# 0) Inventory host packages, docker, local QEMU images
make scan-tools
make link-assets    # symlink ~/Github/gnu-hurd-docker images + mig-gnu
make guest-hint     # print QEMU command (no launch)

# 1) Pure GNU product path (Savannah base)
make plan check
make fetch stage0 mig gnumach root repo maps
```

**Host MIG:** this workstation already has **`gnumig`** (`pacman -Q gnumig`) from `~/Github/OS-Projects/mig-gnu`. Prefer **`make mig`** when building against latest Savannah gnumach defs.

**Guest Hurd (tooling):** reuse `~/Github/gnu-hurd-docker` (Docker+QEMU, existing qcow2 images). That is a **guest environment**, not the Arch package base. See [`docs/architecture/DEV_ENVIRONMENTS.md`](docs/architecture/DEV_ENVIRONMENTS.md).

**glibc strategy (locked):** guest-native pure Savannah builds -- option **(a)**. See [`docs/architecture/GLIBC_STRATEGY.md`](docs/architecture/GLIBC_STRATEGY.md). Launch lab with `make guest-shell` / `ARCH_HURD_QEMU_ACK=yes make guest-shell-run`.

Proven pure path (2026-07-26): **`make gnumach`** produces ELF64 kernel from Savannah with no Debian patches.  
Still required for M0: Hurd servers, glibc, pacman, boot evidence.

See [`docs/roadmap/EXECUTION_PLAN.md`](docs/roadmap/EXECUTION_PLAN.md).

## Design constraints

- Real solutions only: no hardcoded "demo rootfs" that cannot rebuild.
- ASCII-first docs and scripts (no smart quotes).
- Every load-bearing claim carries: authority, falsifier, validation command, artifact path.
- Call graphs are **lexical structure**, not runtime proof.
- Hazardous QEMU/image writes require explicit operator approval.

## Relation to historical Arch Hurd

| Surface | Historical (archhurd.org / z3ntu) | This repo |
|---|---|---|
| Arch | i686 | x86_64-pc-gnu primary |
| glibc | ~2.29 era | track current glibc with Hurd support |
| Drivers | DDE / Linux glue | Rump userland disk/net |
| Init | OpenRC experiments | TBD: OpenRC or lightweight Arch-compatible init (see roadmap) |
| Bootstrap | rebuild from dead ISO | seed from Debian/Guix oracle + Arch PKGBUILD |

## License

Documentation: CC-BY-SA 4.0 or GFDL-compatible notes as cited.  
Code and PKGBUILDs: GPL-compatible, matching Arch Linux packaging norms and upstream package licenses.

Arch Linux name and logo are trademarks of the Arch Linux project; this is an independent porting effort, not an official Arch Linux product.
