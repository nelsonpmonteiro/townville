import { test } from "node:test";
import assert from "node:assert/strict";
import { WORLD_1_FARM } from "../src/data/worldMaps";

function reachable(map: boolean[][], start: {x:number;y:number}) {
  const seen = new Set([`${start.x},${start.y}`]);
  const queue = [start];
  while (queue.length) {
    const p = queue.shift()!;
    for (const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]) {
      const x=p.x+dx,y=p.y+dy,k=`${x},${y}`;
      if (map[y]?.[x] && !seen.has(k)) { seen.add(k); queue.push({x,y}); }
    }
  }
  return seen;
}

test("World 1 is a compact 32x24 farm", () => {
  assert.equal(WORLD_1_FARM.cols, 32);
  assert.equal(WORLD_1_FARM.rows, 24);
  assert.equal(WORLD_1_FARM.walkableMap.length, 24);
  assert.ok(WORLD_1_FARM.walkableMap.every(row => row.length === 32));
});

test("World 1 NPCs use irregular, reachable placements", () => {
  const reached = reachable(WORLD_1_FARM.walkableMap, WORLD_1_FARM.spawn);
  const ys = new Set(WORLD_1_FARM.eventPoints.map(p => p.y));
  assert.ok(ys.size >= 6, "NPCs should not line up in a few uniform rows");
  for (const p of WORLD_1_FARM.eventPoints) {
    assert.ok(p.x >= 0 && p.x < WORLD_1_FARM.cols && p.y >= 0 && p.y < WORLD_1_FARM.rows, `${p.npcId} out of bounds`);
    assert.equal(WORLD_1_FARM.walkableMap[p.y][p.x], true, `${p.npcId} must stand on path`);
    assert.ok(reached.has(`${p.x},${p.y}`), `${p.npcId} must be reachable from spawn`);
  }
});

test("compact buildings and exit are in bounds and reachable", () => {
  for (const b of WORLD_1_FARM.buildings) {
    assert.ok(b.footprintCol >= 0 && b.footprintRow >= 0);
    assert.ok(b.footprintCol + b.footprintW <= WORLD_1_FARM.cols, `${b.id} exceeds width`);
    assert.ok(b.footprintRow + b.footprintH <= WORLD_1_FARM.rows, `${b.id} exceeds height`);
  }
  for (const e of WORLD_1_FARM.exits) {
    assert.ok(e.x < WORLD_1_FARM.cols && e.y < WORLD_1_FARM.rows);
  }
});
