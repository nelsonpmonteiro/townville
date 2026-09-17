extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 32
const ROWS := 24
const SPAWN := Vector2i(15, 8)

var id: String = "world1"

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

	# Solid decorative props block movement (fountain, well, tree, stone, bench, mailbox, gate, fence)
	const SOLID_PROP_IDS := ["fountain", "well", "tree", "stone", "bench", "mailbox", "farm-gate", "fence-left", "fence-right"]
	for prop in WORLD1_PROPS:
		if prop.id in SOLID_PROP_IDS:
			var pt: Vector2i = prop.get("tile", Vector2i(-1, -1))
			if _in_bounds(pt):
				walkable[pt.y][pt.x] = false

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

# --- Prop definitions per world ---

const WORLD1_PROPS := [
	{"id": "bench", "display_name": "Banco", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(2, 9)},
	{"id": "flower-pot", "display_name": "Vaso", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(8, 4)},
	{"id": "fountain", "display_name": "Fonte", "sprite_path": "res://assets/scenery/world1/scenery-fountain.png", "tile": Vector2i(16, 10)},
	{"id": "lamppost", "display_name": "Poste", "sprite_path": "res://assets/scenery/world1/scenery-lamppost.png", "tile": Vector2i(17, 5)},
	{"id": "mailbox", "display_name": "Caixa de Correio", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(29, 5)},
	{"id": "bush", "display_name": "Arbusto", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(3, 18)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(10, 17)},
	{"id": "flower-yellow", "display_name": "Flor Amarela", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(19, 17)},
	{"id": "stone", "display_name": "Pedra", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(30, 10)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(30, 20)},
	{"id": "well", "display_name": "Poço", "sprite_path": "res://assets/scenery/world1/scenery-well.png", "tile": Vector2i(8, 10)},
	{"id": "farm-gate", "display_name": "Portão", "sprite_path": "res://assets/buildings/world1/building-farm-gate-open.png", "tile": Vector2i(15, 23)},
	{"id": "fence-left", "display_name": "Cerca", "sprite_path": "res://assets/buildings/world1/building-fence.png", "tile": Vector2i(12, 19)},
	{"id": "fence-right", "display_name": "Cerca", "sprite_path": "res://assets/buildings/world1/building-fence.png", "tile": Vector2i(16, 19)}
]

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
		"world1": return WORLD1_PROPS
		"world2": return WORLD2_PROPS
		_: return WORLD1_PROPS
