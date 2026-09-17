extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 32
const ROWS := 24
const SPAWN := Vector2i(15, 8)

# All 8 World 1 NPCs with PixelLab idle sprites
const NPCS := [
	{
		"id": "mae",
		"display_name": "Mae",
		"sprite_path": "res://assets/characters/world1/mae-idle.png",
		"tile": Vector2i(6, 6),
		"dialogue": "Mae: Os ovos estão prontos! Quer ajudar a contar?"
	},
	{
		"id": "chester",
		"display_name": "Chester",
		"sprite_path": "res://assets/characters/world1/chester-idle.png",
		"tile": Vector2i(11, 7),
		"dialogue": "Chester: Neigh! Estábulos limpos e quentinhos."
	},
	{
		"id": "farmer-joe",
		"display_name": "Fazendeiro Joe",
		"sprite_path": "res://assets/characters/world1/farmer-joe-idle.png",
		"tile": Vector2i(26, 6),
		"dialogue": "Joe: O celeiro precisa de reparos. Madeira?"
	},
	{
		"id": "vera",
		"display_name": "Dra. Vera",
		"sprite_path": "res://assets/characters/world1/vera-idle.png",
		"tile": Vector2i(21, 12),
		"dialogue": "Dra. Vera: A clínica cuida dos animais da fazenda!"
	},
	{
		"id": "lily",
		"display_name": "Lily",
		"sprite_path": "res://assets/characters/world1/lily-idle.png",
		"tile": Vector2i(5, 14),
		"dialogue": "Lily: As galinhas botaram muito hoje!"
	},
	{
		"id": "grandma-rose",
		"display_name": "Vovó Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(25, 17),
		"dialogue": "Rose: As flores do jardim estão lindas."
	},
	{
		"id": "billy",
		"display_name": "Billy",
		"sprite_path": "res://assets/characters/world1/billy-idle.png",
		"tile": Vector2i(14, 19),
		"dialogue": "Billy: A cerca está firme. Ninguém passa!"
	},
	{
		"id": "old-mac",
		"display_name": "Old Mac",
		"sprite_path": "res://assets/characters/world1/old-mac-idle.png",
		"tile": Vector2i(9, 21),
		"dialogue": "Old Mac: O portão da fazenda é seguro."
	}
]

# Building footprints and sprites
const BUILDINGS := [
	{"id": "henhouse", "sprite": "res://assets/buildings/world1/building-henhouse.png", "footprintCol": 2, "footprintRow": 2, "footprintW": 3, "footprintH": 3, "label": "GALINHEIRO"},
	{"id": "stable", "sprite": "res://assets/buildings/world1/building-stable.png", "footprintCol": 12, "footprintRow": 3, "footprintW": 3, "footprintH": 3, "label": "ESTÁBULO"},
	{"id": "barn", "sprite": "res://assets/buildings/world1/building-barn.png", "footprintCol": 24, "footprintRow": 2, "footprintW": 4, "footprintH": 3, "label": "CELEIRO"},
	{"id": "coop", "sprite": "res://assets/buildings/world1/building-coop.png", "footprintCol": 4, "footprintRow": 11, "footprintW": 3, "footprintH": 3, "label": "GALINHEIRO 2"},
	{"id": "clinic", "sprite": "res://assets/buildings/world1/building-animal-clinic.png", "footprintCol": 18, "footprintRow": 9, "footprintW": 3, "footprintH": 2, "label": "CLÍNICA"},
	{"id": "garden", "sprite": "res://assets/buildings/world1/building-garden.png", "footprintCol": 25, "footprintRow": 13, "footprintW": 2, "footprintH": 2, "label": "JARDIM"}
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

	# Main horizontal through the farm
	_paint_walkable(Rect2i(4, 7, 24, 2))
	# Building approach paths
	_paint_walkable(Rect2i(5, 5, 3, 4))
	_paint_walkable(Rect2i(11, 6, 3, 3))
	_paint_walkable(Rect2i(25, 5, 3, 4))
	# Central vertical spine
	_paint_walkable(Rect2i(14, 7, 3, 16))
	# Lower areas
	_paint_walkable(Rect2i(6, 14, 10, 2))
	_paint_walkable(Rect2i(15, 12, 5, 2))
	_paint_walkable(Rect2i(19, 12, 4, 2))
	_paint_walkable(Rect2i(25, 16, 3, 2))
	_paint_walkable(Rect2i(8, 19, 8, 2))
	_paint_walkable(Rect2i(14, 21, 3, 3))

	# NPC tiles are solid
	for npc in NPCS:
		var t: Vector2i = npc.tile
		if _in_bounds(t):
			walkable[t.y][t.x] = false

	# Building footprints block movement
	for b in BUILDINGS:
		for r in range(b.footprintRow, b.footprintRow + b.footprintH):
			for c in range(b.footprintCol, b.footprintCol + b.footprintW):
				if _in_bounds(Vector2i(c, r)):
					walkable[r][c] = false

func _paint_walkable(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
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
