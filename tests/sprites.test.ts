// Sprite asset contract tests.
//
// Guards the sizing system against silent asset drift:
// 1. The STATIC dimension table in ProtagonistSprite must match the
//    real PNG files (walk 40×106, idle per-direction trimmed sizes).
// 2. Player sprites must be TRIMMED (content == canvas) — untrimmed
//    padding makes the character visually shrink at render time.
// If you replace player art, re-trim and update NATIVE_DIMS.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const PLAYER_DIR = join(__dirname, "..", "assets", "images", "player");

/** Read PNG dimensions straight from the IHDR chunk (no deps). */
function pngSize(path: string): { width: number; height: number } {
  const buf = readFileSync(path);
  // PNG signature (8 bytes) + IHDR length/type (8 bytes) → width @16, height @20
  assert.equal(buf.readUInt32BE(12), 0x49484452, `${path}: not a PNG/IHDR`);
  return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) };
}

// Must mirror NATIVE_DIMS in src/components/ProtagonistSprite.tsx
const EXPECTED = {
  walk: { width: 40, height: 106 },
  idle: {
    front: { width: 25, height: 58 },
    back: { width: 24, height: 59 },
    left: { width: 25, height: 59 },
    right: { width: 25, height: 59 },
  },
};

test("all 32 walk frames match the static dimension table", () => {
  for (const dir of ["front", "back", "left", "right"] as const) {
    for (let i = 0; i < 8; i++) {
      const p = join(PLAYER_DIR, "walk", `boy-walk-${dir}-${i}.png`);
      const size = pngSize(p);
      assert.deepEqual(
        size,
        EXPECTED.walk,
        `walk/${dir}-${i}: ${size.width}x${size.height} ≠ table ${EXPECTED.walk.width}x${EXPECTED.walk.height} — retrim or update NATIVE_DIMS`
      );
    }
  }
});

test("idle sprites match the static dimension table (trimmed)", () => {
  for (const dir of ["front", "back", "left", "right"] as const) {
    const p = join(PLAYER_DIR, `boy-${dir}.png`);
    const size = pngSize(p);
    assert.deepEqual(
      size,
      EXPECTED.idle[dir],
      `boy-${dir}: ${size.width}x${size.height} ≠ table — retrim or update NATIVE_DIMS`
    );
  }
});

test("idle and walk render at consistent on-screen proportions", () => {
  // At equal target height, rendered widths must be within ~25% of each
  // other; a larger gap means someone reintroduced canvas padding.
  const target = 67; // CHARACTER_TARGET_HEIGHT
  const walkW = (EXPECTED.walk.width / EXPECTED.walk.height) * target;
  for (const dir of ["front", "back", "left", "right"] as const) {
    const idle = EXPECTED.idle[dir];
    const idleW = (idle.width / idle.height) * target;
    const ratio = Math.max(idleW, walkW) / Math.min(idleW, walkW);
    assert.ok(
      ratio < 1.25,
      `${dir}: idle renders ${idleW.toFixed(1)}px wide vs walk ${walkW.toFixed(1)}px (ratio ${ratio.toFixed(2)}) — sprites drifted`
    );
  }
});
