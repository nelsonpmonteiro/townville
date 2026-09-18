#!/usr/bin/env bash
# Publish dist/ to GitHub Pages (https://nelsonpmonteiro.github.io/townville/).
#
# Why not just Vercel: Vercel has repeatedly stalled deployments in
# "Initializing"/"Queued" forever and returned deploy_failed/"Deployment not
# found" during platform incidents, leaving production silently stale. GitHub
# Pages serves the same static folder from a branch we control, so publishing
# never depends on a third party's build queue being healthy.
#
# Usage: scripts/deploy-pages.sh          (expects dist/ already built)
#        scripts/deploy-web.sh && scripts/deploy-pages.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${REPO:-https://github.com/nelsonpmonteiro/townville.git}"
URL="${URL:-https://nelsonpmonteiro.github.io/townville}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

[ -s "$ROOT/dist/index.wasm" ] || { echo "dist/ is missing or unbuilt — run scripts/deploy-web.sh first"; exit 1; }

echo "== 1. staging dist/"
cp "$ROOT"/dist/* "$WORK/"
# Jekyll would otherwise drop files and mangle the Godot loader's assets.
touch "$WORK/.nojekyll"
du -sh "$WORK" | sed 's/^/   /'

echo "== 2. pushing to the gh-pages branch"
cd "$WORK"
git init -q
git checkout -q -b gh-pages
git add -A
git -c user.email=deploy@local -c user.name="Townville Deploy" \
    commit -q -m "deploy: Townville web build $(date -u +%Y-%m-%dT%H:%M:%SZ)"
git remote add origin "$REPO"
git push -f -q origin gh-pages
echo "   pushed"

echo "== 3. waiting for Pages to serve the new build"
# Pages builds asynchronously; poll the live file rather than trusting the API.
expected="$(shasum -a 256 "$ROOT/dist/index.pck" | cut -d' ' -f1)"
for i in $(seq 1 40); do
  sleep 10
  live="$(curl -fsS "$URL/index.pck" 2>/dev/null | shasum -a 256 | cut -d' ' -f1 || true)"
  if [ "$live" = "$expected" ]; then
    echo "   live build matches dist/ (sha ${expected:0:12})"
    echo "   $URL/"
    exit 0
  fi
  printf "   still serving the old build (%ds)\n" $((i * 10))
done

echo "TIMEOUT: Pages did not serve the new build within ~7 minutes"
exit 1
