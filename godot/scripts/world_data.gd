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
const NPCS := [
	{
		"id": "mae",
		"display_name": "Mae",
		"sprite_path": "res://assets/characters/world1/mae-idle.png",
		"tile": Vector2i(4, 4),
		"ccss": "K.CC.B.4",
		"skill": "Counting 1:1",
		"dialogue": "Oh! So glad you arrived! The storm messed everything up. I need to know how many eggs I collected today, but I lost count. Can you help me?",
		"quest": {
			"type": "numberpad",
			"problem": "Mae dropped her egg basket! Count the scattered eggs.\nHow many eggs are there?",
			"correct_answer": 4,
			"hints": ["Point at each egg as you count.", "Count out loud: 1, 2, 3...", "Take your time!"],
			"success": "Perfect! {answer} eggs! Now I know what to take to the market!",
			"failure": "Hmm, not quite. Let's try again — point at each egg.",
			"complete": "The henhouse is looking better already. Come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/egg.png", "count": 4}
		}
	},
	{
		"id": "chester",
		"display_name": "Chester",
		"sprite_path": "res://assets/characters/world1/chester-idle.png",
		"tile": Vector2i(14, 4),
		"ccss": "K.CC.C.6",
		"skill": "Compare groups",
		"dialogue": "*Neigh!* I have two piles of hay here. Which has MORE for me to eat first? I don't want to end up with the smaller one!",
		"quest": {
			"type": "compare",
			"problem": "Chester has two piles of hay.\nPile A: 2 bales\nPile B: 7 bales\nWhich pile has MORE?",
			"correct_answer": "B",
			"hints": ["Look at both piles. Which one is taller?", "Count the bales in each pile.", "7 is more than 2!"],
			"success": "*Happy neigh!* Perfect! Pile B has more!",
			"failure": "Hmm, let's look again. Count each pile — which number is bigger?",
			"complete": "The stable is looking better already. Come back anytime!",
			"visual": {"icon_a": "res://assets/scenery/world1/clutter/hay-bale.png", "icon_b": "res://assets/scenery/world1/clutter/hay-bale.png", "count_a": 2, "count_b": 7}
		}
	},
	{
		"id": "farmer-joe",
		"display_name": "Farmer Joe",
		"sprite_path": "res://assets/characters/world1/farmer-joe-idle.png",
		"tile": Vector2i(24, 4),
		"ccss": "K.OA.A.2",
		"skill": "Add & subtract",
		"dialogue": "Hey there! I'm Farmer Joe. I'm building a new barn and I need help with calculations. I have 3 hay bales and received 4 more. How many do I have now?",
		"quest": {
			"type": "numberpad",
			"problem": "Joe has 3 hay bales.\nHe received 4 more.\nHow many hay bales does Joe have now?",
			"correct_answer": 7,
			"hints": ["Start with the first number and count up.", "Point at each hay bale as you count.", "3 + 4: count 4, 5, 6, 7."],
			"success": "That's right! 7 hay bales total!",
			"failure": "Hmm, let's try again. Count the first group, then add the second.",
			"complete": "Stop by the barn anytime for more math help!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/hay-bale.png", "count": 7}
		}
	},
	{
		"id": "lily",
		"display_name": "Lily",
		"sprite_path": "res://assets/characters/world1/lily-idle.png",
		"tile": Vector2i(4, 7),
		"ccss": "K.OA.A.2",
		"skill": "Add & subtract",
		"dialogue": "Hi! I'm Lily. The chicks are always running off! There were 3 in the pen and 2 more came running. How many chicks do I have now?",
		"quest": {
			"type": "numberpad",
			"problem": "Lily had 3 chicks in the pen.\n2 more came running!\nHow many chicks does Lily have now?",
			"correct_answer": 5,
			"hints": ["Count the first group, then count the second group.", "Point at each chick as you count.", "3 + 2: count 4, 5."],
			"success": "Perfect! All 5 chicks are safe in the pen!",
			"failure": "Hmm, that's not quite it. Let's try counting again.",
			"complete": "Come back anytime — the chicks always need counting!",
			"visual": {"icon": "res://assets/characters/world1/lily-idle.png", "count": 5}
		}
	},
	{
		"id": "vera",
		"display_name": "Dr. Vera",
		"sprite_path": "res://assets/characters/world1/vera-idle.png",
		"tile": Vector2i(24, 7),
		"ccss": "K.OA.A.1",
		"skill": "Addition",
		"dialogue": "Welcome to the clinic! 4 kittens are sleeping and 3 more just hopped in. How many kittens are there now?",
		"quest": {
			"type": "numberpad",
			"problem": "4 kittens are sleeping in the basket.\n3 more just hopped in.\nHow many kittens are there now?",
			"correct_answer": 7,
			"hints": ["Start with the bigger number and count up.", "Count the first group, then add the second.", "4 + 3: count 5, 6, 7."],
			"success": "Perfect! You added them correctly!",
			"failure": "Not quite — let's try counting from the bigger number.",
			"complete": "The clinic is always open — come back anytime!",
			"visual": {"icon": "res://assets/characters/world1/vera-idle.png", "count": 7}
		}
	},
	{
		"id": "grandma-rose",
		"display_name": "Grandma Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(25, 14),
		"ccss": "K.MD.A.1",
		"skill": "Compare lengths",
		"dialogue": "Well hello, dear! Look at the sunflower and the carrot. Which one is taller?",
		"quest": {
			"type": "compare_length",
			"problem": "Look at the sunflower and the carrot.\nWhich one is taller?",
			"correct_answer": "sunflower",
			"options": ["Sunflower", "Carrot"],
			"hints": ["Compare them side by side — which one reaches higher?", "Look at the stems. The longer stem means the taller plant.", "The sunflower stretches way up high!"],
			"success": "Why yes, the sunflower is taller — you've got a good eye!",
			"failure": "Hmm, take another look. Which one reaches higher?",
			"complete": "The garden always needs a careful observer. Come back anytime!",
			"visual": {"icon_a": "res://assets/scenery/world1/scenery-flower-yellow.png", "icon_b": "res://assets/scenery/world1/scenery-tree.png"}
		}
	},
	{
		"id": "billy",
		"display_name": "Billy",
		"sprite_path": "res://assets/characters/world1/billy-idle.png",
		"tile": Vector2i(15, 10),
		"ccss": "K.CC.A.1",
		"skill": "Number sequence",
		"dialogue": "Hey! I'm Billy. I'm numbering the fence posts. We counted 1,2,3... up to 10. What number comes next?",
		"quest": {
			"type": "numberpad",
			"problem": "Billy is numbering fence posts.\nHe counted: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10\nWhat number comes next?",
			"correct_answer": 11,
			"hints": ["Count from 1 to 10, then keep going!", "What comes after 10?", "10, then 11!"],
			"success": "That's right! After 10 comes 11. Nice one!",
			"failure": "Hmm, let's try again. Count from 1 to 10, then keep going!",
			"complete": "I'll be right here at the gate. Come back anytime!",
			"visual": {"icon": "res://assets/scenery/world1/clutter/signpost.png", "count": 11}
		}
	},
	{
		"id": "old-mac",
		"display_name": "Old Mac",
		"sprite_path": "res://assets/characters/world1/old-mac-idle.png",
		"tile": Vector2i(15, 19),
		"ccss": "K review",
		"skill": "Gatekeeper",
		"dialogue": "Hmm. You know how to count, compare, add and subtract. But let me warn you — out there the numbers get BIGGER. Think you can handle that?",
		"quest": {
			"type": "numberpad",
			"problem": "Old Mac wants to make sure you're ready.\nCount these animals for him.\n(There are 8 animals)",
			"correct_answer": 8,
			"hints": ["Point at each animal as you count.", "Count out loud: 1, 2, 3...", "Take your time — there's no rush."],
			"success": "Not bad. You counted them correctly.",
			"failure": "Not quite. Let's try again — take your time.",
			"complete": "The gate is open. Welcome to the city, kid.",
			"visual": {"icon": "res://assets/characters/world1/mae-idle.png", "count": 8}
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
