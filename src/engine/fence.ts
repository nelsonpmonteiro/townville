// ============================================================
// Billy's fence — the only runtime-mutable collision in the game.
//
// The fence is painted on the terrain chunk with a 2-tile gap on the
// bottom path. Billy's progress closes the gap with wooden posts:
//   0 phases done → gap open (both tiles walkable)
//   1-2 phases    → 1 post drawn (tile still walkable)
//   3-4 phases    → 2 posts drawn, BOTH tiles become blocked
//
// Pure module: rendering reads fencePosts(); movement reads
// applyFenceCollision(). No React, no side effects.
// ============================================================

import { Save, Point } from '../core';
import { completedPhaseCount } from '../state/buildingStates';

// Gap tiles on the bottom corridor next to Billy's event point (16,26).
// Path tiles at rows 26-27 span cols 14-17; the corridor proper is
// cols 15-16 — the gap closes the wide shoulder tiles (14,26) & (17,26).
// Verified against src/data/collision_w1.ts (rows 27-28 of the file).
export const FENCE_GAP_TILES: Point[] = [
  { x: 14, y: 26 },
  { x: 17, y: 26 },
];

/** How many posts are visible for Billy's progress. */
export function fencePostCount(save: Save): number {
  const done = completedPhaseCount(save, 'billy');
  if (done >= 3) return 2;
  if (done >= 1) return 1;
  return 0;
}

/** Tiles that currently show a post (first N of the gap). */
export function fencePosts(save: Save): Point[] {
  return FENCE_GAP_TILES.slice(0, fencePostCount(save));
}

/**
 * Fence collision applies ONLY when fully closed (2 posts): a single
 * post is decorative and the child can still walk through the gap.
 * Returns a NEW matrix; never mutates the base walkable map.
 */
export function applyFenceCollision(walkable: boolean[][], save: Save): boolean[][] {
  if (fencePostCount(save) < 2) return walkable;

  const result = walkable.map((row) => [...row]);
  for (const tile of FENCE_GAP_TILES) {
    if (result[tile.y]?.[tile.x] !== undefined) {
      result[tile.y][tile.x] = false;
    }
  }
  return result;
}
