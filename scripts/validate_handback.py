#!/usr/bin/env python3
"""Validate agent handback TSV files against the bounded schema."""
from __future__ import annotations

import sys
from pathlib import Path

REQUIRED = ["agent_id", "row_id", "kind", "key", "value", "authority", "confidence", "notes"]
CONF = {"known", "hypothesized", "speculative"}


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {argv[0]} handback.tsv", file=sys.stderr)
        return 2
    path = Path(argv[1])
    if not path.is_file():
        print(f"missing file: {path}", file=sys.stderr)
        return 1
    text = path.read_text(encoding="utf-8", errors="strict")
    if not text.isascii():
        print("handback must be ASCII", file=sys.stderr)
        return 1
    lines = [ln for ln in text.splitlines() if ln.strip()]
    if not lines:
        print("empty handback", file=sys.stderr)
        return 1
    header = lines[0].split("\t")
    if header != REQUIRED:
        print(f"bad header: {header}", file=sys.stderr)
        return 1
    for i, ln in enumerate(lines[1:], start=2):
        cols = ln.split("\t")
        if len(cols) != len(REQUIRED):
            print(f"line {i}: expected {len(REQUIRED)} columns", file=sys.stderr)
            return 1
        conf = cols[6]
        if conf not in CONF:
            print(f"line {i}: bad confidence {conf}", file=sys.stderr)
            return 1
    print(f"OK {path} rows={len(lines)-1}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
