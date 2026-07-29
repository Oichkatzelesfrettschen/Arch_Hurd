# Arch GNU/Hurd rebootstrap -- top-level gates
.PHONY: help plan check maps status preflight fetch stage0 mig gnumach hurd-headers cross-binutils root repo image all-offline clean smoke scan-tools link-assets guest-hint guest-shell guest-shell-run guest-s3 guest-playbook guest-share pure-gnu-gate identity-gate legacy-gate test

help:
	@echo "targets:"
	@echo "  plan status check test maps preflight scan-tools link-assets"
	@echo "  guest-shell guest-shell-run guest-s3 guest-playbook guest-share guest-hint"
	@echo "  pure-gnu-gate identity-gate legacy-gate"
	@echo "  fetch stage0 mig gnumach hurd-headers cross-binutils root repo image all-offline"
	@echo "  smoke  (needs IMAGE=... ARCH_HURD_QEMU_ACK=yes)"

plan:
	bash scripts/plan.sh

check:
	bash scripts/check.sh

maps:
	bash scripts/gen-maps.sh

pure-gnu-gate:
	bash scripts/verify-pure-gnu-default.sh

identity-gate:
	bash scripts/verify-identity.sh

legacy-gate:
	bash scripts/verify-legacy.sh

test:
	bash tests/test_pure_gnu_gate.sh
	bash tests/test_maps_inventory.sh
	bash tests/test_identity.sh
	bash tests/test_legacy.sh

status:
	bash scripts/status.sh

preflight:
	bash scripts/host-preflight.sh

scan-tools:
	bash scripts/host-tooling-scan.sh

link-assets:
	bash scripts/link-local-dev-assets.sh

guest-hint:
	bash scripts/qemu-guest-hint.sh

guest-shell:
	bash scripts/guest-shell.sh hint

guest-shell-run:
	ARCH_HURD_QEMU_ACK=yes bash scripts/guest-shell.sh run

# S3 guest-native glibc+hurd (ACK required; uses overlay + SSH key when present)
guest-s3:
	ARCH_HURD_QEMU_ACK=yes bash scripts/guest-s3-run.sh

# S2 host cross binutils for x86_64-gnu
cross-binutils:
	bash scripts/build-cross-binutils.sh

fetch:
	bash scripts/fetch-sources.sh

# Optional comparison only -- never default product base
fetch-debian-inspiration:
	bash scripts/fetch-debian-inspiration.sh

stage0:
	bash scripts/build-stage0-headers.sh

mig: stage0
	bash scripts/build-mig.sh

gnumach: mig
	bash scripts/build-gnumach.sh

hurd-headers: stage0
	bash scripts/build-hurd-headers.sh

root:
	bash scripts/mkhurdroot.sh

repo:
	bash scripts/seed-local-repo.sh

image:
	bash scripts/assemble-bootstrap-image.sh

guest-playbook:
	bash scripts/guest-native-playbook.sh emit

guest-share:
	bash scripts/guest-native-playbook.sh sync-share

# Offline-ish chain: does not require QEMU ACK
all-offline: fetch stage0 mig gnumach hurd-headers root repo image guest-playbook
	@echo "all-offline complete (kernel+headers+bootstrap tarball)"

smoke:
	@test -n "$(IMAGE)" || (echo "set IMAGE=/path/to.img" >&2; exit 2)
	ARCH_HURD_QEMU_ACK=yes bash scripts/qemu-smoke.sh "$(IMAGE)"

clean:
	rm -rf build/src build/stage0 build/hurd-root build/hurd-root-check
	rm -rf analysis/maps/*.out analysis/maps/*.cscope.out 2>/dev/null || true
