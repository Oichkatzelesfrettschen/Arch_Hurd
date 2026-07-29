# Guest-native playbook: pure glibc + hurd (strategy a)

**Domain:** Hurd VM (gnu-hurd-docker or `make guest-shell-run`).  
**Product sources:** Savannah only. Guest OS may be Debian Hurd for tooling only.

## Host prep

```bash
make fetch link-assets
make guest-shell   # print launch
# Share pure trees:
scripts/guest-native-playbook.sh sync-share
```

Share directory: `build/guest-share/{gnumach,mig,hurd,glibc}` (git checkouts).

## Launch guest

```bash
ARCH_HURD_QEMU_ACK=yes make guest-shell-run
# ssh -p 2222 root@127.0.0.1
```

## On guest (outline)

```bash
# 1) build tools
apt-get update || true
apt-get install -y build-essential autoconf automake gawk bison flex texinfo git

# 2) use shared trees or re-clone Savannah
# 3) headers already usable from gnumach; rebuild mig if needed
# 4) configure glibc for Hurd --host=x86_64-gnu (see glibc Hurd docs)
# 5) build/install glibc to a sysroot
# 6) configure/build hurd against that sysroot
# 7) install rumpdisk translators; document noide if needed
# 8) scp logs back to host evidence/captures/guest-native-*.txt
```

## Host evidence after guest work

```bash
# from host, after collecting logs:
# evidence/captures/guest-native-$(date -u +%Y%m%dT%H%M%SZ).txt
```

## Exit gates

| Gate | Signal |
|---|---|
| glibc | `libc.so` for Hurd in sysroot + log |
| hurd | `/hurd/ext2fs` (or install prefix) + log |
| rump | boot note with rumpdisk |
| product | packages reimported as `hurd_x86_64` PKGBUILDs |

## Non-claims

Running Debian packages inside the guest is **not** ArchHurd M0.
