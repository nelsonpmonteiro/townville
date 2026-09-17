// World map data for Townville MVP
// 40 cols × 30 rows per world (pixel-perfect data)
// Based on HERMES-pixel-perfect-placement.md

import { WORLD1_WALKABLE } from './collision_w1';
import { WORLD2_WALKABLE } from './collision_w2';

export type Tile = '.' | '#' | 'E' | 'X' | 'S';

export interface EventPoint {
  id: string;
  npcId: string;
  x: number; // tile col
  y: number; // tile row
}

export interface Building {
  id: string;
  npcId?: string; // NPC that unlocks this building
  sprite: string; // base name (without -locked suffix)
  footprintCol: number;
  footprintRow: number;
  footprintW: number; // in tiles
  footprintH: number; // in tiles
}

export interface WorldMap {
  id: number;
  name: string;
  cols: number;
  rows: number;
  collisionMap: Tile[][]; // Legacy format - use walkableMap instead
  walkableMap: boolean[][]; // Pixel-perfect collision data (true = walkable)
  spawn: { x: number; y: number };
  exits: Array<{ x: number; y: number; toWorld: number }>;
  eventPoints: EventPoint[];
  buildings: Building[];
}

// World 1 - Farm (30×20)
// Collision map adjusted for corrected building/event point positions
const farmCollisionMap: Tile[][] = [
  // Row 0
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 1
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 2
  ['#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#'],
  // Row 3
  ['#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#'],
  // Row 4
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#'],
  // Row 5
  ['#','#','#','#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#','#'],
  // Row 6
  ['#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#','#'],
  // Row 7
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 8
  ['#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#'],
  // Row 9
  ['#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#'],
  // Row 10
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 11
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 12
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','#','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 13
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 14
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 15
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 16
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 17
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 18
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','#','.','#','#','#','#'],
  // Row 19
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
];

// Apply building footprints to walkable map.
// GATES ARE SKIPPED: their collision is runtime-dependent (closed blocks,
// open is walkable) and handled by src/engine/collision.ts from the save.
function applyBuildingFootprints(walkable: boolean[][], buildings: Building[]): boolean[][] {
  const result = walkable.map(row => [...row]); // Deep copy
  buildings.forEach(b => {
    if (b.sprite.includes('gate')) return; // runtime collision (engine/collision.ts)
    for (let r = b.footprintRow; r < b.footprintRow + b.footprintH; r++) {
      for (let c = b.footprintCol; c < b.footprintCol + b.footprintW; c++) {
        if (r >= 0 && r < result.length && c >= 0 && c < result[0].length) {
          result[r][c] = false; // Blocked
        }
      }
    }
  });
  return result;
}

// Compact World 1: asymmetric placement around branching paths.
const FARM_BUILDINGS: Building[] = [
  { id: 'henhouse', npcId: 'mae', sprite: 'henhouse', footprintCol: 2, footprintRow: 2, footprintW: 3, footprintH: 3 },
  { id: 'stable', npcId: 'chester', sprite: 'stable', footprintCol: 12, footprintRow: 3, footprintW: 3, footprintH: 3 },
  { id: 'barn', npcId: 'farmer-joe', sprite: 'barn', footprintCol: 24, footprintRow: 2, footprintW: 3, footprintH: 3 },
  { id: 'coop', npcId: 'lily', sprite: 'coop', footprintCol: 4, footprintRow: 11, footprintW: 3, footprintH: 3 },
  { id: 'clinic', npcId: 'vera', sprite: 'animal-clinic', footprintCol: 18, footprintRow: 9, footprintW: 3, footprintH: 2 },
  { id: 'garden', npcId: 'grandma-rose', sprite: 'garden', footprintCol: 25, footprintRow: 13, footprintW: 2, footprintH: 2 },
  { id: 'farm-gate', sprite: 'farm-gate', footprintCol: 14, footprintRow: 22, footprintW: 3, footprintH: 2 },
];

export const WORLD_1_FARM: WorldMap = {
  id: 1,
  name: 'Farm',
  cols: 32,
  rows: 24,
  collisionMap: WORLD1_WALKABLE.map(row => row.map(open => open ? '.' : '#')),
  walkableMap: applyBuildingFootprints(WORLD1_WALKABLE, FARM_BUILDINGS),
  spawn: { x: 15, y: 8 },
  exits: [{ x: 15, y: 23, toWorld: 2 }],
  eventPoints: [
    { id: 'ep_mae_1', npcId: 'mae', x: 5, y: 5 },
    { id: 'ep_chester_1', npcId: 'chester', x: 11, y: 6 },
    { id: 'ep_joe_1', npcId: 'farmer-joe', x: 27, y: 5 },
    { id: 'ep_vera_1', npcId: 'vera', x: 21, y: 12 },
    { id: 'ep_lily_1', npcId: 'lily', x: 8, y: 15 },
    { id: 'ep_rose_1', npcId: 'grandma-rose', x: 27, y: 17 },
    { id: 'ep_billy_1', npcId: 'billy', x: 13, y: 19 },
  ],
  buildings: FARM_BUILDINGS,
};

