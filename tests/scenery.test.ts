// Scenery contract tests — props must sit on valid ground and their
// assets must exist. Guards against spec drift when positions or
// assets change.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";
import {
  WORLD1_PROPS,
  BLOCKING_PROP_TYPES,
  applyPropCollision,
} from "../src/data/worldProps";
import { WORLD_1_FARM } from "../src/data/worldMaps";
import { effectiveWalkableMap } from "../src/engine/collision";
import * as core from "../src/core";
import { FENCE_GAP_TILES } from "../src/engine/fence";

const SCENERY_DIR = join(__dirname, "..", "assets", "images", "scenery", "world1");

test("every prop type has its PNG asset present", () => {
  const types = new Set(WORLD1_PROPS.map((p) => p.type));
  for (const t of types) {
    const path = join(SCENERY_DIR, `scenery-${t}.png`);
    assert.ok(existsSync(path), `missing asset: scenery-${t}.png`);
  }
});

test("props are in-grid, off paths, off buildings, off event points", () => {
  for (const p of WORLD1_PROPS) {
    assert.ok(p.col >= 0 && p.col < 40 && p.row >= 0 && p.row < 30, `${p.type} out of grid`);

    // Not on walkable path (props sit on decorative ground)
    assert.equal(
      WORLD_1_FARM.walkableMap[p.row][p.col],
      false,
      `${p.type} (${p.col},${p.row}) sits on the walkable path`
    );

    // Not inside a building footprint
    for (const b of WORLD_1_FARM.buildings) {
      const inside =
        p.col >= b.footprintCol && p.col < b.footprintCol + b.footprintW &&
        p.row >= b.footprintRow && p.row < b.footprintRow + b.footprintH;
      assert.ok(!inside, `${p.type} (${p.col},${p.row}) inside building ${b.id}`);
    }

    // Not on an event point
    const ep = WORLD_1_FARM.eventPoints.find((e) => e.x === p.col && e.y === p.row);
    assert.equal(ep, undefined, `${p.type} (${p.col},${p.row}) on event point ${ep?.id}`);

    // Not on Billy's fence gap
    const onFence = FENCE_GAP_TILES.some((t) => t.x === p.col && t.y === p.row);
    assert.ok(!onFence, `${p.type} (${p.col},${p.row}) on fence gap tile`);
  }
});

test("blocking props block their tile; walk-over props don't", () => {
  // All-true base to observe the prop effect in isolation
  const base: boolean[][] = Array.from({ length: 30 }, () =>
    Array.from({ length: 40 }, () => true)
  );
  const applied = applyPropCollision(base, WORLD1_PROPS);

  for (const p of WORLD1_PROPS) {
    const expected = !BLOCKING_PROP_TYPES.includes(p.type);
    assert.equal(
      applied[p.row][p.col],
      expected,
      `${p.type} (${p.col},${p.row}) expected walkable=${expected}`
    );
  }
  // Base not mutated
  assert.equal(base[WORLD1_PROPS[0].row][WORLD1_PROPS[0].col], true);
});

test("effective map includes prop collision for World 1", () => {
  const map = effectiveWalkableMap(WORLD_1_FARM, core.fresh());
  const tree = WORLD1_PROPS.find((p) => p.type === "tree")!;
  assert.equal(map[tree.row][tree.col], false);
});

test("scenery PNGs are trimmed (content fills canvas height)", () => {
  // PNG IHDR dims must match the trimmed sizes recorded at install time.
  const expected: Record<string, [number, number]> = {
    "scenery-tree.png": [48, 80],
    "scenery-bush.png": [44, 27],
    "scenery-flower-yellow.png": [18, 35],
    "scenery-flower-red.png": [18, 35],
    "scenery-stone.png": [26, 16],
    "scenery-well.png": [33, 49],
  };
  for (const [file, [w, h]] of Object.entries(expected)) {
    const buf = readFileSync(join(SCENERY_DIR, file));
    assert.equal(buf.readUInt32BE(16), w, `${file} width`);
    assert.equal(buf.readUInt32BE(20), h, `${file} height`);
  }
});
