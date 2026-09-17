// Contract tests: derived building states + runtime collision
// (gates and Billy's fence) — the only save-dependent collision.
import { test } from "node:test";
import assert from "node:assert/strict";
import * as core from "../src/core";
import {
  computeBuildingStates,
  completedPhaseCount,
  stateFromPhaseCount,
  allNpcsComplete,
  FARM_NPCS,
} from "../src/state/buildingStates";
import { fencePosts, fencePostCount, applyFenceCollision, FENCE_GAP_TILES } from "../src/engine/fence";
import { effectiveWalkableMap } from "../src/engine/collision";
import { WORLD_1_FARM } from "../src/data/worldMaps";

function saveWithPhases(npcId: string, phases: number): core.Save {
  let s = core.fresh();
  for (let p = 1; p <= phases; p++) s = core.completeEventPoint(s, npcId, p);
  return s;
}

function fullyCompleteFarm(): core.Save {
  let s = core.fresh();
  for (const npc of FARM_NPCS) {
    for (let p = 1; p <= 4; p++) s = core.completeEventPoint(s, npc, p);
  }
  return s;
}

test("building state follows NPC phase count (0..4 → LOCKED..COMPLETE)", () => {
  assert.equal(stateFromPhaseCount(0), "LOCKED");
  assert.equal(stateFromPhaseCount(1), "STAGE_1");
  assert.equal(stateFromPhaseCount(2), "STAGE_2");
  assert.equal(stateFromPhaseCount(3), "STAGE_3");
  assert.equal(stateFromPhaseCount(4), "COMPLETE");

  const s = saveWithPhases("mae", 2);
  assert.equal(completedPhaseCount(s, "mae"), 2);
  assert.equal(computeBuildingStates(s)["henhouse"], "STAGE_2");
  assert.equal(computeBuildingStates(s)["stable"], "LOCKED"); // chester untouched
});

test("garden derives from grandma-rose; fountain always COMPLETE", () => {
  const fresh = computeBuildingStates(core.fresh());
  assert.equal(fresh["garden"], "LOCKED");
  assert.equal(fresh["fountain"], "COMPLETE");

  const s = saveWithPhases("grandma-rose", 4);
  assert.equal(computeBuildingStates(s)["garden"], "COMPLETE");
});

test("farm gate opens ONLY when every farm NPC is fully complete", () => {
  assert.equal(computeBuildingStates(core.fresh())["farm-gate"], "LOCKED");

  // All but billy complete → still locked
  let s = core.fresh();
  for (const npc of FARM_NPCS.filter((n) => n !== "billy")) {
    for (let p = 1; p <= 4; p++) s = core.completeEventPoint(s, npc, p);
  }
  assert.equal(allNpcsComplete(s, FARM_NPCS), false);
  assert.equal(computeBuildingStates(s)["farm-gate"], "LOCKED");

  // Everyone complete → open
  const done = fullyCompleteFarm();
  assert.equal(computeBuildingStates(done)["farm-gate"], "COMPLETE");
});

test("billy fence: 0 phases = open, 1-2 = 1 post (walkable), 3+ = closed", () => {
  assert.equal(fencePostCount(core.fresh()), 0);
  assert.equal(fencePostCount(saveWithPhases("billy", 1)), 1);
  assert.equal(fencePostCount(saveWithPhases("billy", 2)), 1);
  assert.equal(fencePostCount(saveWithPhases("billy", 3)), 2);
  assert.equal(fencePosts(saveWithPhases("billy", 3)).length, 2);

  // 1 post: decorative, tiles stay as base map
  const base = WORLD_1_FARM.walkableMap;
  const onePost = applyFenceCollision(base, saveWithPhases("billy", 1));
  for (const t of FENCE_GAP_TILES) {
    assert.equal(onePost[t.y][t.x], base[t.y][t.x]);
  }

  // 2 posts: both gap tiles blocked; base map NOT mutated
  const closed = applyFenceCollision(base, saveWithPhases("billy", 4));
  for (const t of FENCE_GAP_TILES) {
    assert.equal(closed[t.y][t.x], false);
  }
  assert.notEqual(closed, base);
});

test("effective map: gate blocks exit corridor until farm complete", () => {
  const gate = WORLD_1_FARM.buildings.find((b) => b.id === "farm-gate")!;
  const tile = { x: gate.footprintCol + 1, y: gate.footprintRow }; // (15,28) corridor

  // Base map has the corridor walkable (gate footprint NOT pre-blocked)
  assert.equal(WORLD_1_FARM.walkableMap[tile.y][tile.x], true);

  // Fresh save → closed gate blocks it
  const closed = effectiveWalkableMap(WORLD_1_FARM, core.fresh());
  assert.equal(closed[tile.y][tile.x], false);

  // Farm complete → gate open, corridor walkable again
  const open = effectiveWalkableMap(WORLD_1_FARM, fullyCompleteFarm());
  assert.equal(open[tile.y][tile.x], true);
});

test("fence gap tiles sit on walkable ground and are not event points", () => {
  for (const t of FENCE_GAP_TILES) {
    assert.equal(
      WORLD_1_FARM.walkableMap[t.y][t.x],
      true,
      `fence tile (${t.x},${t.y}) must be on walkable ground`
    );
    const clash = WORLD_1_FARM.eventPoints.find((ep) => ep.x === t.x && ep.y === t.y);
    assert.equal(clash, undefined, `fence tile (${t.x},${t.y}) collides with ${clash?.id}`);
  }
});
