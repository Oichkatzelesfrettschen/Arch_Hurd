# Agent instructions for Arch_Hurd

## Instruction source

`AGENTS.md` is the root instruction file for Arch_Hurd and owns its rules. Every agent and contributor reads it directly. `CLAUDE.md` is a tracked, repository-relative symbolic link to `AGENTS.md`, so Claude Code receives the canonical rules through the same bytes and the body lives in one place. A tool that requires a differently named loader references this file rather than copying doctrine that can drift.

## Orchestrator owns

- Final claims in `frontier/CLAIMS_EVIDENCE.tsv`
- Hazard decisions (QEMU, disk images, network publishes)
- Merges of agent handbacks
- Implementation of load-bearing scripts and PKGBUILDs
- Roadmap status transitions

## Agents own

- Bounded reads per `agents/contracts/*`
- Handbacks only under `agents/handbacks/`
- Lexical maps under `analysis/maps/` when contracted

## Hard rules

1. Do not claim M0 green without `evidence/captures/m0-*`.
2. Do not treat cflow/cscope maps as runtime proof.
3. Primary triple is `x86_64-pc-gnu`; i686 is archival.
4. Pure GNU Savannah is the source base; Debian/Guix are inspiration only (SOURCE_POLICY.md).
5. ASCII for scripts, TSV, Makefile.
6. No force-push; no destructive clean of operator evidence without approval.

## Useful commands

```bash
make check
make maps
make status
make preflight
```
