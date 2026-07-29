# Source policy: pure GNU/Hurd base

**Decision (2026-07-26):** Arch GNU/Hurd builds from **pure GNU/Hurd project sources** on Savannah. Debian GNU/Hurd is **inspiration only**, not the base.

## Base (authoritative)

| Component | Upstream | Clone URL |
|---|---|---|
| GNU Mach | GNU Hurd project | `https://git.savannah.gnu.org/git/hurd/gnumach.git` |
| MIG | GNU Hurd project | `https://git.savannah.gnu.org/git/hurd/mig.git` |
| Hurd | GNU Hurd project | `https://git.savannah.gnu.org/git/hurd/hurd.git` |
| glibc (Hurd port) | GNU (Hurd maintenance branch) | `https://git.savannah.gnu.org/git/hurd/glibc.git` (or glibc master + Hurd) |
| Documentation | hurd-web | Savannah / darnassus wiki |

Building docs (pure GNU):

- https://www.gnu.org/software/hurd/microkernel/mach/gnumach/building.html
- https://www.gnu.org/software/hurd/hurd/building.html
- https://www.gnu.org/software/hurd/source_repositories.html

## Inspiration only (not base)

| Source | Allowed use | Forbidden use |
|---|---|---|
| Debian gnumach/hurd/mig packages | Compare configure flags, learn which patches exist, read packaging scripts | Default tarball, default patch series, dpkg identity |
| Guix Hurd | Reproducible build recipes, QEMU args (`q35`, `noide`) | Guix store as product base |
| Alpine Hurd | Minimal userspace ideas | musl identity for Arch product |
| Historical Arch Hurd (z3ntu) | PKGBUILD layout patterns | Frozen i686 package versions as product |

## Rule of thumb

```
product_identity = Arch (pacman, PKGBUILD, rolling, KISS)
kernel_userspace  = pure GNU (Savannah gnumach + hurd + mig + ...)
distro_inspiration = Debian/Guix/Alpine process knowledge only
```

If a Debian patch is useful, **upstream it or vendor a documented Arch-local patch** under `packages/*/patches/` with provenance. Do not silently apply `debian/patches/series` as the default build.

## Rump

Rump disk/net live **in the pure Hurd tree** (`hurd/rumpdisk`, `hurd/rumpnet`), not as a Debian-only invention. Debian packaging of `rumpkernel` remains a useful *reference* for NetBSD rump library versions, not the Arch base tarball.

## Migration from earlier session error

Earlier bootstrap incorrectly treated Debian pool tarballs + `debian/patches` as the default oracle. That is **rescinded**. Scripts now default to Savannah git. Debian artifacts may remain under `build/cache/debian-inspiration/` for comparison only.
