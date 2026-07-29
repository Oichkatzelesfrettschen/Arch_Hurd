# Host package: gnumig (Linux side MIG)

GNU MIG is needed on the **Linux host** to build gnumach and Hurd stubs.

## Already installed on this workstation

```text
pacman -Q gnumig   # 1.8-1
# Provides: mig, gnu-mig
# Files: /usr/bin/mig, /usr/libexec/migcom
# Packager: local (eirikr), from OS-Projects/mig-gnu
```

## Source PKGBUILD (do not re-invent)

```text
~/Github/OS-Projects/mig-gnu/PKGBUILD
```

That recipe vendors gnumach 1.8 headers for `TARGET_CPPFLAGS` so MIG builds on Arch without a full Hurd sysroot.

## paru / AUR

- Official AUR search for `gnumig` returned **0** results in 2026-07 survey.
- Searching `mig` is useless noise (DB migration tools).
- Install path: `makepkg` from `OS-Projects/mig-gnu` or use this repo's `make mig` (Savannah-matched stage0).

## When to use which MIG

| MIG | When |
|---|---|
| Host `gnumig` | Quick host builds; may lag newest gnumach defs |
| `make mig` stage0 | Matched to pure Savannah gnumach HEAD (preferred for product kernel) |

If host mig fails with type errors / FPE on modern defs, use stage0 mig (already proven).
