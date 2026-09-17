extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 30
const ROWS := 20
const SPAWN := Vector2i(15, 6)

var id: String = "world1"

# 8 World 1 NPCs — full script per NPC-teaching-plan.md spec.
# Positions follow the 30x20 grid, each NPC on a reachable tile.
# Sprites: current PixelLab pixel art for all 8 characters.
#
# Quest types:
#   "numberpad"  — type the answer (addition, subtraction, counting, sequence)
#   "compare"    — choose which group has more (tap A or B)
#   "compare_equal" — choose which group (may be equal)
#   "compare_length" — which object is taller/longer
#
# Interaction flow: intro → quest_start (show problem) → player answers → success → complete
#                                                         → failure (retry, max 3)
const NPCS_TEMPLATE := [
	{
		"id": "mae",
		"display_name": "Mae",
		"sprite_path": "res://assets/characters/world1/mae-idle.png",
		"tile": Vector2i(4, 4),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Oh! So glad you arrived! The storm messed everything up. I collected 4 eggs this morning, then found 3 more behind the hay! Can you help me count how many I have in total?",
		"quest": {
			"type": "numberpad",
			"problem": "Mae collected 4 eggs in the morning.\nThen she found 3 more behind the hay!\nHow many eggs does she have now?",
			"correct_answer": 7,
			"hints": ["Count the 4 eggs she already had, then add 3 more: 4, 5, 6, 7.", "4 + 3: count up from 4 — 5, 6, 7.", "There are 7 eggs in total."],
			"success": "Seven eggs! That's a great morning for the hens.",
			"failure": "Hmm, not quite. Let's try counting again — 4 plus 3 more.",
			"complete": "The henhouse is looking better already. Come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/egg.png", "count": 7}
		}
	},
	{
		"id": "chester",
		"display_name": "Chester",
		"sprite_path": "res://assets/characters/world1/chester-idle.png",
		"tile": Vector2i(14, 4),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "*Neigh!* I'm Chester the horse. Chester ate 5 carrots this morning, and I'm bringing him 6 more for lunch. Can you help me count the total?",
		"quest": {
			"type": "numberpad",
			"problem": "Chester ate 5 carrots this morning.\nNow I'm bringing him 6 more for lunch.\nHow many carrots is that in total?",
			"correct_answer": 11,
			"hints": ["Count the 5 carrots he already ate, then add 6 more: 5, 6, 7, 8, 9, 10, 11.", "5 + 6: count up from 5 — 6, 7, 8, 9, 10, 11.", "There are 11 carrots altogether."],
			"success": "Chester's going to be one happy horse! Eleven carrots total.",
			"failure": "Hmm, let's try again. 5 carrots plus 6 more — count them up.",
			"complete": "The stable is looking better already. Come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/carrot.png", "count": 11}
		}
	},
	{
		"id": "farmer-joe",
		"display_name": "Farmer Joe",
		"sprite_path": "res://assets/characters/world1/farmer-joe-idle.png",
		"tile": Vector2i(24, 4),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Hey there! I'm Farmer Joe. I'm building a new barn and I need help with calculations. I stacked 6 hay bales this morning, and just brought in 5 more from the field! Can you help me count the total?",
		"quest": {
			"type": "numberpad",
			"problem": "Joe stacked 6 hay bales this morning.\nThen he brought in 5 more from the field!\nHow many hay bales does he have now?",
			"correct_answer": 11,
			"hints": ["Count the 6 bales he already stacked, then add 5 more: 6, 7, 8, 9, 10, 11.", "6 + 5: count up from 6 — 7, 8, 9, 10, 11.", "There are 11 bales in total."],
			"success": "Eleven bales — that'll last us a while!",
			"failure": "Hmm, let's try again. 6 bales plus 5 more — count them up.",
			"complete": "Stop by the barn anytime for more math help!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/hay-bale.png", "count": 11}
		}
	},
	{
		"id": "lily",
		"display_name": "Lily",
		"sprite_path": "res://assets/characters/world1/lily-idle.png",
		"tile": Vector2i(4, 7),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Hi! I'm Lily. I found 3 baby chicks by the fence, and 4 more near the barn! Can you help me count how many chicks I have in total?",
		"quest": {
			"type": "numberpad",
			"problem": "Lily found 3 baby chicks by the fence.\nThen she found 4 more near the barn!\nHow many chicks does she have now?",
			"correct_answer": 7,
			"hints": ["Count the 3 chicks she already found, then add 4 more: 3, 4, 5, 6, 7.", "3 + 4: count up from 3 — 4, 5, 6, 7.", "There are 7 chicks in total."],
			"success": "Seven little chicks, all safe and sound!",
			"failure": "Hmm, that's not quite it. Let's try counting again — 3 plus 4 more.",
			"complete": "Come back anytime — the chicks always need counting!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/chick.png", "count": 7}
		}
	},
	{
		"id": "vera",
		"display_name": "Dr. Vera",
		"sprite_path": "res://assets/characters/world1/vera-idle.png",
		"tile": Vector2i(24, 7),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Welcome to the clinic! I have 5 bandages ready, and just restocked 6 more from the supply closet. Can you help me count how many I have in total?",
		"quest": {
			"type": "numberpad",
			"problem": "Vera has 5 bandages ready.\nShe just restocked 6 more from the supply closet!\nHow many bandages does she have now?",
			"correct_answer": 11,
			"hints": ["Count the 5 bandages she already had, then add 6 more: 5, 6, 7, 8, 9, 10, 11.", "5 + 6: count up from 5 — 6, 7, 8, 9, 10, 11.", "There are 11 bandages in total."],
			"success": "Eleven bandages — fully stocked for whatever comes in!",
			"failure": "Hmm, not quite. Let's try counting again — 5 plus 6 more.",
			"complete": "The clinic is always open — come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/bandage.png", "count": 11}
		}
	},
	{
		"id": "grandma-rose",
		"display_name": "Grandma Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(25, 14),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Well hello, dear! I picked 7 tomatoes this morning, and just found 5 more hiding under the leaves! Can you help me count the total?",
		"quest": {
			"type": "numberpad",
			"problem": "Grandma Rose picked 7 tomatoes this morning.\nThen she found 5 more hiding under the leaves!\nHow many tomatoes does she have now?",
			"correct_answer": 12,
			"hints": ["Count the 7 tomatoes she already picked, then add 5 more: 7, 8, 9, 10, 11, 12.", "7 + 5: count up from 7 — 8, 9, 10, 11, 12.", "There are 12 tomatoes in total."],
			"success": "Twelve tomatoes — perfect for tonight's sauce!",
			"failure": "Hmm, not quite. Let's try again — 7 plus 5 more tomatoes.",
			"complete": "The garden always needs a careful observer. Come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/tomato.png", "count": 12}
		}
	},
	{
		"id": "billy",
		"display_name": "Billy",
		"sprite_path": "res://assets/characters/world1/billy-idle.png",
		"tile": Vector2i(15, 10),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Hey! I'm Billy. I've got 6 nails in my toolbox, and Old Mac just gave me 4 more! Can you help me count how many nails I have now?",
		"quest": {
			"type": "numberpad",
			"problem": "Billy has 6 nails in his toolbox.\nOld Mac just gave him 4 more!\nHow many nails does Billy have now?",
			"correct_answer": 10,
			"hints": ["Count the 6 nails he already had, then add 4 more: 6, 7, 8, 9, 10.", "6 + 4: count up from 6 — 7, 8, 9, 10.", "There are 10 nails in total."],
			"success": "Ten nails — enough to finish this fence!",
			"failure": "Hmm, let's try again. 6 nails plus 4 more — count them up.",
			"complete": "I'll be right here at the gate. Come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/nail.png", "count": 10}
		}
	},
	{
		"id": "old-mac",
		"display_name": "Old Mac",
		"sprite_path": "res://assets/characters/world1/old-mac-idle.png",
		"tile": Vector2i(15, 19),
		"ccss": "2.OA.A.1",
		"skill": "Addition",
		"dialogue": "Hmm. You're doing well with addition! Let me test you one more time. I found 4 old keys in the shed, and just discovered 5 more in the workbench drawer. Can you help me count how many keys I have in total?",
		"quest": {
			"type": "numberpad",
			"problem": "Old Mac found 4 old keys in the shed.\nThen he discovered 5 more in the workbench drawer!\nHow many keys does he have now?",
			"correct_answer": 9,
			"hints": ["Count the 4 keys he already found, then add 5 more: 4, 5, 6, 7, 8, 9.", "4 + 5: count up from 4 — 5, 6, 7, 8, 9.", "There are 9 keys in total."],
			"success": "Nine keys — one of these has got to open the gate! Welcome to Downtown.",
			"failure": "Hmm, not quite. Let's try again — 4 keys plus 5 more.",
			"complete": "The gate is open. Welcome to the city, kid.",
			"visual": {"icon": "res://assets/scenery/world1/clutter/key.png", "count": 9}
		}
	}
]

