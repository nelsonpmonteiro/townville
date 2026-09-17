// Compact 32×24 World 1 path network.
// This matrix is the single source for collision AND rendered dirt paths.
const COLS = 32;
const ROWS = 24;
const map: boolean[][] = Array.from({ length: ROWS }, () => Array(COLS).fill(false));

function open(x: number, y: number) {
  if (x >= 0 && x < COLS && y >= 0 && y < ROWS) map[y][x] = true;
}

/** Carve an orthogonal route. Width 2 keeps the game readable without plazas. */
function route(points: Array<[number, number]>, width = 2) {
  for (let i = 1; i < points.length; i++) {
    let [x, y] = points[i - 1];
    const [tx, ty] = points[i];
    const dx = Math.sign(tx - x), dy = Math.sign(ty - y);
    while (true) {
      for (let oy = 0; oy < width; oy++) for (let ox = 0; ox < width; ox++) open(x + ox, y + oy);
      if (x === tx && y === ty) break;
      x += dx; y += dy;
    }
  }
}

route([[14, 7], [14, 23]]);                       // main route to gate
route([[14, 8], [9, 8], [9, 5], [5, 5]]);        // Mae
route([[14, 8], [11, 8], [11, 6]]);              // Chester
route([[15, 8], [20, 8], [20, 5], [27, 5]]);     // Farmer Joe
route([[15, 10], [21, 10], [21, 12]]);           // Vera
route([[14, 12], [10, 12], [10, 15], [8, 15]]);  // Lily
route([[21, 12], [24, 12], [24, 17], [27, 17]]); // Grandma Rose
route([[14, 16], [12, 16], [12, 19], [13, 19]]); // Billy
route([[14, 19], [17, 19]]);                      // Old Mac

// Lower fence opening and gate corridor.
for (let x = 13; x <= 17; x++) open(x, 20);
for (let y = 21; y <= 23; y++) { open(14, y); open(15, y); open(16, y); }

export const WORLD1_WALKABLE: boolean[][] = map;
