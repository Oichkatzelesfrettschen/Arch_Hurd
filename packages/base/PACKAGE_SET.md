# Base package set (M0) -- hurd_x86_64

ALPM architecture: **`hurd_x86_64`**  
GNU tuple: compiler `-dumpmachine` / multiarch `x86_64-gnu`  
Repos: `[base]` then `[core]`

## Build status (2026-07-28)

| Package | Status |
|---|---|
| gnumach | **BUILT** pure Savannah ELF64 (host stage0) |
| mig | **BUILT** stage0-matched |
| gnumach-headers | **INSTALLED** stage0 |
| hurd | Savannah cloned; needs glibc |
| glibc | Savannah pin; **guest-native strategy a** |
| rumpdisk | in-tree hurd.git |
| rumpkernel-compat | Debian **reference** lineage; not product default tarball |
| rumpkernel-netbsd11 | **future donor**; not R0.1 blocker |
| pacman | 7.x policy; PKGBUILD scaffold |
| filesystem | arch any + translator policy |

## M0 zeros still open

glibc userspace × hurd servers × rump root exercise × pacman-on-Hurd × boot image
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
