// Verify the actual renderer table against every installed PNG.
// Each direction shares one union-cropped canvas across idle + walk.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { runInNewContext } from "node:vm";

const PLAYER_DIR = join(__dirname, "..", "assets", "images", "player");
const source = readFileSync(join(__dirname, "../src/components/ProtagonistSprite.tsx"), "utf8");
const table = source.match(/const NATIVE_DIMS = (\{[\s\S]*?\}) as const;/);
assert.ok(table, "renderer must declare its static native dimension table");
const DIMS = JSON.parse(JSON.stringify(runInNewContext(`(${table[1]})`)));
const directions = ["front", "back", "left", "right"] as const;

function pngSize(path: string): { width: number; height: number } {
  const buf = readFileSync(path);
  assert.equal(buf.readUInt32BE(12), 0x49484452, `${path}: not a PNG/IHDR`);
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
}

test("all 32 walk frames match the renderer's per-direction dimensions", () => {
  for (const dir of directions) {
    for (let i = 0; i < 8; i++) {
      const size = pngSize(join(PLAYER_DIR, "walk", `boy-walk-${dir}-${i}.png`));
      assert.deepEqual(size, DIMS.walk[dir], `walk/${dir}-${i}: update NATIVE_DIMS`);
    }
  }
});

test("idle sprites match the renderer's native dimension table", () => {
  for (const dir of directions) {
    assert.deepEqual(pngSize(join(PLAYER_DIR, `boy-${dir}.png`)), DIMS.idle[dir], dir);
  }
});

test("idle and walk share exactly the same canvas per direction", () => {
  for (const dir of directions) {
    const idle = pngSize(join(PLAYER_DIR, `boy-${dir}.png`));
    for (let i = 0; i < 8; i++) {
      assert.deepEqual(pngSize(join(PLAYER_DIR, "walk", `boy-walk-${dir}-${i}.png`)), idle);
    }
  }
});
