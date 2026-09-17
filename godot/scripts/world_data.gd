extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 30
const ROWS := 20
const SPAWN := Vector2i(15, 6)

var id: String = "world1"

# 6 World 1 NPCs, standing tiles per the final verified map spec. Billy and
# Old Mac are intentionally excluded — out of scope for this delivery.
const NPCS := [
	{
		"id": "mae",
		"display_name": "Mae",
		"sprite_path": "res://assets/characters/world1/mae-idle.png",
		"tile": Vector2i(4, 4),
		"dialogue": "Mae: Os ovos estão prontos! Quer ajudar a contar?"
	},
	{
		"id": "chester",
		"display_name": "Chester",
		"sprite_path": "res://assets/characters/world1/chester-idle.png",
		"tile": Vector2i(14, 4),
		"dialogue": "Chester: Neigh! Estábulos limpos e quentinhos."
	},
	{
		"id": "farmer-joe",
		"display_name": "Fazendeiro Joe",
		"sprite_path": "res://assets/characters/world1/farmer-joe-idle.png",
		"tile": Vector2i(24, 4),
		"dialogue": "Joe: O celeiro precisa de reparos. Madeira?"
	},
	{
		"id": "lily",
		"display_name": "Lily",
		"sprite_path": "res://assets/characters/world1/lily-idle.png",
		"tile": Vector2i(4, 8),
		"dialogue": "Lily: As galinhas botaram muito hoje!"
	},
	{
		"id": "vera",
		"display_name": "Dra. Vera",
		"sprite_path": "res://assets/characters/world1/vera-idle.png",
		"tile": Vector2i(24, 8),
		"dialogue": "Dra. Vera: A clínica cuida dos animais da fazenda!"
	},
	{
		"id": "grandma-rose",
		"display_name": "Vovó Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(25, 15),
		"dialogue": "Rose: As flores do jardim estão lindas."
	}
]

# Building footprints, sprite (the exact -locked deliverable), and render
# height in tiles per the final map spec. renderHeightTiles drives scaling:
# scale image so height == renderHeightTiles*48px preserving aspect ratio,
# center horizontally in footprint, bottom-align to footprint's bottom edge.
const BUILDINGS := [
	{"id": "henhouse", "sprite": "res://assets/buildings/world1/building-henhouse-locked.png", "footprintCol": 3, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "renderHeightTiles": 2.0, "label": "GALINHEIRO"},
	{"id": "stable", "sprite": "res://assets/buildings/world1/building-stable-locked.png", "footprintCol": 13, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "renderHeightTiles": 2.6, "label": "ESTÁBULO"},
	{"id": "barn", "sprite": "res://assets/buildings/world1/building-barn-locked.png", "footprintCol": 23, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "renderHeightTiles": 3.2, "label": "CELEIRO"},
	{"id": "coop", "sprite": "res://assets/buildings/world1/building-coop-locked.png", "footprintCol": 3, "footprintRow": 8, "footprintW": 2, "footprintH": 2, "renderHeightTiles": 2.0, "label": "GALINHEIRO 2"},
	{"id": "clinic", "sprite": "res://assets/buildings/world1/building-animal-clinic-locked.png", "footprintCol": 23, "footprintRow": 8, "footprintW": 2, "footprintH": 2, "renderHeightTiles": 2.6, "label": "CLÍNICA"},
	{"id": "garden", "sprite": "res://assets/buildings/world1/building-garden.png", "footprintCol": 26, "footprintRow": 14, "footprintW": 2, "footprintH": 2, "renderHeightTiles": 1.6, "label": "JARDIM"}
]

var walkable: Array[Array] = []

func _init() -> void:
	_build_walkable_matrix()

func _build_walkable_matrix() -> void:
	walkable.clear()
	for y in ROWS:
		var row: Array[bool] = []
		row.resize(COLS)
		row.fill(false)
		walkable.append(row)

	# Base dirt path network, matching the final terrain art pixel-for-pixel
	# (spine + branch clearings + connector patches per the spec).
	_paint_row(5, 1, 28)
	_paint_rect(3, 2, 2, 3)
	_paint_rect(13, 2, 2, 3)
	_paint_rect(23, 2, 2, 3)
	_paint_rect(15, 6, 2, 14)
	_paint_rect(3, 6, 2, 4)
	_paint_rect(23, 6, 2, 4)
	# Garden connector: walkway from trunk (col15) to Garden's door, row 14-15
	_paint_rect(16, 14, 11, 2)

	# Building footprints block movement (collisionRule: footprint tiles -> false)
	for b in BUILDINGS:
		for r in range(b.footprintRow, b.footprintRow + b.footprintH):
			for c in range(b.footprintCol, b.footprintCol + b.footprintW):
				if _in_bounds(Vector2i(c, r)):
					walkable[r][c] = false

	# NPC tiles are solid
	for npc in NPCS:
		var t: Vector2i = npc.tile
		if _in_bounds(t):
			walkable[t.y][t.x] = false

func _paint_rect(x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if _in_bounds(Vector2i(x, y)):
				walkable[y][x] = true

func _paint_row(y: int, x0: int, x1: int) -> void:
	for x in range(x0, x1 + 1):
		if _in_bounds(Vector2i(x, y)):
			walkable[y][x] = true

func _paint_col(x: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		if _in_bounds(Vector2i(x, y)):
			walkable[y][x] = true

func _in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.x < COLS and t.y >= 0 and t.y < ROWS

func world_size_px() -> Vector2i:
	return Vector2i(COLS * TILE_SIZE, ROWS * TILE_SIZE)

func camera_limits() -> Rect2i:
	return Rect2i(Vector2i.ZERO, world_size_px())

func is_walkable(tile: Vector2i) -> bool:
	return _in_bounds(tile) and walkable[tile.y][tile.x]

func get_npc_at(tile: Vector2i) -> Dictionary:
	for npc in NPCS:
		if npc.tile == tile:
			return npc
	return {}

func get_adjacent_npc(tile: Vector2i) -> Dictionary:
	for npc in NPCS:
		var delta: Vector2i = (tile - npc.tile).abs()
		if delta.x + delta.y <= 1 and (delta.x + delta.y) > 0:
			return npc
	return {}

func interaction_text(tile: Vector2i) -> String:
	var npc := get_adjacent_npc(tile)
	return npc.get("dialogue", "") if npc else ""

const TERRAIN_TEXTURE := "res://assets/maps/world1/terrain-final.png"

const WORLD2_PROPS := [
	{"id": "anchor-rusty", "display_name": "Âncora", "sprite_path": "res://assets/scenery/world2/scenery-anchor-rusty.png"},
	{"id": "barrel", "display_name": "Barril", "sprite_path": "res://assets/scenery/world2/scenery-barrel.png"},
	{"id": "crates-stack", "display_name": "Caixotes", "sprite_path": "res://assets/scenery/world2/scenery-crates-stack.png"},
	{"id": "fishing-net", "display_name": "Rede de Pesca", "sprite_path": "res://assets/scenery/world2/scenery-fishing-net.png"},
	{"id": "market-stall", "display_name": "Barraca", "sprite_path": "res://assets/scenery/world2/scenery-market-stall.png"},
	{"id": "seagull", "display_name": "Gaivota", "sprite_path": "res://assets/scenery/world2/scenery-seagull.png"}
]

func get_world_props(world_id: String) -> Array:
	match world_id:
		"world2": return WORLD2_PROPS
		_: return []