# Building footprints — layout from the latest user spec (30x20 grid, exact
# col/row per building). Sprites unchanged (current PixelLab pixel art).
const BUILDINGS := [
	{"id": "henhouse", "sprite": "res://assets/buildings/world1/building-henhouse.png", "footprintCol": 3, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "HENHOUSE", "scale": 1.0, "flip_h": true},
	{"id": "stable", "sprite": "res://assets/buildings/world1/building-stable.png", "footprintCol": 13, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "STABLE", "scale": 1.5, "flip_h": false},
	{"id": "barn", "sprite": "res://assets/buildings/world1/building-barn.png", "footprintCol": 23, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "BARN", "scale": 2.0, "flip_h": false},
	{"id": "coop", "sprite": "res://assets/buildings/world1/building-coop.png", "footprintCol": 3, "footprintRow": 8, "footprintW": 2, "footprintH": 2, "label": "COOP", "scale": 1.0, "flip_h": true},
	{"id": "clinic", "sprite": "res://assets/buildings/world1/building-animal-clinic.png", "footprintCol": 23, "footprintRow": 8, "footprintW": 2, "footprintH": 2, "label": "CLINIC", "scale": 1.5, "flip_h": false},
	{"id": "garden", "sprite": "res://assets/buildings/world1/building-garden.png", "footprintCol": 26, "footprintRow": 14, "footprintW": 2, "footprintH": 2, "label": "GARDEN", "scale": 1.0, "flip_h": false}
]

