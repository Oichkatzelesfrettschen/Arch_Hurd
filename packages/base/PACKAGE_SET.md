# Base package set (M0) -- hurd_x86_64

ALPM architecture: **`hurd_x86_64`**  
GNU tuple: compiler `-dumpmachine` / multiarch `x86_64-gnu`  
Repos: `[base]` then `[core]`

### Runtime progress (2026-07-29)

- **S2 cross-binutils**: DONE -- `build/cross/bin/x86_64-gnu-{as,ld,...}` 2.43.1; `build/cross/CROSS_BINUTILS.ok`
- **S3 guest-native**: IN PROGRESS -- pure trees uploaded; glibc configure OK, make fails on mach x86_64 sysdep macros; hurd configure OK (`--without-parted`, rumpdisk Makefile)
- Evidence: `evidence/captures/guest-native-*.txt`, import under `build/guest-import/` and `packages/base/*/GUEST_IMPORT.txt`
- Helpers: `scripts/guest-s3-run.sh`, `scripts/guest-inject-ssh.sh`, `scripts/import-guest-artifacts.sh`

## Build status (2026-07-29)

| Package | Status |
|---|---|
| gnumach | **BUILT** pure Savannah ELF64 (host stage0) |
| mig | **BUILT** stage0-matched |
| gnumach-headers | **INSTALLED** stage0 |
| hurd | Savannah configured on guest (`--without-parted`); needs full make after glibc |
| glibc | Savannah guest configure OK; **make blocked** on mach x86_64 sysdep macros |
| rumpdisk | in-tree hurd.git; Makefile generated on guest configure |
| rumpkernel-compat | Debian **reference** lineage; not product default tarball |
| rumpkernel-netbsd11 | **future donor**; not R0.1 blocker |
| pacman | 7.x policy; PKGBUILD scaffold |
| filesystem | arch any + translator policy |

## M0 zeros still open

glibc userspace x hurd servers x rump root exercise x pacman-on-Hurd x boot image
=> product readiness remains 0 until those gates close (honest).

## Non-goals for first usable release

- rump DRM/KMS / modern Wayland stack
- SMP as default kernel flavor
- shipping Arch Linux `x86_64` packages on the target

## Policy refs

- `docs/architecture/IDENTITY.md`
- `docs/architecture/SOURCE_POLICY.md`
- `docs/architecture/STAGE_GRAPH.md`
- `docs/architecture/GLIBC_STRATEGY.md`
