extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 30
const ROWS := 20
const SPAWN := Vector2i(15, 6)

var id: String = "world1"

# 6 World 1 NPCs — layout follows the latest user-provided spec (30x20 grid,
# exact standing tiles), sprites unchanged (current PixelLab pixel art).
# Billy and Old Mac intentionally excluded — out of scope for this delivery.
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
		"tile": Vector2i(4, 7),
		"dialogue": "Lily: As galinhas botaram muito hoje!"
	},
	{
		"id": "vera",
		"display_name": "Dra. Vera",
		"sprite_path": "res://assets/characters/world1/vera-idle.png",
		"tile": Vector2i(24, 7),
		"dialogue": "Dra. Vera: A clínica cuida dos animais da fazenda!"
	},
	{
		"id": "grandma-rose",
		"display_name": "Vovó Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(25, 14),
		"dialogue": "Rose: As flores do jardim estão lindas."
	}
]

# Building footprints — layout from the latest user spec (30x20 grid, exact
# col/row per building). Sprites unchanged (current PixelLab pixel art).
const BUILDINGS := [
	{"id": "henhouse", "sprite": "res://assets/buildings/world1/building-henhouse.png", "footprintCol": 3, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "GALINHEIRO", "scale": 1.0, "flip_h": true},
	{"id": "stable", "sprite": "res://assets/buildings/world1/building-stable.png", "footprintCol": 13, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "ESTÁBULO", "scale": 1.5, "flip_h": false},
	{"id": "barn", "sprite": "res://assets/buildings/world1/building-barn.png", "footprintCol": 23, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "CELEIRO", "scale": 2.0, "flip_h": false},
	{"id": "coop", "sprite": "res://assets/buildings/world1/building-coop.png", "footprintCol": 3, "footprintRow": 8, "footprintW": 2, "footprintH": 2, "label": "GALINHEIRO 2", "scale": 1.0, "flip_h": true},
	{"id": "clinic", "sprite": "res://assets/buildings/world1/building-animal-clinic.png", "footprintCol": 23, "footprintRow": 8, "footprintW": 2, "footprintH": 2, "label": "CLÍNICA", "scale": 2.0, "flip_h": false},
	{"id": "garden", "sprite": "res://assets/buildings/world1/building-garden.png", "footprintCol": 26, "footprintRow": 14, "footprintW": 2, "footprintH": 2, "label": "JARDIM", "scale": 1.0, "flip_h": false}
]

var walkable: Array[Array] = []
var path_mask: Array[Array] = []

func _init() -> void:
	_build_walkable_matrix()

func _build_walkable_matrix() -> void:
	walkable.clear()
	path_mask.clear()
	for y in ROWS:
		var row: Array[bool] = []
		row.resize(COLS)
		row.fill(false)
		walkable.append(row)
		var prow: Array[bool] = []
		prow.resize(COLS)
		prow.fill(false)
		path_mask.append(prow)

	# Path network per the latest user spec: horizontal spine + branch
	# clearings + central vertical trunk + garden connector.
	_paint_walkable(Rect2i(1, 5, 28, 1))
	_paint_walkable(Rect2i(3, 2, 2, 3))
	_paint_walkable(Rect2i(13, 2, 2, 3))
	_paint_walkable(Rect2i(23, 2, 2, 3))
	_paint_walkable(Rect2i(15, 6, 2, 14))
	_paint_walkable(Rect2i(3, 6, 2, 4))
	_paint_walkable(Rect2i(23, 6, 2, 4))
	_paint_walkable(Rect2i(16, 14, 11, 2))

	# Visual path mask mirrors the walkable network before entities carve holes in it,
	# so buildings/props/NPCs still stand on dirt instead of leaving a grass gap.
	for y in ROWS:
		for x in COLS:
			path_mask[y][x] = walkable[y][x]

	# NPC tiles are solid but stand on the path visually
	for npc in NPCS:
		var t: Vector2i = npc.tile
		if _in_bounds(t):
			walkable[t.y][t.x] = false
			path_mask[t.y][t.x] = true

	# Building footprints block movement; their footprint reads as packed dirt/yard
	for b in BUILDINGS:
		for r in range(b.footprintRow, b.footprintRow + b.footprintH):
			for c in range(b.footprintCol, b.footprintCol + b.footprintW):
				if _in_bounds(Vector2i(c, r)):
					walkable[r][c] = false
					path_mask[r][c] = true

	# Solid decorative props block movement (fountain, well, tree, stone, bench, mailbox, gate, fence)
	const SOLID_PROP_IDS := ["fountain", "well", "tree", "stone", "bench", "mailbox", "farm-gate", "fence-left", "fence-right"]
	# Only wayside props (not trees/stones planted in open grass) mark the ground as path
	const PATHSIDE_PROP_IDS := ["fountain", "well", "bench", "mailbox", "farm-gate", "fence-left", "fence-right"]
	for prop in WORLD1_PROPS:
		var pt: Vector2i = prop.get("tile", Vector2i(-1, -1))
		if prop.id in SOLID_PROP_IDS and _in_bounds(pt):
			walkable[pt.y][pt.x] = false
		if prop.id in PATHSIDE_PROP_IDS and _in_bounds(pt):
			path_mask[pt.y][pt.x] = true

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

