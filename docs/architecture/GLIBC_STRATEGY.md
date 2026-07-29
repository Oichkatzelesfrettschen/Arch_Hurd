# glibc strategy (locked)

**Decision (2026-07-26):** plan review option **(a) guest-native**.

## Choice

| Option | Description | Status |
|---|---|---|
| **(a) guest-native** | Build pure Savannah glibc/hurd **inside** a Hurd QEMU guest (gnu-hurd-docker images), then package results for Arch identity | **SELECTED** |
| (b) host cross | Full `x86_64-pc-gnu` cross toolchain on Linux host | deferred unless guest boot fails |

## Why (a)

1. Host lacks `x86_64-pc-gnu-gcc` today.
2. Workstation already has Hurd qcow2 images and `gnu-hurd-docker`.
3. Native Hurd compilers exercise real RPC/glibc paths that cross can miss.
4. Product **sources** remain pure Savannah; guest OS may be Debian Hurd for the **build environment only**.

## Falsifier

If guest cannot boot or cannot compile pure `hurd.git` / glibc after documented setup, switch to (b) and record evidence under `evidence/captures/glibc-strategy-flip-*.txt`.

## Procedure sketch

1. `make link-assets && make guest-shell` (hint)
2. Launch guest: `ARCH_HURD_QEMU_ACK=yes make guest-shell-run` (or gnu-hurd-docker runner)
3. On guest: install build-essential equivalents; clone or 9p-mount Savannah trees
4. Configure/build glibc for Hurd, then hurd servers
5. Export artifacts back to host for PKGBUILD / stage root
6. Keep claims honest: guest build != Arch M0 until pacman path works

## Non-claims

- Guest Debian userland is not the Arch product root.
- Success of one package build on guest does not close M0.
