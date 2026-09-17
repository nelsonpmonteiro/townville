// ============================================================
// Runtime collision — derives the EFFECTIVE walkable map from the
// static world map + save-dependent obstacles:
//   - world exit gate: closed (blocks footprint) until every NPC of
//     the world is fully complete; open = walkable corridor
//   - Billy's fence gap (World 1): closes when Billy reaches phase 3
// Pure module. App calls effectiveWalkableMap(world, save) and feeds
// the result to canMoveTo().
// ============================================================

import { Save } from '../core';
import { WorldMap } from '../data/worldMaps';
import { applyFenceCollision } from './fence';
import { applyPropCollision, WORLD1_PROPS } from '../data/worldProps';
import { allNpcsComplete, FARM_NPCS, DOWNTOWN_NPCS } from '../state/buildingStates';

function blockRect(
  map: boolean[][],
  col: number, row: number, w: number, h: number
): void {
  for (let r = row; r < row + h; r++) {
    for (let c = col; c < col + w; c++) {
      if (map[r]?.[c] !== undefined) map[r][c] = false;
    }
  }
}

/** Effective walkable map for this world given current progress. */
export function effectiveWalkableMap(world: WorldMap, save: Save): boolean[][] {
  let map = world.walkableMap.map((row) => [...row]);

  // Gate: blocked while closed, walkable when open
  const gate = world.buildings.find((b) => b.sprite.includes('gate'));
  if (gate) {
    const npcs = world.id === 1 ? FARM_NPCS : DOWNTOWN_NPCS;
    const open = allNpcsComplete(save, npcs);
    if (!open) {
      blockRect(map, gate.footprintCol, gate.footprintRow, gate.footprintW, gate.footprintH);
    }
  }

  // Billy's fence (World 1 only) + blocking scenery props
  if (world.id === 1) {
    map = applyFenceCollision(map, save);
    map = applyPropCollision(map, WORLD1_PROPS);
  }

  return map;
}
