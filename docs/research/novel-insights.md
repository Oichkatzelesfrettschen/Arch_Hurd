# Novel insights, connections, and breakthroughs

Present-tense research synthesis for Arch GNU/Hurd rebootstrap (2026-07-25).  
These are **structured claims**, not slogans. Each insight carries a coefficient decomposition and a falsifier.

## Insight I1 -- Pure GNU base + Arch identity (corrected)

**Statement:** A modern Arch Hurd succeeds by splitting *identity* (pacman, PKGBUILD, rolling policy) from *kernel/userspace base* which is **pure GNU Hurd on Savannah**, not Debian packages.

**Why the first draft was wrong:** Treating Debian pool tarballs + `debian/patches` as the default "oracle" silently makes Arch a Debian rebuild with pacman paint. That is inspiration-as-base, not Arch-on-Hurd.

**Correct connection:**
- **Base:** Savannah `gnumach.git`, `mig.git`, `hurd.git` (and glibc Hurd maintenance).
- **Inspiration:** Debian packaging scripts, Guix QEMU recipes, Alpine minimalism -- read, do not ship as defaults.
- **Rump:** already in pure `hurd.git` (`rumpdisk`, `rumpnet`).

**Coefficients (relative weight, sum = 1.0 for bootstrap success):**

| Coefficient | Symbol | Weight | Notes |
|---|---|---|---|
| Pure GNU SHA stability | C_abi | 0.28 | pinned Savannah commits that build |
| Packaging graph closure | C_pkg | 0.22 | pacman + base deps |
| Driver path (Rump in-tree) | C_drv | 0.18 | disk + NIC under QEMU |
| Cross-build discipline | C_x | 0.15 | no circular host deps |
| Init/translator policy | C_init | 0.10 | boot to shell |
| Community ops | C_ops | 0.07 | mirrors, signing, docs |

**Falsifier:** M0 only achievable by consuming Debian binary packages as rootfs base.

**Action:** `docs/architecture/SOURCE_POLICY.md`; `make fetch` clones Savannah only.

## Insight I2 -- xattr is the bootstrap hinge

**Statement:** Debian's switch to xattr-stored translators is the Arch-relevant bootstrap hinge: a Linux host can assemble a Hurd rootfs without running Hurd servers during package unpack.

**Derivation:** Translators used to be filesystem-special; foreign OS bootstrap was painful. xattr encoding lets mmdebstrap-class tools create Hurd images from Linux. Arch can implement an equivalent `mkhurdroot` that:

1. formats ext2/ext4 with user_xattr
2. unpacks pacman packages or bootstrap tarball
3. writes translator xattrs for /servers, /dev, ...
4. installs gnumach + GRUB/multiboot config
5. boots under QEMU q35 for first native `pacman -Syu`

**Coefficient:** multiplies C_x by unlocking host-side staging.

**Falsifier:** If xattr translator records are incomplete for Arch FHS paths required by pacman, host-side staging fails and must fall back to Debian Hurd chroot seeding.

## Insight I3 -- Rump-first package set (not "kernel package")

**Statement:** Arch base on Hurd is a **multi-server product**. Packaging must treat `gnumach`, `hurd`, `rumpkernel`/`rumpdisk`/`rumpnet` as peers.

**Connection:** Historical Arch Hurd optimized for i686 with DDE. FOSDEM 2026 and Debian 2025 put Rump in production. Guix 64-bit defaults to rumpdisk and often `noide`.

**Package topology (M0):**

```
base-hurd meta
  |- gnumach
  |- hurd
  |- hurd-libs / mig (build)
  |- rumpdisk (+ rumpkernel bits)
  |- rumpnet (optional at M0 if e1000 via other path)
  |- glibc
  |- filesystem (Arch dirs + translator recipes)
  |- pacman-stack
```

**Falsifier:** A single "linux-style" kernel package that hides Rump and still boots durable root on amd64 under QEMU with USB/SATA.

## Insight I4 -- Target triple is a product decision

**Statement:** Primary triple is `x86_64-pc-gnu`. Shipping i686 as default re-imports every historical dead end.

**Coefficients:** hardware relevance (high), upstream compiler support (GCC 14+ Hurd 64-bit), archive density (Debian amd64 parity).

**Retention:** keep i686 only as `arch=i686` experimental if oracle still builds it.

## Insight I5 -- Cross-then-native ladder (Debian rebootstrap + Guix childhurd)

