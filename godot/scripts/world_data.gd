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

# All World1 decorative props: every tile below is validated (see art-brief
# validation script) to be within Chebyshev distance <=1 of the walkable path
# network or a building footprint — nothing sits isolated in open grass where
# the player would never pass close enough to see it.
const WORLD1_PROPS := [
	{"id": "bench", "display_name": "Banco", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(3, 9)},
	{"id": "flower-pot", "display_name": "Vaso", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(8, 5)},
	{"id": "fountain", "display_name": "Fonte", "sprite_path": "res://assets/scenery/world1/scenery-fountain.png", "tile": Vector2i(16, 10)},
	{"id": "lamppost", "display_name": "Poste", "sprite_path": "res://assets/scenery/world1/scenery-lamppost.png", "tile": Vector2i(18, 6)},
	{"id": "mailbox", "display_name": "Caixa de Correio", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(28, 5)},
	{"id": "bush", "display_name": "Arbusto", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(7, 18)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(9, 13)},
	{"id": "flower-yellow", "display_name": "Flor Amarela", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(17, 14)},
	{"id": "stone", "display_name": "Pedra", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(28, 9)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(28, 17)},
	{"id": "well", "display_name": "Poço", "sprite_path": "res://assets/scenery/world1/scenery-well.png", "tile": Vector2i(5, 10)},
	{"id": "farm-gate", "display_name": "Portão", "sprite_path": "res://assets/buildings/world1/building-farm-gate-open.png", "tile": Vector2i(15, 23)},
	{"id": "fence-left", "display_name": "Cerca", "sprite_path": "res://assets/buildings/world1/building-fence.png", "tile": Vector2i(12, 19)},
	{"id": "fence-right", "display_name": "Cerca", "sprite_path": "res://assets/buildings/world1/building-fence.png", "tile": Vector2i(16, 19)}
]

# Fine-detail clutter (Fase 2, PixelLab map-objects) — purely decorative, no
# collision. Every tile is grass (never on the path/building footprint) AND
# within distance<=1 of the path network, clustered near a point of interest
# instead of scattered — each entry's comment names which POI it belongs to.
const WORLD1_GRASS_CLUTTER := [
	# Mae / henhouse approach
	{"id": "wildflower-white", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-white.png", "tile": Vector2i(4, 5), "scale": 0.9},
	{"id": "grass-tuft-a", "sprite_path": "res://assets/scenery/world1/clutter/grass-tuft-a.png", "tile": Vector2i(7, 4), "scale": 1.0},
	# Vera / clinic approach
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(21, 9), "scale": 0.9},
	{"id": "mushroom-cluster", "sprite_path": "res://assets/scenery/world1/clutter/mushroom-cluster.png", "tile": Vector2i(17, 9), "scale": 1.0},
	# Lily / coop approach
	{"id": "grass-tuft-b", "sprite_path": "res://assets/scenery/world1/clutter/grass-tuft-b.png", "tile": Vector2i(3, 10), "scale": 1.0},
	# Garden / Rose approach
	{"id": "wildflower-white", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-white.png", "tile": Vector2i(24, 13), "scale": 0.9},
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(24, 15), "scale": 0.9},
	# Billy's fence approach
	{"id": "tree-stump", "sprite_path": "res://assets/scenery/world1/clutter/tree-stump.png", "tile": Vector2i(13, 18), "scale": 1.0},
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(12, 18), "scale": 0.9},
	{"id": "mushroom-cluster", "sprite_path": "res://assets/scenery/world1/clutter/mushroom-cluster.png", "tile": Vector2i(17, 20), "scale": 1.0},
	# Old Mac / farm-gate approach
	{"id": "grass-tuft-a", "sprite_path": "res://assets/scenery/world1/clutter/grass-tuft-a.png", "tile": Vector2i(7, 19), "scale": 1.0},
]

# Farmyard clutter: hay bales, crates, barrel, signpost clustered near the
# buildings/paths they belong to (art brief §4). Non-blocking, same distance
# rule as grass clutter.
const WORLD1_FARM_CLUTTER := [
	# Chester / stable approach
	{"id": "hay-bale", "sprite_path": "res://assets/scenery/world1/clutter/hay-bale.png", "tile": Vector2i(10, 9), "scale": 1.1},
	{"id": "grass-tuft-b", "sprite_path": "res://assets/scenery/world1/clutter/grass-tuft-b.png", "tile": Vector2i(13, 9), "scale": 1.0},
	# Joe / barn approach
	{"id": "wood-crate", "sprite_path": "res://assets/scenery/world1/clutter/wood-crate.png", "tile": Vector2i(28, 4), "scale": 1.0},
	{"id": "barrel", "sprite_path": "res://assets/scenery/world1/clutter/barrel.png", "tile": Vector2i(28, 7), "scale": 1.0},
	{"id": "hay-bale", "sprite_path": "res://assets/scenery/world1/clutter/hay-bale.png", "tile": Vector2i(23, 6), "scale": 1.1},
	# Lily / coop approach
	{"id": "wood-crate", "sprite_path": "res://assets/scenery/world1/clutter/wood-crate.png", "tile": Vector2i(4, 9), "scale": 1.0},
	# Central crossroads — a signpost belongs at the junction itself
	{"id": "signpost", "sprite_path": "res://assets/scenery/world1/clutter/signpost.png", "tile": Vector2i(17, 11), "scale": 1.1},
]

# Ground decals painted directly on the path (cart tracks, footprints, puddles)
# — purely flat, rendered just above the tilemap, always sit ON walkable path
# tiles so the player actually walks over them (art brief §4).
const WORLD1_PATH_DECALS := [
	{"id": "cart-tracks", "sprite_path": "res://assets/scenery/world1/clutter/cart-tracks.png", "tile": Vector2i(12, 8)},
	{"id": "cart-tracks", "sprite_path": "res://assets/scenery/world1/clutter/cart-tracks.png", "tile": Vector2i(25, 6)},
	{"id": "footprints", "sprite_path": "res://assets/scenery/world1/clutter/footprints.png", "tile": Vector2i(20, 13)},
	{"id": "footprints", "sprite_path": "res://assets/scenery/world1/clutter/footprints.png", "tile": Vector2i(9, 8)},
	{"id": "mud-puddle", "sprite_path": "res://assets/scenery/world1/clutter/mud-puddle.png", "tile": Vector2i(15, 10)},
	{"id": "mud-puddle", "sprite_path": "res://assets/scenery/world1/clutter/mud-puddle.png", "tile": Vector2i(16, 20)},
]

# Border framing (art brief §6): dense bushes ringing the map edge so the farm
# reads as enclosed by wild vegetation instead of cutting off into flat grass.
# Reuses the already-approved bush asset; positions skip every occupied tile.
const WORLD1_BORDER_CLUTTER := [
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(3, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(6, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(9, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(15, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(21, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(27, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(30, 0), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(3, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(6, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(21, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(24, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(27, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(30, 23), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 3), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 6), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 12), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 15), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 18), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(0, 21), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(31, 3), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(31, 15), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(31, 18), "scale": 1.0},
	{"id": "bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(31, 21), "scale": 1.0},
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
