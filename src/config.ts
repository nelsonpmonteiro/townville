// ============================================================
// GAME CONFIG — single source of truth for all game constants.
// NEVER redefine these values in components. Import from here.
// Changing grid/tile values here propagates to the whole game.
// ============================================================

export const TILE_SIZE = 48;

export const GRID_COLS = 40;
export const GRID_ROWS = 30;

export const MAP_WIDTH = GRID_COLS * TILE_SIZE; // 1920
export const MAP_HEIGHT = GRID_ROWS * TILE_SIZE; // 1440

// Movement
export const MOVEMENT_DURATION_MS = 200; // tile-to-tile animation
export const MOVE_THROTTLE_MS = 140; // min interval between moves

// Session rules
export const MAX_LIVES = 3;
export const ERRORS_PER_LIFE = 3; // lose 1 life every N errors on a point
export const SESSION_QUEST_TARGET = 5; // quests per session
export const SCORE_PER_QUEST = 100;
export const DEFAULT_MAX_ATTEMPTS = 3;

// Persistence
export const SAVE_KEY = 'townville.save.v1';

// Rendering
export const CHUNK_SIZE = 480; // rendered chunk size (native files are 512)
export const PROTAGONIST_TARGET_HEIGHT = 56;
