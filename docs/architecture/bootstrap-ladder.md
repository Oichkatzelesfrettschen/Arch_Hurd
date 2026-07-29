# Bootstrap ladder (architecture)

## Goal

Deliver a **functional Arch GNU/Hurd base**: gnumach + Hurd servers + glibc + core userland + **pacman**, on **x86_64-pc-gnu**, bootable under QEMU machine type **q35**.

## Stages

### Stage -1: Host prerequisites (Linux)

- binutils, gcc capable of building cross targets (or install distro cross packages when available)
- mig (Mach Interface Generator) for Hurd RPC stubs
- qemu-system-x86_64
- pacman (host) for packaging tests where possible
- ext4/xattr tools, mtools/grub as needed for images

Validation: `scripts/host-preflight.sh`

### Stage 0: Oracle pins

Record exact upstream/Debian/Guix versions that are known to boot:

- gnumach
- hurd
- glibc
- rumpkernel
- mig
- bash, coreutils baselines

File: `frontier/ORACLE_PINS.tsv`

### Stage 1: Cross headers and tools

Build order (logical):

1. gnumach-headers / mig
2. hurd-headers
3. binutils (x86_64-pc-gnu)
4. gcc stage1 (c only)
5. glibc
6. gcc stage2 (c,c++)
7. hurd libraries and essential servers

This follows the classic Hurd cross + Debian rebootstrap shape; exact flags live in package recipes under `packages/base/`.

### Stage 2: Host-assembled root (xattr)

`scripts/mkhurdroot.sh` (scaffold):

1. Create disk image; mkfs.ext2 (or ext4) with user_xattr
2. Pacstrap-equivalent unpack of stage tarball / packages into mount
3. Write translator xattrs and static device nodes policy
4. Install multiboot kernel (gnumach) + modules (ext2fs, exec, ...)
5. Seed pacman conf + local repo

Gate: image mounts on Linux and shows expected xattrs (`getfattr`).

### Stage 3: First boot (QEMU q35)

```
qemu-system-x86_64 -M q35 -m 2048 -enable-kvm \
  -drive file=archhurd.img,format=raw \
  -device e1000,netdev=n0 -netdev user,id=n0,hostfwd=tcp::10022-:22 \
  -serial stdio
```

Prefer rumpdisk; pass `noide` when built-in IDE conflicts (Guix lesson).

Gate G0: root shell + `uname` reports GNU + `pacman -V`.

### Stage 4: Native rebuild

Inside the Hurd system (or Debian Hurd chroot as interim):

- install base-devel analogue
- rebuild packages with makepkg
- sign and publish to repo

### Stage 5: Rolling track

- track Arch Linux package versions for portable packages
- carry Hurd-specific patches in `packages/*/patches`
- CI: cross build + QEMU smoke (when infrastructure exists)

## Init and translators

Hurd boot is not systemd. Historical Arch Hurd experimented with OpenRC; Debian uses its own runsystem path. This repo:

- Phase M0: vendor the minimal Hurd boot scripts required to reach a shell
- Phase M1: decide OpenRC vs thin runsystem wrapper with evidence
- Never pretend systemd works

## Failure modes (ranked)

1. Disk translator fails => unbootable root (C_drv = 0)
2. glibc/MIG mismatch => total userspace collapse (C_abi = 0)
3. pacman sandbox/Linuxisms => package manager unusable (C_pkg low)
4. Missing network => cannot grow without local media (ops only)
5. SMP bugs => flaky parallel builds (M2 only)

## Non-claims

This document does not assert that Stage 2-3 already run green in this repository. Scaffolds exist; execution is gated on toolchain acquisition and operator-approved image builds.
