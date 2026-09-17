extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 40
const ROWS := 30
const SPAWN := Vector2i(20, 6)

var id: String = "world1"

# All 8 World 1 NPCs with PixelLab idle sprites. Positions sit on the path
# network immediately adjacent to their building's dooryard (see §1-§4 of the
# tile-by-tile spec) — never floating in open grass.
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
		"tile": Vector2i(16, 6),
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
		"tile": Vector2i(23, 13),
		"dialogue": "Dra. Vera: A clínica cuida dos animais da fazenda!"
	},
	{
		"id": "lily",
		"display_name": "Lily",
		"sprite_path": "res://assets/characters/world1/lily-idle.png",
		"tile": Vector2i(8, 15),
		"dialogue": "Lily: As galinhas botaram muito hoje!"
	},
	{
		"id": "grandma-rose",
		"display_name": "Vovó Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(26, 15),
		"dialogue": "Rose: As flores do jardim estão lindas."
	},
	{
		"id": "billy",
		"display_name": "Billy",
		"sprite_path": "res://assets/characters/world1/billy-idle.png",
		"tile": Vector2i(15, 19),
		"dialogue": "Billy: A cerca está firme. Ninguém passa!"
	},
	{
		"id": "old-mac",
		"display_name": "Old Mac",
		"sprite_path": "res://assets/characters/world1/old-mac-idle.png",
		"tile": Vector2i(15, 26),
		"dialogue": "Old Mac: O portão da fazenda é seguro."
	}
]

