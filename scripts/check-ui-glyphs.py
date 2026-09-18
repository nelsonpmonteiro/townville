#!/usr/bin/env python3
"""Reject fragile non-ASCII glyphs in Godot UI string literals.

The Web export's default font renders some symbols as square "tofu" boxes.
Keep player-visible strings in runtime/editor GDScript ASCII-only unless a
project font with explicit glyph coverage is introduced later.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1] / "godot"
SCAN_EXTENSIONS = {".gd", ".tscn", ".tres", ".godot"}


def strings_before_comment(line: str):
    strings = []
    buf = []
    quote = False
    escaped = False
    for char in line:
        if quote:
            if escaped:
                buf.append(char)
                escaped = False
            elif char == "\\":
                buf.append(char)
                escaped = True
            elif char == '"':
                strings.append("".join(buf))
                buf = []
                quote = False
            else:
                buf.append(char)
        elif char == "#":
            break
        elif char == '"':
            quote = True
    return strings


failures = []
for path in sorted(ROOT.rglob("*")):
    if not path.is_file() or path.suffix not in SCAN_EXTENSIONS:
        continue
    if any(part in {".godot", "tests"} for part in path.relative_to(ROOT).parts):
        continue
    for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        for value in strings_before_comment(line):
            bad = sorted({c for c in value if ord(c) > 127})
            if bad:
                codes = ", ".join(f"{c!r}=U+{ord(c):04X}" for c in bad)
                failures.append(f"{path.relative_to(ROOT.parent)}:{line_no}: {codes}")

if failures:
    print("Unsupported/unguarded UI glyphs found:")
    print("\n".join(failures))
    sys.exit(1)
print("UI glyph check: PASS (runtime/editor strings are ASCII-safe)")
