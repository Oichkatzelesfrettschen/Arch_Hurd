# Product identity: ArchHurd x86_64 (hurd_x86_64)

**Decision (2026-07-28):** The product is an ALPM-managed GNU/Hurd distribution.
It is not Arch Linux packages on Hurd, not Debian dpkg identity, and not NetBSD userland.

## Four roles (keep distinct)

| Role | Supplier | Product use |
|---|---|---|
| OS ABI | GNU/Hurd (Mach, servers, glibc, MIG, rump) | Product runtime |
| Distribution model | Arch (PKGBUILD, makepkg, pacman, signing, rolling) | Product packaging |
| Bootstrap/porting corpus | Debian GNU/Hurd | Reference only: versions, patches, build order, images |
| Future driver donor | NetBSD 11 | Optional rump refresh / later graphics; not Release 0.1 blocker |

## Three architecture identifiers

| Purpose | Identifier |
|---|---|
| CPU ISA | `x86_64` |
| GNU configure tuple | compiler `-dumpmachine` (typically `x86_64-unknown-gnu` / multiarch `x86_64-gnu`) |
| **ALPM package architecture** | **`hurd_x86_64`** |

Plain `x86_64` is reserved for **host bootstrap** packages that run on Arch Linux.
Target packages must use `arch=('hurd_x86_64')` so Linux ELF packages cannot install by accident.

## Target pacman policy

```ini
Architecture = hurd_x86_64
# Never enable Arch Linux [core]/[extra] on the target.
# LocalFileSigLevel requires ArchHurd signatures (keyring milestone).
```

PKGBUILD provenance fields (informational; enforced by audit hook):

```bash
arch=('hurd_x86_64')
xdata=(
  'osabi=hurd-gnu'
  'gnu_tuple=x86_64-gnu'
)
```

## Compatibility policy

- `hurd_x86_64` packages depend only on `hurd_x86_64` or `any`.
- Arch Linux repositories are never configured on the target.
- Target keyring does not trust Arch Linux package-signing keys by default.
- Host bootstrap packages live in a separate Linux `[bootstrap]` concept (`x86_64`).
- Debian packages are never the default product root or dpkg runtime identity.

## Graphics policy (first release)

- First usable release does **not** depend on rump DRM/KMS.
- Prefer Hurd console + non-DRM X paths later; graphics subsystem is a separate gate.
- NetBSD rump DRM experiments are post-M0 optional work.

## Conversion note

Imported Arch Linux PKGBUILDs often declare `arch=('x86_64')`. Convert to
`hurd_x86_64` with `scripts/convert-pkgbuild-arch.sh` before packaging for the target.