# World1 decorative props — repositioned for the new 30x20 layout, every
# tile within Chebyshev distance<=1 of the path network or a building
# footprint (the validated placement rule), clustered near the POI it
# belongs to. Sprites unchanged (current PixelLab pixel art).
const WORLD1_PROPS := [
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(7, 4)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(20, 6)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(28, 6)},
	# Henhouse (Mae) cluster
	{"id": "flower-pot", "display_name": "Vaso", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(5, 4)},
	{"id": "bush", "display_name": "Arbusto", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(5, 5)},
	# Stable (Chester) cluster
	{"id": "lamppost", "display_name": "Poste", "sprite_path": "res://assets/scenery/world1/scenery-lamppost.png", "tile": Vector2i(17, 4)},
	{"id": "stone", "display_name": "Pedra", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(17, 5)},
	# Barn (Joe) cluster
	{"id": "mailbox", "display_name": "Caixa de Correio", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(25, 4)},
	{"id": "flower-yellow", "display_name": "Flor Amarela", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(26, 4)},
	# Coop (Lily) cluster
	{"id": "well", "display_name": "Poço", "sprite_path": "res://assets/scenery/world1/scenery-well.png", "tile": Vector2i(3, 5)},
	{"id": "bench", "display_name": "Banco", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(5, 6)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(5, 7)},
	# Clinic (Vera) cluster
	{"id": "fountain", "display_name": "Fonte", "sprite_path": "res://assets/scenery/world1/scenery-fountain.png", "tile": Vector2i(22, 7)},
	{"id": "flower-pot", "display_name": "Vaso", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(25, 6)},
	# Garden (Rose) cluster
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(24, 14)},
	{"id": "flower-yellow", "display_name": "Flor Amarela", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(24, 15)},
]

# Fine-detail clutter — repositioned for the new 30x20 layout, each entry
# within Chebyshev distance<=1 of the path network, clustered near the POI
# it belongs to (never scattered in open unreachable grass).
const WORLD1_GRASS_CLUTTER := [
	# Mae / henhouse approach
	{"id": "wildflower-white", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-white.png", "tile": Vector2i(3, 4), "scale": 0.9},
	{"id": "grass-tuft-a", "sprite_path": "res://assets/scenery/world1/clutter/grass-tuft-a.png", "tile": Vector2i(8, 4), "scale": 1.0},
	# Chester / stable approach
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(16, 4), "scale": 0.9},
	{"id": "mushroom-cluster", "sprite_path": "res://assets/scenery/world1/clutter/mushroom-cluster.png", "tile": Vector2i(19, 4), "scale": 1.0},
	# Joe / barn approach
	{"id": "grass-tuft-b", "sprite_path": "res://assets/scenery/world1/clutter/grass-tuft-b.png", "tile": Vector2i(28, 5), "scale": 1.0},
	# Lily / coop approach
	{"id": "wildflower-white", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-white.png", "tile": Vector2i(3, 7), "scale": 0.9},
	# Vera / clinic approach
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(22, 6), "scale": 0.9},
	{"id": "mushroom-cluster", "sprite_path": "res://assets/scenery/world1/clutter/mushroom-cluster.png", "tile": Vector2i(22, 9), "scale": 1.0},
	# Rose / garden approach
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(25, 15), "scale": 0.9},
]

# Farmyard clutter: hay bales, crates, barrel, signpost clustered near the
# buildings/paths they belong to. Non-blocking, same distance rule.
const WORLD1_FARM_CLUTTER := [
	# Chester / stable
	{"id": "hay-bale", "sprite_path": "res://assets/scenery/world1/clutter/hay-bale.png", "tile": Vector2i(18, 4), "scale": 1.1},
	# Joe / barn
	{"id": "wood-crate", "sprite_path": "res://assets/scenery/world1/clutter/wood-crate.png", "tile": Vector2i(27, 4), "scale": 1.0},
	{"id": "barrel", "sprite_path": "res://assets/scenery/world1/clutter/barrel.png", "tile": Vector2i(25, 5), "scale": 1.0},
	# Lily / coop
	{"id": "wood-crate", "sprite_path": "res://assets/scenery/world1/clutter/wood-crate.png", "tile": Vector2i(4, 6), "scale": 1.0},
	# Central crossroads
	{"id": "signpost", "sprite_path": "res://assets/scenery/world1/clutter/signpost.png", "tile": Vector2i(15, 5), "scale": 1.1},
]

# Ground decals painted directly on the path (cart tracks, footprints, puddles)
# — purely flat, rendered just above the tilemap, always sit ON walkable path
# tiles so the player actually walks over them.
const WORLD1_PATH_DECALS := [
	{"id": "cart-tracks", "sprite_path": "res://assets/scenery/world1/clutter/cart-tracks.png", "tile": Vector2i(10, 5)},
	{"id": "footprints", "sprite_path": "res://assets/scenery/world1/clutter/footprints.png", "tile": Vector2i(20, 5)},
	{"id": "mud-puddle", "sprite_path": "res://assets/scenery/world1/clutter/mud-puddle.png", "tile": Vector2i(15, 10)},
]

# Border framing: dense bushes ringing the map edge so the farm reads as
# enclosed by wild vegetation instead of cutting off into flat grass.
const WORLD1_BORDER_CLUTTER := [
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(6, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(11, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(21, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(29, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 19), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(6, 19), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(11, 19), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(21, 19), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(29, 19), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 5), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 11), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 15), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(29, 5), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(29, 11), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(29, 15), "scale": 1.0},
]

const SHADOW_BLOB_SPRITE := "res://assets/scenery/world1/clutter/shadow-blob.png"

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
