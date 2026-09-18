#!/usr/bin/env bash
# Townville — build the Godot web export and verify it from a plain static file
# server (never the editor preview). Usage:
#   scripts/deploy-web.sh            # build → dist/ → serve :8090 → probe
#   scripts/deploy-web.sh --no-probe # build only
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Users/nelsonmonteiro/Applications/Godot.app/Contents/MacOS/Godot}"
OUT=/tmp/townville-web
PORT="${PORT:-8090}"

echo "== 0. static UI glyph guard"
python3 "$ROOT/scripts/check-ui-glyphs.py"

echo "== 1. headless suites"
# NOTE: capture the output instead of piping into `grep -q`. grep -q exits at
# the first match, and suites that still print Godot's "ObjectDB instances were
# leaked" warnings AFTER "ALL TESTS PASSED" then die with SIGPIPE (141), which
# `set -o pipefail` turns into a bogus FAILED for a suite that actually passed.
for t in tests/test_runner.gd tests/test_editor_delete.gd tests/test_editor_move.gd tests/test_depth_order.gd tests/test_audio.gd tests/test_restart.gd tests/test_ending.gd tests/test_success_screen.gd tests/test_array_hint.gd; do
  out="$("$GODOT" --headless --path "$ROOT/godot" --script "$t" 2>&1 || true)"
  if grep -qE "ALL TESTS PASSED" <<<"$out"; then
    echo "   $t OK"
  else
    echo "   $t FAILED"
    grep -E "^(FAIL|TEST FAILURES)|Parse Error|SCRIPT ERROR" <<<"$out" | head -20
    exit 1
  fi
done

echo "== 2. export (preset 'Web': runnable, desktop VRAM only, no PWA, no GDExtension)"
mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT/godot" --export-release "Web" "$OUT/index.html" 2>&1 \
  | grep -E "^SCRIPT ERROR|Project export .* failed" | grep -v grass_dirt_tileset && { echo "export errors"; exit 1; } || true

echo "== 3. required files"
for f in index.html index.js index.wasm index.pck index.audio.worklet.js; do
  [ -s "$OUT/$f" ] || { echo "MISSING $f"; exit 1; }
  printf "   %-26s %8d KB\n" "$f" $(( $(stat -f%z "$OUT/$f") / 1024 ))
done
mkdir -p "$ROOT/dist" && cp "$OUT"/* "$ROOT/dist/"
echo "   → $ROOT/dist/ (deploy this whole folder together)"

[ "${1:-}" = "--no-probe" ] && exit 0

echo "== 4. static server on :$PORT"
if ! curl -s -o /dev/null "http://localhost:$PORT/index.html"; then
  (cd "$ROOT/dist" && python3 -m http.server "$PORT" >/dev/null 2>&1 &)
  sleep 1
fi
for f in index.wasm index.pck index.js; do
  printf "   %-12s %s\n" "$f" "$(curl -sI "http://localhost:$PORT/$f" | grep -i content-type | tr -d '\r')"
done

echo "== 5. real-browser acceptance (fps, input, onboarding, NPC loop)"
cd "$ROOT" && node scripts/web-perf-probe.cjs | tail -3
