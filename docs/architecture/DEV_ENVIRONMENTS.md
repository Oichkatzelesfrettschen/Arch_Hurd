# Development environments (multi-lane)

**Why this doc exists:** Building pure GNU from source on Linux is one lane.  
Ready host packages, QEMU images, and Docker/QEMU wrappers are other lanes.  
Use the cheapest lane that answers the question.

## Inventory (this host, 2026-07-26)

### Lane A -- Native Linux piecemeal (host packages)

| Tool | Status on host | Notes |
|---|---|---|
| **gnumig** 1.8-1 | **Installed** (`pacman -Q gnumig`) | Local package from `~/Github/OS-Projects/mig-gnu`; provides `/usr/bin/mig` + `migcom`; vendored Mach headers at build time |
| mig (AUR name) | No AUR hit for GNU MIG | Search noise is DB migration tools; real package name is **gnumig** |
| gnumach / hurd | Not in official repos or AUR (RPC count 0) | Must build from Savannah or use guest tools |
| qemu-system-x86_64 | 11.0.2 present | Required for all VM lanes |
| guix | Not installed / not in quick pacman hit | Guix childhurd is optional if user installs Guix |
| docker / podman | Present | See Lane C |

**paru search guidance:**

```bash
# Wrong: "mig" matches database migration junk
paru -Ss mig

# Right:
paru -Ss gnumig
pacman -Qi gnumig
# PKGBUILD source of truth for host package:
#   ~/Github/OS-Projects/mig-gnu/PKGBUILD
```

AUR has **no** `gnumach` / `hurd` packages as of this survey. Host-side product work is: package pure Savannah builds under Arch_Hurd PKGBUILDs; keep **gnumig** (or stage0 mig) for RPC stubs.

**Use Lane A for:**

- Freestanding `gnumach` builds (already works)
- MIG generation during kernel build
- Layout/scripts, packaging metadata, offline gates

**Do not expect Lane A alone for:**

- Full Hurd userspace (needs glibc for `x86_64-pc-gnu` or a Hurd guest)
- Running `makepkg` natively as on Hurd (needs guest)

### Lane B -- Ready QEMU images (Hurd guest / "native" tooling)

Official Debian GNU/Hurd **preinstalled** disk images (inspiration guest, not product base):

| Arch | URL pattern |
|---|---|
| amd64 | `https://cdimage.debian.org/cdimage/ports/latest/hurd-amd64/debian-hurd.img.tar.gz` (~497 MiB) |
| i386 | `https://cdimage.debian.org/cdimage/ports/latest/hurd-i386/debian-hurd.img.tar.gz` |

Documented QEMU pattern (Debian install docs):

```bash
# after extract
qemu-system-x86_64 -M q35 -m 2G -enable-kvm \
  -drive file=debian-hurd*.img,format=raw,cache=writeback \
  -device e1000,netdev=n0 -netdev user,id=n0,hostfwd=tcp::10022-:22 \
  -serial stdio
```

**Already on this workstation (do not re-download blindly):**

| Path | Role |
|---|---|
| `~/Github/gnu-hurd-docker/images/*.qcow2` | Multiple amd64 Hurd QEMU images (2025-11 through 2026-03, latest, working) |
| `~/Github/OS-Projects/GNUHurd2025/*.qcow2` / `.img` | Debian Hurd 2025-class images |
| `~/Github/gnu-hurd-docker/scripts/run-hurd-qemu.sh` | Mature QEMU launcher |
| `~/Github/gnu-hurd-docker/scripts/setup-hurd-dev.sh` | Guest dev setup |

**Use Lane B for:**

- Native Hurd compilers, tests, `apt` experiments (guest only)
- Proving pure-built `gnumach` boots a real userspace (swap kernel carefully)
- Building Arch packages **on** Hurd once bootstrap chroot exists

**Product rule:** Guest may be Debian Hurd for **tooling**. Arch_Hurd package **sources** remain pure GNU Savannah.

### Lane C -- Docker / Podman wrapping QEMU (not Hurd-in-Docker)

Hurd is a microkernel OS. There is **no useful official "Hurd userspace in a Linux container"** on Docker Hub (name collisions only: hurdbr, hurdlegroup, ...).

What **does** work: container **orchestrates** QEMU + disk images + SSH/serial.

**Existing project:** `~/Github/gnu-hurd-docker`

- `Dockerfile`, `compose.yaml`, KVM/podman/VNC variants
- Entrypoint launches QEMU with Hurd disk
- Documented workflows under `docs/01-GETTING-STARTED/`

```bash
cd ~/Github/gnu-hurd-docker
# see README / make targets -- do not reinvent in Arch_Hurd
```

**Use Lane C for:**

- Reproducible "start Hurd guest" for CI or multi-machine
- Isolating QEMU ports and credentials

**Do not** claim Docker runs Hurd natively without QEMU/KVM.

### Lane D -- Guix childhurd (optional)

Guix `hurd-vm-service-type` / childhurd runs Hurd VMs under Guix System, including 64-bit templates. Install Guix only if that workflow is desired. Not required for Arch_Hurd pure-source lane.

### Lane E -- Pure Savannah stage0 (this repo default product path)

```bash
make fetch stage0 mig gnumach root
```

Builds pure GNU kernel on Linux host. Complements Lanes A--C; does not replace guest for full userspace.

## Decision tree

```
Need MIG on Linux host?
  -> pacman -Q gnumig || install from OS-Projects/mig-gnu || make mig

Need to compile gnumach only?
  -> Lane A + E (host gcc freestanding)

Need Hurd userspace tools / test server behavior?
  -> Lane B/C with existing qcow2 (gnu-hurd-docker)

Need Arch packaging identity?
  -> This repo PKGBUILDs + pure Savannah sources (always)
```

## Integration scripts in Arch_Hurd

| Script | Purpose |
|---|---|
| `scripts/host-tooling-scan.sh` | paru/pacman/gnumig/qemu/docker/local-image inventory |
| `scripts/link-local-dev-assets.sh` | Symlink inventory of gnu-hurd-docker images + mig-gnu (no copy) |
| `scripts/qemu-guest-hint.sh` | Print recommended QEMU command using linked or env image |

Large downloads use explicit ACK env vars (see scripts).

## Honesty about earlier omission

The first bootstrap path over-indexed on source compilation and Debian pool pins. It did not:

1. Query **paru/pacman** for **gnumig** (already installed on this host)
2. Reuse **gnu-hurd-docker** and local qcow2 images
3. Separate **host tooling**, **guest environment**, and **product source base**

That is corrected here.
