extends RefCounted
class_name WangTiler

## Wang tile selection based on 4-corner neighbor analysis.
## Convention: "upper" = grass (no edge), "lower" = dirt/water (edge present)
## Binary encoding: bit 0 (1) = SE lower, bit 1 (2) = SW lower,
##                  bit 2 (4) = NE lower, bit 3 (8) = NW lower

## Return the Wang tile ID for corner configuration [NW, NE, SW, SE]
func get_wang_id(corners: Array) -> int:
	var nw = 8 if corners[0] == "lower" else 0
	var ne = 4 if corners[1] == "lower" else 0
	var sw = 2 if corners[2] == "lower" else 0
	var se = 1 if corners[3] == "lower" else 0
	return nw + ne + sw + se

## Analyze a 3x3 neighbourhood around (cx, cy) in a flat grid
## grid is Dictionary<int, String> keyed by (y * stride + x)
## terrain values: "grass", "dirt", "water"
## Returns a Wang tile ID for the center cell.
func analyze_neighbors(grid: Dictionary, cx: int, cy: int, stride: int) -> int:
	var nw := _terrain_corner(grid, cx - 1, cy - 1, stride)
	var ne := _terrain_corner(grid, cx + 1, cy - 1, stride)
	var sw := _terrain_corner(grid, cx - 1, cy + 1, stride)
	var se := _terrain_corner(grid, cx + 1, cy + 1, stride)
	return get_wang_id([nw, ne, sw, se])

## Determine corner orientation: if the neighbour terrain differs from center,
## we pick "upper" for the dominant (grass) and "lower" for the recessive (dirt/water).
## Simplified: just return the neighbour's terrain classification.
func _terrain_corner(grid: Dictionary, x: int, y: int, stride: int) -> String:
	var key = y * stride + x
	var terrain = grid.get(key, "grass")
	if terrain == "dirt" or terrain == "water":
		return "lower"
	else:
		return "upper"
