# Base package set (M0 sketch)

Architecture: `x86_64` (triple `x86_64-pc-gnu`)  
Repos: `[base]` then `[core]`

## Build status (host, 2026-07-28) -- pure GNU base

| Package | Status |
|---|---|
| gnumach | **BUILT** ELF64 from Savannah (no Debian patches) |
| mig | **BUILT** stage0-matched Savannah mig |
| gnumach-headers | **INSTALLED** `build/stage0/include/mach` |
| hurd | Savannah cloned; build blocked on glibc |
| glibc | Savannah `hurd/glibc.git` pin path; **guest-native strategy a** |
| rumpdisk/rumpnet | **in-tree** under pure `hurd.git` |
| pacman | PKGBUILD scaffold only |

Base policy: `docs/architecture/SOURCE_POLICY.md`  
glibc: `docs/architecture/GLIBC_STRATEGY.md` (guest-native)

## M0 zeros still open

C_abi partial (kernel yes, glibc no) × C_drv (rump unexercised) × C_pkg (pacman) × C_init (no boot image) = product readiness still 0 until those gates close.

## Tier 0 -- headers and generators

| Package | Role |
|---|---|
| mig | Mach Interface Generator |
| gnumach-headers | kernel headers for userland |
| hurd-headers | Hurd RPC headers |

## Tier 1 -- kernel and servers

| Package | Role |
|---|---|
| gnumach | microkernel |
| hurd | essential servers (auth, proc, exec, ext2fs, ...) |
| rumpkernel | NetBSD rump bits |
| rumpdisk | userland disk |
| rumpnet | userland net (M0 optional if alternate NIC path) |

## Tier 2 -- C library and compiler runtime

| Package | Role |
|---|---|
| glibc | GNU C library for Hurd |
| gcc-libs | runtime |
| libxcrypt | crypt |

## Tier 3 -- shell and POSIX userland

| Package | Role |
|---|---|
| filesystem | Arch hierarchy + translator recipes |
| iana-etc | protocols/services |
| tzdata | timezones |
| bash | shell |
| readline | ncurses | coreutils | findutils | grep | sed | gawk | tar | gzip | xz | bzip2 | file | which | less | diffutils | patch |

## Tier 4 -- pacman stack

| Package | Role |
|---|---|
| zlib | zstd | libarchive | openssl | curl | expat | gpgme | libassuan | libgpg-error | gnupg | pacman | archhurd-keyring |

## Tier 5 -- system glue

| Package | Role |
|---|---|
| shadow | accounts (verify Hurd support) |
| base-hurd | meta package pulling M0 |
| runsystem-hurd or openrc | init decision gated |
| netcfg-hurd | pfinet helper scripts |

## Explicit non-goals for M0

- linux, linux-firmware, systemd, mkinitcpio (Linux-specific)
- full util-linux feature parity
- desktop stacks
