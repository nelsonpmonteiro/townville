// ============================================================
// World scenery props — decorative sprites placed over the terrain.
// Per HERMES-additional-sprites.md §2: hand-picked fixed list, no
// procedural generation.
//
// Collision: trees, stones and wells BLOCK their tile; bushes and
// flowers are walk-over. Positions were validated against
// collision_w1.ts — every prop sits on non-path ground, off
// buildings and off event points (tests/scenery.test.ts enforces).
// ============================================================

export type PropType =
  | 'tree'
  | 'bush'
  | 'flower-yellow'
  | 'flower-red'
  | 'stone'
  | 'well';

export interface WorldProp {
  type: PropType;
  col: number;
  row: number;
  /** Rendered height in tiles (spriteScale categories). */
  targetHeightTiles: number;
}

export const BLOCKING_PROP_TYPES: PropType[] = ['tree', 'stone', 'well'];

export const WORLD1_PROPS: WorldProp[] = [
  { type: 'tree', col: 9, row: 5, targetHeightTiles: 2.3 },
  { type: 'tree', col: 21, row: 4, targetHeightTiles: 2.3 },
  { type: 'tree', col: 29, row: 10, targetHeightTiles: 2.3 },
  { type: 'bush', col: 3, row: 10, targetHeightTiles: 0.65 },
  { type: 'bush', col: 10, row: 12, targetHeightTiles: 0.65 },
  { type: 'bush', col: 23, row: 15, targetHeightTiles: 0.65 },
  { type: 'bush', col: 19, row: 20, targetHeightTiles: 0.65 },
  { type: 'flower-yellow', col: 9, row: 13, targetHeightTiles: 0.4 },
  { type: 'flower-yellow', col: 22, row: 14, targetHeightTiles: 0.4 },
  { type: 'flower-red', col: 28, row: 12, targetHeightTiles: 0.4 },
  { type: 'flower-red', col: 4, row: 18, targetHeightTiles: 0.4 },
  { type: 'stone', col: 11, row: 18, targetHeightTiles: 0.35 },
  { type: 'stone', col: 23, row: 19, targetHeightTiles: 0.35 },
  { type: 'well', col: 29, row: 19, targetHeightTiles: 1.3 },
];

/** Block tiles occupied by blocking props. Returns a NEW matrix. */
export function applyPropCollision(
  walkable: boolean[][],
  props: WorldProp[]
): boolean[][] {
  const result = walkable.map((row) => [...row]);
  for (const p of props) {
    if (BLOCKING_PROP_TYPES.includes(p.type)) {
      if (result[p.row]?.[p.col] !== undefined) {
        result[p.row][p.col] = false;
      }
    }
  }
  return result;
}
