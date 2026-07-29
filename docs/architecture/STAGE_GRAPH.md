# Bootstrap stage graph (0-14 compressed)

**Product:** `hurd_x86_64` ALPM packages + pure GNU ABI.  
**Host:** Arch Linux x86_64 control plane.  
**Reference:** Debian GNU/Hurd porting corpus (not product base).

## Domain separation

```text
Host domain          Cross-target domain         Native domain
(Arch Linux tools)   (Hurd objects on Linux)     (inside Hurd VM)
----------------     -----------------------     ----------------
fetch, QEMU,         headers, glibc stages,      final core rebuild,
devtools, signing    gnumach, early hurd,        base-devel, X later
                     seed pacman if possible
```

Never install target Hurd files into host `/usr`. Cross sysroots live under
project `build/sysroots/x86_64-gnu/` (or `/srv/archhurd/...` on dedicated hosts).

## Stages (DAG)

| Stage | Name | Domain | Outputs | Depends |
|---|---|---|---|---|
| 0 | Host tools + identity policy | host | pacman/devtools, IDENTITY | -- |
| 1 | Source locks / pins | host | ORACLE_PINS, sources.lock | 0 |
| 2 | Cross binutils | host | x86_64-gnu-as/ld | 1 |
| 3 | MIG (cross + host usable) | host | mig for x86_64-gnu | 1 |
| 4 | gnumach-headers + hurd-headers | cross | installed headers sysroot | 2,3 |
| 5 | glibc headers / startfiles | cross | libc stubs | 4 |
| 6 | GCC stage1 (C only) | host/cross | cross-gcc | 5 |
| 7 | glibc full | cross/native | libc.so | 6 |
| 8 | GCC stage2 | host/cross | full cross-gcc | 7 |
| 9 | gnumach kernel (UP) | host | boot/gnumach | 3,4 |
| 10 | Hurd servers + rumpdisk-compat | cross/native | /hurd/* | 7,9 |
| 11 | Minimal userland + pacman | native preferred | base shell + pacman | 10 |
| 12 | Image (ext2 + translators) | host | QEMU disk | 9-11 |
| 13 | QEMU smoke M0 | host+guest | evidence/captures/m0-* | 12 |
| 14 | Native base-devel self-host | native | rebuild cycle | 13 |

## Current progress (repo)

| Stage | Status |
|---|---|
| 0-1 | **done** (policy, pins, gates, identity, legacy) |
| 3 | mig stage0 **done** |
| 4 | gnumach headers **done**; hurd-headers via `make hurd-headers` |
| 9 | pure gnumach ELF64 **done** |
| 12 partial | bootstrap tarball via `make image` (full disk needs root/mkfs) |
| 2, 5-8, 10-11, 13-14 | **open** (see `docs/roadmap/OPEN_STEPS.md`) |

## Package directory pattern (future)

```text
packages/<name>/
  PKGBUILD
  port.toml          # bootstrap profiles (headers|startfiles|full)
  sources.lock
  patches/series
  tests/
```

`port.toml` carries build/host/target roles; PKGBUILD remains the package surface.

## PKGBUILD arch conversion

```bash
scripts/convert-pkgbuild-arch.sh packages/foo/PKGBUILD
# x86_64 -> hurd_x86_64 + xdata osabi/gnu_tuple
```

Host bootstrap packages under `packages/host/` stay `x86_64` if/when added.

## Non-DRM graphics deferral

Stages 0-13 never require rump DRM/KMS. Optional graphics track branches after M0
from Hurd console / non-DRM X references, then NetBSD-11 rump experiments.
