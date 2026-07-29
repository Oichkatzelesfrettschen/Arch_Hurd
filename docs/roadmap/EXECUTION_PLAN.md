# Execution plan -- build Arch GNU/Hurd M0

**Updated:** 2026-07-26  
**Source base:** pure GNU Savannah  
**glibc strategy:** guest-native (option **a**)

## Objective

Functional base on `x86_64-pc-gnu`: gnumach + Hurd + glibc + core tools + **pacman**, QEMU `-M q35`, evidence `m0-*`.

## Phase map

| Phase | Name | Exit gate | Status |
|---|---|---|---|
| P0 | Plan + Savannah pins | ORACLE_PINS + SOURCE_POLICY | **done** |
| P1 | Fetch pure GNU git | `build/cache/gnu/{gnumach,mig,hurd}` | **done** |
| P2 | Headers + mig | stage0 include + `bin/mig` | **done** |
| P3 | gnumach kernel | `build/stage0/boot/gnumach` ELF64 | **done** |
| P4 | Root layout | mkhurdroot Arch FHS + pacman.conf | **done** (scaffold) |
| P5 | Local repo seed | file:// mirrorlist skeleton | **done** (empty) |
| P5b | Multi-lane tooling | scan-tools, link-assets, guest-shell | **done** |
| P6 | Guest lab smoke | login + guest-tooling capture | **next** |
| P7a | Guest-native glibc+hurd | pure sources build logs on guest | **next** |
| P7b | Product image + pacman | m0 evidence | open |
| P7 | Full M0 | all M0 checkboxes | open |

## Locked decisions

1. Triple: `x86_64-pc-gnu`
2. QEMU: `q35`
3. Disk: Rump-first from pure `hurd.git`
4. Sources: Savannah only for product
5. Debian/Guix: inspiration + **guest lab** only
6. glibc: **guest-native (a)** until falsified
7. Packaging identity: pacman / PKGBUILD

## Makefile surface

```bash
make plan status check preflight scan-tools link-assets
make guest-shell          # hint
make guest-shell-run      # needs ARCH_HURD_QEMU_ACK=yes
make fetch stage0 mig gnumach root repo maps
```

## Non-goals (current)

- Desktop
- Full cross toolchain until guest path fails
- Replacing gnu-hurd-docker (wrap only)
