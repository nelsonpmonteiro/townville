// World map data for Townville MVP
// 30 cols × 20 rows per world
// Based on HERMES-rendering-spec.md

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
  collisionMap: Tile[][];
  spawn: { x: number; y: number };
  exits: Array<{ x: number; y: number; toWorld: number }>;
  eventPoints: EventPoint[];
  buildings: Building[];
}

// World 1 - Farm (30×20)
// Legend: . = walkable, # = blocked
// Pixel-sampled + manual overrides for gameplay
const farmCollisionMap: Tile[][] = [
  // Row 0
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 1
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 2 (henhouse footprint 3-4,2-3; stable 13-14,2-3; barn 23-24,2-3)
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 3 (event points at 5,3 12,3 22,3)
  ['#','#','#','#','#','.','#','#','#','#','#','#','.','.','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 4
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 5
  ['#','#','#','#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#','#','#','#'],
  // Row 6
  ['#','#','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','#'],
  // Row 7
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','.','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 8 (coop footprint 3-4,8-9; clinic 13-14,8-9; garden 23-24,8-9)
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
  // Row 9 (event points at 5,9 15,9 22,9 + spawn 14,9)
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 10
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','#','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 11
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 12 (billy at 14,12)
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 13
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 14
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 15
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 16
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 17
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','.','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 18
  ['#','#','#','#','#','.','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','.','#','#','#','#','#','#','#'],
  // Row 19 (exit at 15,19)
  ['#','#','#','#','#','#','#','#','#','#','#','#','#','#','.','.','#','#','#','#','#','#','#','#','#','#','#','#','#','#'],
];

export const WORLD_1_FARM: WorldMap = {
  id: 1,
  name: 'Farm',
  collisionMap: farmCollisionMap,
  spawn: { x: 14, y: 9 },
  exits: [{ x: 15, y: 19, toWorld: 2 }],
  eventPoints: [
    { id: 'ep_mae_1', npcId: 'mae', x: 5, y: 3 },
    { id: 'ep_chester_1', npcId: 'chester', x: 12, y: 3 },
    { id: 'ep_lily_1', npcId: 'lily', x: 22, y: 3 },
    { id: 'ep_joe_1', npcId: 'farmer-joe', x: 5, y: 9 },
    { id: 'ep_vera_1', npcId: 'vera', x: 15, y: 9 },
    { id: 'ep_rose_1', npcId: 'grandma-rose', x: 22, y: 9 },
    { id: 'ep_billy_1', npcId: 'billy', x: 15, y: 12 },
  ],
  buildings: [
    // Top row - henhouse, stable, barn
    { id: 'henhouse', npcId: 'mae', sprite: 'henhouse', footprintCol: 3, footprintRow: 2, footprintW: 2, footprintH: 2 },
    { id: 'stable', npcId: 'chester', sprite: 'stable', footprintCol: 13, footprintRow: 2, footprintW: 2, footprintH: 2 },
    { id: 'barn', npcId: 'farmer-joe', sprite: 'barn', footprintCol: 23, footprintRow: 2, footprintW: 2, footprintH: 2 },
    // Middle row - coop, clinic, garden
    { id: 'coop', npcId: 'lily', sprite: 'coop', footprintCol: 3, footprintRow: 8, footprintW: 2, footprintH: 2 },
    { id: 'clinic', npcId: 'vera', sprite: 'clinic', footprintCol: 13, footprintRow: 8, footprintW: 2, footprintH: 2 },
    { id: 'garden', npcId: 'grandma-rose', sprite: 'garden', footprintCol: 23, footprintRow: 8, footprintW: 2, footprintH: 2 },
  ],
    { id: 'animal-clinic', npcId: 'vera', sprite: 'animal-clinic', footprintCol: 13, footprintRow: 8, footprintW: 2, footprintH: 2 },
    { id: 'garden', npcId: 'grandma-rose', sprite: 'garden', footprintCol: 23, footprintRow: 8, footprintW: 2, footprintH: 2 },
    { id: 'farm-gate', npcId: 'old-mac', sprite: 'farm-gate', footprintCol: 14, footprintRow: 19, footprintW: 3, footprintH: 1 },
  ],
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

export const WORLD_2_DOWNTOWN: WorldMap = {
  id: 2,
  name: 'Downtown',
  collisionMap: downtownCollisionMap,
  spawn: { x: 13, y: 9 },
  exits: [{ x: 15, y: 19, toWorld: 1 }],
  eventPoints: [
    { id: 'ep_sam_1', npcId: 'sam', x: 5, y: 3 },
    { id: 'ep_rosa_1', npcId: 'rosa', x: 12, y: 3 },
    { id: 'ep_chen_1', npcId: 'mayor-chen', x: 21, y: 3 },
    { id: 'ep_tommy_1', npcId: 'tommy', x: 5, y: 9 },
    { id: 'ep_park_1', npcId: 'ms-park', x: 15, y: 9 },
    { id: 'ep_danny_1', npcId: 'danny', x: 13, y: 13 },
    { id: 'ep_carlos_1', npcId: 'carlos', x: 7, y: 14 },
  ],
  buildings: [
    // World 2 buildings - sprites available in batch2
    { id: 'bakery', npcId: 'sam', sprite: 'bakery', footprintCol: 3, footprintRow: 2, footprintW: 2, footprintH: 2 },
    { id: 'hardware', npcId: 'rosa', sprite: 'hardware', footprintCol: 13, footprintRow: 2, footprintW: 2, footprintH: 2 },
    { id: 'town-hall', npcId: 'mayor-chen', sprite: 'town-hall', footprintCol: 22, footprintRow: 2, footprintW: 4, footprintH: 2 },
    { id: 'post-office', npcId: 'tommy', sprite: 'post-office', footprintCol: 3, footprintRow: 8, footprintW: 2, footprintH: 2 },
    { id: 'library', npcId: 'ms-park', sprite: 'library', footprintCol: 13, footprintRow: 8, footprintW: 2, footprintH: 2 },
    { id: 'fountain', npcId: 'danny', sprite: 'fountain', footprintCol: 14, footprintRow: 13, footprintW: 2, footprintH: 2 },
    { id: 'park', npcId: 'carlos', sprite: 'park', footprintCol: 6, footprintRow: 13, footprintW: 2, footprintH: 2 },
    { id: 'town-gate', npcId: 'officer-pat', sprite: 'town-gate', footprintCol: 14, footprintRow: 19, footprintW: 3, footprintH: 1 },
  ],
};

export const WORLDS = [WORLD_1_FARM, WORLD_2_DOWNTOWN];