# Building footprints — pixel-verified per the tile-by-tile spec §1. All 2x2.
const BUILDINGS := [
	{"id": "henhouse", "sprite": "res://assets/buildings/world1/building-henhouse.png", "footprintCol": 6, "footprintRow": 3, "footprintW": 2, "footprintH": 2, "label": "GALINHEIRO"},
	{"id": "stable", "sprite": "res://assets/buildings/world1/building-stable.png", "footprintCol": 15, "footprintRow": 3, "footprintW": 2, "footprintH": 2, "label": "ESTÁBULO"},
	{"id": "barn", "sprite": "res://assets/buildings/world1/building-barn.png", "footprintCol": 26, "footprintRow": 3, "footprintW": 2, "footprintH": 2, "label": "CELEIRO"},
	{"id": "coop", "sprite": "res://assets/buildings/world1/building-coop.png", "footprintCol": 7, "footprintRow": 13, "footprintW": 2, "footprintH": 2, "label": "GALINHEIRO 2"},
	{"id": "clinic", "sprite": "res://assets/buildings/world1/building-animal-clinic.png", "footprintCol": 23, "footprintRow": 10, "footprintW": 2, "footprintH": 2, "label": "CLÍNICA"},
	{"id": "garden", "sprite": "res://assets/buildings/world1/building-garden.png", "footprintCol": 26, "footprintRow": 13, "footprintW": 2, "footprintH": 2, "label": "JARDIM"}
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

	# --- Path network (tile-by-tile spec §2-§4) ---
	# Horizontal trunk: row 5-6, col 2-37
	_paint_walkable(Rect2i(2, 5, 36, 2))
	# Vertical trunk A: col 6-7, row 6-27 (Henhouse -> Coop -> Fence -> Gate)
	_paint_walkable(Rect2i(6, 6, 2, 22))
	# Vertical trunk B: col 15-16, row 6-17 (Stable, ends at fence row)
	_paint_walkable(Rect2i(15, 6, 2, 12))
	# South corridor: col 14-16, row 18-28 (fence -> farm gate), continues trunk A south
	_paint_walkable(Rect2i(14, 18, 3, 11))
	# Coop connector: row 15, col 8-16 (dooryard -> trunk A, spec §4)
	_paint_walkable(Rect2i(8, 15, 9, 1))
	# Clinic stub: col 23-24, row 6-14 (horizontal trunk down to dooryard + plaza)
	_paint_walkable(Rect2i(23, 6, 2, 9))
	# Fountain plaza (Animal Clinic zone, spec §6)
	_paint_walkable(Rect2i(17, 13, 6, 4))
	# Garden connector: row 15, col 22-27 (plaza -> garden dooryard)
	_paint_walkable(Rect2i(22, 15, 6, 1))

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

	# Solid decorative props block movement (trees, fountain, well, mailbox, sign,
	# haybales, rocks, gate, fence — spec §11 BLOCKED_EXTRA)
	const SOLID_PROP_IDS := ["tree", "fountain", "well", "mailbox", "sign", "haybale", "rock", "farm-gate", "fence-left", "fence-right", "bench"]
	# Only wayside props (not ambient scatter planted deep in open grass) mark the
	# ground as path so they read as standing on dirt, not floating in grass.
	const PATHSIDE_PROP_IDS := ["fountain", "well", "mailbox", "sign", "farm-gate", "fence-left", "fence-right", "bench"]
	for prop in WORLD1_PROPS:
		var pt: Vector2i = prop.get("tile", Vector2i(-1, -1))
		if prop.id in SOLID_PROP_IDS and _in_bounds(pt):
			walkable[pt.y][pt.x] = false
		if prop.id in PATHSIDE_PROP_IDS and _in_bounds(pt):
			path_mask[pt.y][pt.x] = true

	# Fence gap (Billy, spec §8): walkable while his phases are incomplete.
	# Runtime collision flips to blocked only once phase 4 completes — see
	# effectiveWalkableMap equivalent when interactions are wired.
	_paint_walkable(Rect2i(14, 17, 2, 1))

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

# All World1 decorative props, transcribed directly from the tile-by-tile spec
# §5, §7, §8 (anchor trees, low prop clusters, fence zone), each already
# validated against the path network — nothing sits isolated.
const WORLD1_PROPS := [
	# Anchor trees (§5) — 1 per building except Coop/Clinic (skipped per spec)
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(8, 3)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(14, 3)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(28, 3)},
	{"id": "tree", "display_name": "Árvore", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(28, 13)},
	# Henhouse cluster (§7): flower pot, bush
	{"id": "flower-pot", "display_name": "Vaso", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(5, 4)},
	{"id": "bush", "display_name": "Arbusto", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(5, 5)},
	# Stable cluster: haybale, rock
	{"id": "haybale", "display_name": "Fardo de Feno", "sprite_path": "res://assets/scenery/world1/clutter/hay-bale.png", "tile": Vector2i(17, 4)},
	{"id": "rock", "display_name": "Pedra", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(17, 5)},
	# Barn cluster: stacked haybales (single prop), mailbox touching dooryard edge
	{"id": "haybale", "display_name": "Fardo de Feno", "sprite_path": "res://assets/scenery/world1/clutter/hay-bale.png", "tile": Vector2i(25, 4)},
	{"id": "mailbox", "display_name": "Caixa de Correio", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(28, 4)},
	# Coop cluster: well, bench facing well, single flower
	{"id": "well", "display_name": "Poço", "sprite_path": "res://assets/scenery/world1/scenery-well.png", "tile": Vector2i(9, 13)},
	{"id": "bench", "display_name": "Banco", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(9, 14)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(10, 14)},
	# Clinic: single flower pot at entrance corner
	{"id": "flower-pot", "display_name": "Vaso", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(22, 10)},
	# Fountain plaza (§6): fountain, sign, two tightened flower clusters (not an even scatter)
	{"id": "fountain", "display_name": "Fonte", "sprite_path": "res://assets/scenery/world1/scenery-fountain.png", "tile": Vector2i(19, 14)},
	{"id": "sign", "display_name": "Placa", "sprite_path": "res://assets/scenery/world1/clutter/signpost.png", "tile": Vector2i(20, 15)},
	{"id": "flower-yellow", "display_name": "Flor Amarela", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(17, 15)},
	{"id": "flower-yellow", "display_name": "Flor Amarela", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(18, 15)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(20, 16)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(21, 16)},
	# Fence zone (§8): stump SW of Billy, flower mirrors it on the opposite side
	{"id": "tree-stump", "display_name": "Toco", "sprite_path": "res://assets/scenery/world1/clutter/tree-stump.png", "tile": Vector2i(13, 18)},
	{"id": "flower-purple", "display_name": "Flor Roxa", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(16, 16)},
	{"id": "fence-left", "display_name": "Cerca", "sprite_path": "res://assets/buildings/world1/building-fence.png", "tile": Vector2i(13, 17)},
	{"id": "fence-right", "display_name": "Cerca", "sprite_path": "res://assets/buildings/world1/building-fence.png", "tile": Vector2i(16, 17)},
	# Farm Gate (§9): kept clear, no additional decoration around the threshold
	{"id": "farm-gate", "display_name": "Portão", "sprite_path": "res://assets/buildings/world1/building-farm-gate-open.png", "tile": Vector2i(15, 28)},
	# Ambient scatter (§10) — exactly 3 for the whole map, far from any building,
	# reads as background without crowding. Do not add more.
	{"id": "haybale", "display_name": "Fardo de Feno", "sprite_path": "res://assets/scenery/world1/clutter/hay-bale.png", "tile": Vector2i(18, 7)},
	{"id": "rock", "display_name": "Pedra", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(30, 8)},
	{"id": "flower-red", "display_name": "Flor Vermelha", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(10, 20)},
]

# Ground decals painted directly on the path (cart tracks, footprints, puddles)
# — purely flat, rendered just above the tilemap, always sit ON walkable path
# tiles so the player actually walks over them.
const WORLD1_PATH_DECALS := [
	{"id": "cart-tracks", "sprite_path": "res://assets/scenery/world1/clutter/cart-tracks.png", "tile": Vector2i(12, 6)},
	{"id": "footprints", "sprite_path": "res://assets/scenery/world1/clutter/footprints.png", "tile": Vector2i(9, 8)},
	{"id": "mud-puddle", "sprite_path": "res://assets/scenery/world1/clutter/mud-puddle.png", "tile": Vector2i(16, 8)},
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
