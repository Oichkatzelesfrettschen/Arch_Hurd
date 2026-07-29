# 2026 GNU/Hurd and Arch Hurd landscape

Capture date (UTC): 2026-07-25  
Authority style: primary announcements first; secondary reporting as corroboration.

## 1. Prior Arch Hurd (what we inherit)

### 1.1 Identity (stable)

Arch Hurd is Arch Linux userland semantics on GNU Hurd:

- pacman package manager
- PKGBUILD-driven rolling packages
- BSD-style init historically; OpenRC appeared in staging lists
- KISS / DIY culture
- Originally **i686-optimised** packages

Sources: archhurd.org front page; Wikipedia Arch Hurd.

### 1.2 Timeline (condensed)

| When | Event | Evidence class |
|---|---|---|
| 2010-01 | Project founded on Arch Linux forums | primary forum / wiki |
| 2010 | Boot in VM; real hardware reports; LiveCD work | GNU "month of the Hurd" news |
| 2011-06 | DDE integration improves networking | Arch Hurd news (archived) |
| 2013 | "seems dead" posts; glibc rebuild bottleneck | archhurd.org news |
| 2015-2016 | Volunteer rebuilds inside old ISO / Debian Hurd chroot | archhurd.org news |
| 2018-06 | z3ntu: website rebuild, packages on GitHub, chroot builds | archhurd.org "We're back!" |
| ~2019-05 | Last meaningful package push on z3ntu/archhurd_packages | GitHub pushed_at |
| 2021-05 | IRC network note (Libera) on site | archhurd.org news edit |
| 2022-06 | Wikipedia "latest release" citation | secondary |
| 2025-08 | LWN: Arch Hurd "can really use volunteers to (re-)bootstrap" | secondary, community signal |

### 1.3 Frozen technical surface (historical packages)

archhurd.org staging list (observed 2026-07-25) still advertises:

- hurd 0.9.r179 / gnumach 1.8.r82
- glibc 2.29.r34436
- pacman 5.1.0
- openrc 0.38.2
- architecture: **i686 only**

GitHub inventory (z3ntu):

- archhurd_packages (last push 2019-05)
- archhurd_packages_binary (2019-05)
- archhurd_pacman, archhurd_glibc, archhurd-genimg, archhurd_devtools
- archhurd_archweb fork still receives cosmetic pushes (2026)

**Claim:** historical Arch Hurd is not a viable product baseline for 2026 amd64 hardware.  
**Falsifier:** a maintained x86_64 Arch Hurd mirror with packages newer than 2024 and documented bootstrap.  
**Status:** known (no such mirror found in bounded search).

## 2. Debian GNU/Hurd 2025 (primary oracle)

Announcement: 2025-08-10, debian.org/ports/hurd/hurd-news.

Load-bearing bullets:

1. Snapshot of Debian sid at Trixie time; official **port** release, not an official Debian release.
2. Architectures: **i386 and amd64**, ~72% of Debian archive.
3. **64-bit complete**; coverage matches or exceeds i386 for some 64-only packages.
4. Disk I/O on 64-bit uses **NetBSD Rump** userland drivers exclusively for the modern path.
5. **xattr default for translators** -- bootstrap from other OSes (e.g. mmdebstrap) becomes seamless.
6. **Rust** ported to GNU/Hurd.
7. USB disk and CD-ROM via Rump.
8. **SMP packages** available ("quite working").
9. Console: xkb layouts; multiboot framebuffer.
10. Platform bits: acpi, rtc, apic, hpet; fixes in irqs, nfsv3, libports, pipes.

Install surfaces: NETINST ISO (hurd-i386, hurd-amd64), preinstalled disk image, QEMU documented path.

**Implication for Arch:** Debian is the densest binary and packaging-port oracle. Re-use its Hurd patches and configure knowledge; do not copy dpkg into the product identity.

## 3. FOSDEM 2026 (Samuel Thibault)

Event: 2026-02-01, Microkernel track.  
Title: Updates on GNU/Hurd progress: rump drivers, 64bit, SMP, software bootstrapping.

Abstract (authoritative):

- Rump layer in production; remaining fixes.
- SMP enough for parallel compilation.
- Rust support became necessary for modern software graphs.
- x86_64 essentially complete (MIG RPC layer + software awareness).
- Debian hurd-amd64 bootstrapped via crossbuild / rebootstrap / build profiles.
- Guix/Hurd and Alpine/Hurd also in motion.
- Closing slide corpus: "GNU/Hurd is almost there with Debian/Guix/Arch/Alpine".

Secondary corroboration: Phoronix 2026-02-01; It's FOSS 2026-02-03 (reports ~75-80% package build rates, userland net/ACPI/PCI, PAE, experimental AArch64).

## 4. Guix 64-bit Hurd (2026-03-01)

