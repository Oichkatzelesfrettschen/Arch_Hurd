# Open steps (scoped backlog)

**As of:** 2026-07-28  
**Product:** `hurd_x86_64` + pure GNU Savannah ABI + ALPM identity  
**Not open for R0.1:** rump DRM/KMS, Wayland, SMP default, desktop

## Done foundation

| ID | Item |
|---|---|
| F0 | Identity `hurd_x86_64`, SOURCE_POLICY, legacy/, pins, stage graph docs |
| F1 | Savannah fetch for gnumach/mig/hurd/glibc |
| F2 | stage0 mig + gnumach ELF64 pure build |
| F3 | Offline gates (pure-gnu, identity, legacy, maps, tests) |
| F4 | Multi-lane guest tooling links (gnu-hurd-docker) |

## M0 critical path (ordered zeros)

```text
C_abi:  gnumach [yes] * glibc [NO] * hurd servers [NO]
C_drv:  rumpdisk root path [NO]
C_pkg:  pacman on Hurd [NO]
C_init: bootable image + reboot [NO]
R = product of zeros => still 0
```

| Step | Stage | Work | Domain | Exit gate |
|---|---|---|---|---|
| **S1** | 4 | **DONE** hurd-headers  into stage0/sysroot | host | `build/stage0/include/hurd` present |
| **S2** | 2 | Cross **binutils** for `x86_64-gnu` (optional parallel) | host | `x86_64-gnu-ld` in build/cross or documented miss |
| **S3** | 10 prep | Guest playbook: build pure glibc+hurd on Hurd VM | guest | logs under evidence/captures/guest-* |
| **S4** | 10 | Install hurd servers into product root | guest/cross | `/hurd/ext2fs` etc. |
| **S5** | 10 | Wire **rumpdisk** for root | guest | boot with rump, document `noide` |
| **S6** | 11 | Port/build **pacman 7.x** + deps | guest | `pacman -V` |
| **S7** | 12 | Assemble disk image (ext2 + translators/xattrs) | host | image artifact |
| **S8** | 13 | QEMU smoke + **`evidence/captures/m0-*`** | host+guest | M0 claim may flip |

## Deferred (explicit)

| Item | Until |
|---|---|
| rumpkernel-netbsd11 | after rump-compat works |
| rump DRM/KMS | after M0 non-DRM path |
| X.Org milestone | after M0 shell+pacman |
| archhurd-keyring production | after local repo packages exist |
| CI publish | after check/test stable on main |

## Parallel cheap host work (does not unblock glibc alone)

- Expand `port.toml` for mig/hurd/glibc
- `sources.lock` generators
- Image assembler that embeds pure `gnumach`
- Convert more PKGBUILDs as they are imported

## Next action now

Implement **S1** (hurd-headers) + bootstrap image/tarball tooling + guest playbook files, then attempt S3 when `ARCH_HURD_QEMU_ACK=yes`.
