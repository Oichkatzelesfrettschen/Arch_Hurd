# Ultra-detailed roadmap -- Arch GNU/Hurd rebootstrap

**Rescope date:** 2026-07-26  
**Horizon:** M0 (base boots with pacman) -> M4 (optional desktop)  
**Source base:** pure GNU Savannah (`SOURCE_POLICY.md`)  
**glibc strategy:** guest-native (option a; `GLIBC_STRATEGY.md`)

## 0. Live repository state

| Observation | Status |
|---|---|
| Pure Savannah fetch + pins (gnumach/mig/hurd) | **done** |
| stage0 headers + matched mig | **done** |
| gnumach ELF64 pure build | **done** (P3) |
| Root layout + empty local repo | **done** (scaffold) |
| Multi-lane host/guest tooling docs + scan/link | **done** |
| Host gnumig package available | **done** (local PKGBUILD) |
| Linked gnu-hurd-docker images | **done** (symlinks) |
| glibc + hurd userspace product build | **open** |
| Boot + pacman M0 evidence | **open** |

### Remaining deficiencies (M0)

1. glibc for `x86_64-pc-gnu` (guest-native path selected)
2. hurd servers install into product root
3. Rump root exercised under QEMU
4. pacman port + local repo packages
5. Disk image assembly with translators/xattrs
6. `evidence/captures/m0-*`
7. Signing keyring + CI (post-M0 acceptable)

### Harmonization

- Triple: `x86_64-pc-gnu`
- Claims: `frontier/CLAIMS_EVIDENCE.tsv`
- Pins: `frontier/ORACLE_PINS.tsv` (`pinned-git` for Savannah)
- Agents: bounded contracts under `agents/contracts/`
- Guest lab: `gnu-hurd-docker` (not product base)

## 1. Milestones

### M0 -- Functional base

- [x] gnumach ELF64 from pure Savannah
- [x] gnumach headers + stage0 mig
- [ ] hurd + glibc for x86_64-pc-gnu (**guest-native**)
- [ ] QEMU `-M q35` boot of product-ish root
- [ ] Rump disk path (or documented equivalent)
- [ ] bash + coreutils-class tools
- [ ] pacman `-V` / local `-Sy` / install
- [ ] Reboot preserves state
- [ ] `evidence/captures/m0-*`

### M1 -- Self-hosting packaging

- [ ] makepkg on Hurd
- [ ] base-devel analogue
- [ ] rebuild hello, zlib, pacman
- [ ] chroot build helper
- [ ] contributor path

### M2 -- SMP / net expansion

- [ ] SMP gnumach variant tested
- [ ] rumpnet path
- [ ] optional USB
- [ ] parallel makepkg stress

### M3 -- Language graph

- [ ] rustc status
- [ ] go status if needed
- [ ] LLVM optional

### M4 -- Usability (optional)

- [ ] X/Wayland status
- [ ] lightweight WM only after M1
- [ ] installer ISO experiments

## 2. Work packages

| WP | Title | Status | Priority |
|---|---|---|---|
| WP-R1 | Research corpus + citations | done | P0 |
| WP-R2 | **Savannah** git pins (not Debian base) | done | P0 |
| WP-R3 | Multi-lane env (paru/gnumig, QEMU images, docker-qemu) | done | P0 |
| WP-T0 | stage0 headers + mig + gnumach pure build | done | P0 |
| WP-G1 | Guest login + toolchain inventory evidence | in progress | P0 |
| WP-T1 | Guest-native glibc (strategy a) | pending | P0 |
| WP-P1 | PKGBUILD: gnumach, mig, hurd, glibc (real install) | partial | P0 |
| WP-P2 | pacman dependency closure | pending | P0 |
| WP-B1 | mkhurdroot + xattr/package unpack | scaffold | P0 |
| WP-B2 | QEMU product smoke + m0 evidence | pending | P0 |
| WP-M1 | Lexical maps continuous | ongoing | P1 |
| WP-C1 | CI skeleton | pending | P1 |
| WP-D1 | Installer ISO | blocked on M1 | P3 |

## 3. Package closure sketch (M0)

1. mig, gnumach-headers, gnumach (**built**)
2. **glibc (Hurd)** -- next
3. hurd (+ in-tree rumpdisk/rumpnet)
4. filesystem + translators
5. bash / coreutils-class
6. pacman stack + pacman
7. archhurd-keyring (later)
8. runsystem vs OpenRC (after shell)

## 4. Near-term execution (locked order)

1. Hygiene: status dashboard, roadmap alignment, `guest-shell` (**this slice**)
2. Guest login proof + `guest-tooling-*` capture (G2--G3)
3. Guest-native pure glibc + hurd build notes/logs (strategy a)
4. Stage product root with servers + rump
5. pacman + image + M0 smoke

## 5. Sanity checks

```bash
make check maps status preflight scan-tools link-assets guest-shell
```

## 6. Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Savannah tip drift | medium | pin SHAs in ORACLE_PINS; re-verify builds |
| Guest image bitrot | medium | prefer dated qcow2; snapshot before kernel swap |
| pacman Linuxisms | high | A-pacman-port; feature probes on guest |
| Scope creep to desktop | high | M4 blocked until M1 |
| Confusing guest Debian with product | high | SOURCE_POLICY + README disclaimers |

## 7. Success metric (12 weeks, aspirational)

- M0 evidence bundle public in repo
- Reproducible path: Linux host pure gnumach + guest-assisted userspace -> QEMU login + pacman
- >= 30 packages in core building (aspirational, not a claim)