// World 2 - Downtown (30×20)
const downtownCollisionMap: Tile[][] = [
  // Row 0
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 1
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.'],
  // Row 2 (bakery at 3,2; hardware at 13,2; town-hall at 22,2 4×2)
  ['#','.','.','#','#','.','.','.','.','.','.','.','.','.','#','#','.','.','.','.','.','.','.','#','#','#','#','.','.','.'],
  // Row 3 (event points at 5,3; 12,3; 21,3)
  ['#','.','.','#','#','E','.','.','.','.','.','.','E','.','.','#','.','.','.','.','.','E','.','.','#','#','#','#','.','#'],
  // Row 4
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 5
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 6
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 7
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 8 (post-office at 3,8; library at 13,8)
  ['#','.','.','#','#','.','.','.','.','.','.','.','.','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 9 (event points at 5,9; 15,9 + spawn at 13,9)
  ['#','.','.','#','#','E','.','.','.','.','.','.','.','.','S','E','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 10
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 11
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 12
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 13 (park at 6,13; fountain at 14,13)
  ['#','.','.','.','.','.','.','.','#','#','.','.','.','.','.','#','#','.','.','.','.','.','.','.','.','.','.','.','.','.'],
  // Row 14 (event points at 13,13; 7,14)
  ['#','.','.','.','.','.','.','.','E','#','.','.','.','E','.','.','#','.','.','.','.','.','.','.','.','.','.','.','.','.'],
  // Row 15
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 16
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 17
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 18
  ['#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 19 (town gate exit at 14,19)
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','X','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
];

// World 2 buildings - using detected clearings from HERMES-pixel-perfect-placement.md §5
const DOWNTOWN_BUILDINGS: Building[] = [
  // Sidewalk section (rows 0-13)
  { id: 'bakery', npcId: 'sam', sprite: 'bakery', footprintCol: 2, footprintRow: 1, footprintW: 3, footprintH: 2 },
  { id: 'hardware', npcId: 'rosa', sprite: 'hardware', footprintCol: 10, footprintRow: 1, footprintW: 3, footprintH: 2 },
  { id: 'town-hall', npcId: 'mayor-chen', sprite: 'town-hall', footprintCol: 16, footprintRow: 1, footprintW: 7, footprintH: 2 }, // 4×2 wide pad
  { id: 'post-office', npcId: 'tommy', sprite: 'post-office', footprintCol: 2, footprintRow: 9, footprintW: 3, footprintH: 2 },
  { id: 'library', npcId: 'ms-park', sprite: 'library', footprintCol: 10, footprintRow: 9, footprintW: 3, footprintH: 2 },
  { id: 'park', npcId: 'danny', sprite: 'park', footprintCol: 16, footprintRow: 9, footprintW: 3, footprintH: 2 },
  // Park section
  { id: 'fountain', sprite: 'fountain', footprintCol: 12, footprintRow: 19, footprintW: 5, footprintH: 6 }, // Circular fountain area
  // Town Gate (world exit) — runtime collision like farm-gate.
  { id: 'town-gate', sprite: 'town-gate', footprintCol: 14, footprintRow: 28, footprintW: 3, footprintH: 2 },
];

export const WORLD_2_DOWNTOWN: WorldMap = {
  id: 2,
  name: 'Downtown',
  cols: 40,
  rows: 30,
  collisionMap: downtownCollisionMap, // Legacy - kept for compatibility
  walkableMap: applyBuildingFootprints(WORLD2_WALKABLE, DOWNTOWN_BUILDINGS),
  spawn: { x: 16, y: 1 }, // Top center (arrives from Farm)
  exits: [{ x: 16, y: 29, toWorld: 1 }], // Bottom center (returns to Farm)
  eventPoints: [
    // Sidewalk NPCs
    { id: 'ep_sam_1', npcId: 'sam', x: 3, y: 3 }, // Near bakery
    { id: 'ep_rosa_1', npcId: 'rosa', x: 11, y: 3 }, // Near hardware
    { id: 'ep_chen_1', npcId: 'mayor-chen', x: 19, y: 3 }, // Near town hall
    { id: 'ep_tommy_1', npcId: 'tommy', x: 3, y: 11 }, // Near post office
    { id: 'ep_park_1', npcId: 'ms-park', x: 11, y: 11 }, // Near library
    { id: 'ep_danny_1', npcId: 'danny', x: 17, y: 11 }, // Near park marker
    // Park NPCs
    { id: 'ep_carlos_1', npcId: 'carlos', x: 14, y: 22 }, // Near fountain
    { id: 'ep_pat_1', npcId: 'officer-pat', x: 14, y: 28 }, // Bottom exit path
  ],
  buildings: DOWNTOWN_BUILDINGS,
};

export const WORLDS = [WORLD_1_FARM, WORLD_2_DOWNTOWN];
