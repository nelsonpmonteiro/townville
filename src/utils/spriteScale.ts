// Sprite scaling system - proportional rendering based on category
// Per HERMES-worldscale-implementation.md §3.2-3.4

const TILE_SIZE = 48;

// Target heights in tiles for each sprite category
export const TARGET_HEIGHT_TILES: Record<string, number> = {
  protagonist: 1.4,
  npcMap: 1.4,
  buildingStandard: 2.6,
  buildingWide: 2.6,
  gate: 2.2,
  tree: 2.3,
  bush: 0.65,
  flower: 0.4,
  rock: 0.35,
  well: 1.3,
  lamppost: 1.7,
  furniture: 0.6,
  fountain: 2.0,
};

/**
 * Compute render size for a sprite based on its category.
 * Maintains aspect ratio, scales to target height in tiles.
 * @param nativeW - Width of trimmed PNG (after trim_sprites.py)
 * @param nativeH - Height of trimmed PNG
 * @param category - Sprite category from TARGET_HEIGHT_TILES
 */
export function computeRenderSize(
  nativeW: number,
  nativeH: number,
  category: string
): { width: number; height: number } {
  const targetH = (TARGET_HEIGHT_TILES[category] || 1.0) * TILE_SIZE;
  const scale = targetH / nativeH;
  return {
    width: Math.round(nativeW * scale),
    height: Math.round(targetH),
  };
}

/**
 * Get sprite position anchored at bottom-center of footprint.
 * @param footprintCol - Footprint column (in tiles)
 * @param footprintRow - Footprint row (in tiles)
 * @param footprintColsW - Footprint width (in tiles)
 * @param footprintRowsH - Footprint height (in tiles)
 * @param renderW - Rendered sprite width (px, from computeRenderSize)
 * @param renderH - Rendered sprite height (px, from computeRenderSize)
 */
export function getSpritePosition(
  footprintCol: number,
  footprintRow: number,
  footprintColsW: number,
  footprintRowsH: number,
  renderW: number,
  renderH: number
): { x: number; y: number } {
  const footprintPxW = footprintColsW * TILE_SIZE;
  const footprintPxH = footprintRowsH * TILE_SIZE;
  
  // Horizontally centered on footprint, vertically anchored at base
  const x = footprintCol * TILE_SIZE + (footprintPxW - renderW) / 2;
  const y = footprintRow * TILE_SIZE + footprintPxH - renderH;
  
  return { x, y };
}