**Statement:** The winning process is the product of two proven methods:

1. Debian: crossbuild + Helmut Grohne-style rebootstrap + build profiles for hurd-amd64
2. Guix: childhurd (32 then 64) for native rebuild and package fixing

**Arch instantiation:**

```
Linux host
  -> cross x86_64-pc-gnu toolchain (gcc, binutils, mig, gnumach headers)
  -> stage0 root (static-ish tools + glibc)
  -> stage1 pacman-capable root (host-assembled, xattrs)
  -> QEMU q35 boot
  -> stage2 native rebuild of PKGBUILDs (devtools-hurd)
  -> publish file:// or http repo
```

**Falsifier:** Native-only rebuild inside Debian Hurd chroot produces a cleaner Arch identity faster *and* does not depend on Debian forever. (Even then, oracle patches remain.)

## Insight I6 -- pacman is the differentiator, not "another Hurd port"

**Statement:** Debian, Guix, and Alpine already occupy Hurd. Arch's unique deliverable is **rolling pacman UX + KISS packaging** on the same microkernel substrate.

**Non-goal:** matching Debian package count in year one.  
**Goal:** closed base + growable core with Arch contribution patterns (PKGBUILD review, AUR-like user packages later).

## Insight I7 -- SMP and Rust are second-wave enablers, not M0 blockers

**Statement:** SMP and Rust unlock parallel package builds and modern dependency graphs, but M0 gates on single-CPU QEMU with C/C++ toolchain.

**Ordering:**

1. M0 single-CPU pacman base
2. M1 native toolchain + makepkg
3. M2 SMP gnumach package variant
4. M3 rustc for Hurd (consume Debian/upstream port)
5. M4 desktop experiments (Xfce etc.) only after M1 green

## Insight I8 -- Coefficient product, not sum

**Statement:** Bootstrap readiness is closer to a **product of gates** than a weighted sum. A 0 on C_drv (no disk) zeroes the system even if C_pkg is perfect.

```
Readiness ~= C_abi * C_drv * C_x * C_pkg * C_init
```

Ops coefficient C_ops scales adoption after Readiness > 0.

**Engineering consequence:** fix zeros first. Do not polish PKGBUILD style while Rump root is red.

## Insight I9 -- Historical PKGBUILDs are pattern mines, not drop-in sources

**Statement:** z3ntu/archhurd_packages encodes:

- which packages Arch Hurd considered "core"
- Hurd-specific depends/conflicts patterns
- install scriptlets for translators

Versions, checksums, and patches are stale. Mine structure; re-pin versions from Arch Linux core + Hurd patches from Debian.

## Insight I10 -- Instrument before mythology

**Statement:** Every load-bearing script and package recipe gets lexical maps (cflow/cscope/ctags) and a claim row. Maps do not prove runtime; they prevent narrative drift.

**This repo practice:**

- `make maps` regenerates analysis/maps/*
- frontier TSV owns claim state
- agents return fixed-schema handbacks only

## Breakthrough opportunities (implementation-ready hypotheses)

| ID | Hypothesis | Ready? | First validation |
|---|---|---|---|
| B1 | Host-side `mkhurdroot` using xattrs + pacman -r | hypothesized | build empty root, boot gnumach |
| B2 | Import Debian hurd/gnumach/glibc versions into PKGBUILD | hypothesized | build under cross or Debian Hurd |
| B3 | pacman 7.x on Hurd with disabled Linux-only sandbox features | hypothesized | compile+install test |
| B4 | file:// repo + pacman.conf for offline base | hypothesized | pacman -Syu offline |
| B5 | QEMU q35 + e1000 + rumpdisk automated smoke | hypothesized | scripts/qemu-smoke.sh |
| B6 | devtools-hurd (makechrootpkg analogue) | speculative | after M1 |

## What this repository claims today (known)

1. The workspace was empty; this tree is a deliberate rebootstrap, not a fork of a live monorepo.
2. Public evidence shows historical Arch Hurd is i686/stale; modern Hurd is amd64-capable via Debian/Guix.
3. A viable Arch path is oracle-backed, Rump-first, x86_64, xattr-bootstrap, pacman-identity.

## What this repository does not claim

- A bootable ISO ships in this commit.
- Bare-metal support for arbitrary laptops.
- Feature parity with Arch Linux on Linux.
- That FOSDEM "almost there" means production-ready desktop for all users.
