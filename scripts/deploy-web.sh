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

echo "== 1. export (preset 'Web': runnable, desktop VRAM only, no PWA, no GDExtension)"
mkdir -p "$OUT"
"$GODOT" --headless --path "$ROOT/godot" --export-release "Web" "$OUT/index.html" 2>&1 \
  | grep -E "^SCRIPT ERROR|Project export .* failed" | grep -v grass_dirt_tileset && { echo "export errors"; exit 1; } || true

echo "== 2. required files"
for f in index.html index.js index.wasm index.pck index.audio.worklet.js; do
  [ -s "$OUT/$f" ] || { echo "MISSING $f"; exit 1; }
  printf "   %-26s %8d KB\n" "$f" $(( $(stat -f%z "$OUT/$f") / 1024 ))
done
mkdir -p "$ROOT/dist" && cp "$OUT"/* "$ROOT/dist/"
echo "   → $ROOT/dist/ (deploy this whole folder together)"

[ "${1:-}" = "--no-probe" ] && exit 0

echo "== 3. static server on :$PORT"
if ! curl -s -o /dev/null "http://localhost:$PORT/index.html"; then
  (cd "$ROOT/dist" && python3 -m http.server "$PORT" >/dev/null 2>&1 &)
  sleep 1
fi
for f in index.wasm index.pck index.js; do
  printf "   %-12s %s\n" "$f" "$(curl -sI "http://localhost:$PORT/$f" | grep -i content-type | tr -d '\r')"
done

echo "== 4. real-browser acceptance (fps, input, onboarding, NPC loop)"
cd "$ROOT" && node scripts/web-perf-probe.cjs | tail -3