Blog: "The 64-bit Hurd is Here!" (Janneke Nieuwenhuizen, Yelninei).

Load-bearing facts:

- Native `x86_64-gnu` support merged after large GCC 14-driven world rebuild.
- Cross-built gnumach; childhurd types including 64-bit.
- QEMU requires **machine type q35** for modern images.
- 64-bit path leans on **rumpdisk**; often needs `noide` kernel argument so gnumach does not own IDE.
- RumpNET support for Intel i8254x (`wm`) documented with settrans recipe.
- Guix package coverage for Hurd remains low (~1% order) vs Debian ~75%; Guix is a **bootstrap and system-definition** oracle more than a binary archive oracle.
- Ongoing: SMP fixes for 64-bit gnumach (Damien Zammit patches, early 2026); journaling ext2; AArch64; RISC-V interest; audio (NLnet).

## 5. Alpine Hurd

Announced on bug-hurd (2024-01) as a musl/busybox-lean Hurd distro effort. Named again at FOSDEM 2026. Useful as a **minimal userspace coefficient** reference (how small can a Hurd base be?), not as the Arch packaging model.

## 6. Cross-distro comparison (2026)

| Distro | Kernel/userspace | Package model | Archive depth | Best use as input |
|---|---|---|---|---|
| Debian GNU/Hurd | gnumach + Hurd + Rump | dpkg/apt | ~72-75% | ABI, patches, binary seed |
| Guix/Hurd | same + Shepherd | functional store | low % | reproducible system graphs, childhurd |
| Alpine/Hurd | lean userspace | apk | sparse | minimal base experiments |
| Historical Arch Hurd | pre-Rump i686 | pacman | frozen | packaging layout patterns only |
| **This repo** | modern Hurd | pacman rolling | goal: base then core | Arch identity on modern substrate |

## 7. Hardware / driver topology (2026 reality)

```
+---------------------------+
| Applications (pacman pkgs)|
+---------------------------+
| glibc / ld.so / libpthread|
+---------------------------+
| Hurd servers (ext2fs,     |
| proc, auth, pfinet/pflocal|
| exec, init, ...)          |
+-------------+-------------+
| Rump disk/net | PCI/ACPI  |   userland
| translators   | arbiter   |
+-------------+-------------+
| GNU Mach (CPU, RAM, IRQ,  |
| clock, optional legacy IDE|
+---------------------------+
| QEMU q35 / limited bare   |
| metal                     |
+---------------------------+
```

**Insight:** Arch base packages must package translators and Rump as seriously as they package glibc. Treating "kernel" as a single linux-like package is a category error.

## 8. What "functional base system with pacman" means here

Minimum closed set (M0):

1. gnumach (bootable under QEMU q35)
2. hurd servers required for single-user multi-process
3. glibc for x86_64-gnu
4. bash, coreutils, util-linux-or-hurd-equivalents, grep, sed, gawk, tar, gzip/xz
5. pacman + libalpm dependencies (curl, openssl, gpgme, libarchive, ...)
6. filesystem layout: Arch FHS with Hurd translator hooks
7. network path: pfinet + at least one NIC driver path (rumpnet or emulated e1000)
8. package repo metadata: local file:// repo sufficient for M0

Gate G0 (definition of done for "base boots"):

- QEMU boots to a login or root shell
- `pacman -Sy` against a local repo succeeds
- `pacman -S` installs a trivial package and leaves a consistent system
- reboot preserves translator/xattr state on the root filesystem

## 9. Research gaps (explicit)

| Gap | Why it matters | Next probe |
|---|---|---|
| Exact Alpine Hurd package list depth | minimal-base coefficient | bounded clone/read of Alpine Hurd tree |
| Current gnumach/hurd git SHAs in Debian 2025 images | pin versions | inspect ISO/Packages or salsa |
| pacman 7.x build on Hurd (fcntl, sandbox, download) | M0 blocker | try build in Debian Hurd chroot |
| OpenRC vs runsystem/sysv on modern Hurd | init story | compare Debian runsystem + Arch openrc history |
| Bare-metal support matrix beyond ThinkPad-class reports | hardware claims | defer; VM-first |

## 10. Citations (retrieval anchors)

- https://archhurd.org/
- https://en.wikipedia.org/wiki/Arch_Hurd
- https://www.debian.org/ports/hurd/hurd-news
- https://www.phoronix.com/news/Debian-GNU-Hurd-2025
- https://fosdem.org/2026/schedule/event/7FZXHF-updates_on_gnuhurd_progress_rump_drivers_64bit_smp_software_bootstrapping/
- https://www.phoronix.com/news/GNU-Hurd-In-2026
- https://guix.gnu.org/en/blog/2026/the-64-bit-hurd/
- https://lwn.net/Articles/1033414/
- https://itsfoss.com/news/gnu-hurd-progress-report/
- https://github.com/z3ntu/archhurd_packages