var walkable: Array[Array] = []
var path_mask: Array[Array] = []
var NPCS: Array = []

func _init() -> void:
	# Deep-duplicate the template so each NPC dict is a fresh, WRITABLE copy —
	# dictionaries nested inside a `const` array are read-only in Godot 4, so
	# the map editor could never persist a dragged NPC's new tile without this.
	NPCS = NPCS_TEMPLATE.duplicate(true)
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
	# South yard + side bypass for Coop and Clinic, so their door (which faces
	# down/south on the sprite, same as every other building — no flips) has
	# real street right in front of it, matching each building's true street
	# side instead of forcing a broken vertical-flip on the art.
	_paint_walkable(Rect2i(3, 10, 2, 1))
	_paint_walkable(Rect2i(2, 6, 1, 5))
	_paint_walkable(Rect2i(23, 10, 2, 1))
	_paint_walkable(Rect2i(25, 6, 1, 5))
	# South yard for Garden too — same reasoning: every building's door now
	# faces south (per the unified stable-style art), so Garden needs street
	# directly below its footprint as well, not just the west-side approach.
	_paint_walkable(Rect2i(25, 15, 1, 2))
	_paint_walkable(Rect2i(25, 16, 3, 1))

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

func get_adjacent_npc_quest(tile: Vector2i) -> Dictionary:
	var npc := get_adjacent_npc(tile)
	if npc and npc.has("quest"):
		return npc.quest
	return {}

# --- Prop definitions per world ---

# World1 decorative props — repositioned for the new 30x20 layout, every
# tile within Chebyshev distance<=1 of the path network or a building
# footprint (the validated placement rule), clustered near the POI it
# belongs to. Sprites unchanged (current PixelLab pixel art).
const WORLD1_PROPS := [
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(7, 4)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(20, 6)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(28, 6)},
	# Henhouse (Mae) cluster
	{"id": "flower-pot", "display_name": "Flower Pot", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(5, 4)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(5, 5)},
	# Stable (Chester) cluster
	{"id": "lamppost", "display_name": "Lamppost", "sprite_path": "res://assets/scenery/world1/scenery-lamppost.png", "tile": Vector2i(17, 4)},
	{"id": "stone", "display_name": "Stone", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(17, 5)},
	# Barn (Joe) cluster
	{"id": "mailbox", "display_name": "Mailbox", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(25, 4)},
	{"id": "flower-yellow", "display_name": "Yellow Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(26, 4)},
	# Coop (Lily) cluster
	{"id": "well", "display_name": "Well", "sprite_path": "res://assets/scenery/world1/scenery-well.png", "tile": Vector2i(3, 5)},
	{"id": "bench", "display_name": "Bench", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(5, 6)},
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(5, 7)},
	# Clinic (Vera) cluster
	{"id": "fountain", "display_name": "Fountain", "sprite_path": "res://assets/scenery/world1/scenery-fountain.png", "tile": Vector2i(22, 7)},
	{"id": "flower-pot", "display_name": "Flower Pot", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(26, 6)},
	# Garden (Rose) cluster
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(24, 14)},
	{"id": "flower-yellow", "display_name": "Yellow Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(24, 15)},
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
	{"id": "wildflower-purple", "sprite_path": "res://assets/scenery/world1/clutter/wildflower-purple.png", "tile": Vector2i(26, 15), "scale": 0.9},
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
	{"id": "anchor-rusty", "display_name": "Rusty Anchor", "sprite_path": "res://assets/scenery/world2/scenery-anchor-rusty.png"},
	{"id": "barrel", "display_name": "Barrel", "sprite_path": "res://assets/scenery/world2/scenery-barrel.png"},
	{"id": "crates-stack", "display_name": "Crates Stack", "sprite_path": "res://assets/scenery/world2/scenery-crates-stack.png"},
	{"id": "fishing-net", "display_name": "Fishing Net", "sprite_path": "res://assets/scenery/world2/scenery-fishing-net.png"},
	{"id": "market-stall", "display_name": "Market Stall", "sprite_path": "res://assets/scenery/world2/scenery-market-stall.png"},
	{"id": "seagull", "display_name": "Seagull", "sprite_path": "res://assets/scenery/world2/scenery-seagull.png"}
]

func get_world_props(world_id: String) -> Array:
	match world_id:
		"world1": return WORLD1_PROPS
		"world2": return WORLD2_PROPS
		_: return WORLD1_PROPS
