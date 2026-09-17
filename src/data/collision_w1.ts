// Compact 32×24 World 1 collision layout.
// True means walkable. Paths intentionally branch asymmetrically so NPCs
// form a village-like route instead of two uniform rows.
const COLS = 32;
const ROWS = 24;

function buildCompactFarmWalkable(): boolean[][] {
  const map = Array.from({ length: ROWS }, () => Array(COLS).fill(false));
  const paint = (x0: number, y0: number, x1: number, y1: number) => {
    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) map[y][x] = true;
    }
  };

  // Main lane and staggered approaches to the upper buildings.
  paint(3, 7, 28, 8);
  paint(5, 5, 6, 7);      // Mae
  paint(10, 6, 12, 7);    // Chester
  paint(26, 5, 27, 7);    // Farmer Joe

  // Central spine with irregular east/west branches.
  paint(14, 7, 16, 23);
  paint(7, 14, 15, 15);   // Lily
  paint(7, 15, 8, 16);
  paint(15, 11, 20, 12);  // Vera
  paint(20, 12, 21, 13);
  paint(15, 17, 27, 18);  // Grandma Rose
  paint(26, 16, 27, 17);
  paint(12, 19, 17, 20);  // Billy / fence approach

  // Gate corridor remains statically open; runtime gate state blocks it.
  paint(14, 21, 16, 23);
  return map;
}

export const WORLD1_WALKABLE: boolean[][] = buildCompactFarmWalkable();
