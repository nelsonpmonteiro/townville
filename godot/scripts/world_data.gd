extends RefCounted
class_name WorldData

const TILE_SIZE := 48
const COLS := 30
const ROWS := 20
const SPAWN := Vector2i(15, 6)

var id: String = "world1"

# 8 World 1 NPCs - full script per NPC-teaching-plan.md spec.
# Positions follow the 30x20 grid, each NPC on a reachable tile.
# Sprites: current PixelLab pixel art for all 8 characters.
#
# Quest types:
#   "numberpad"  - type the answer (addition, subtraction, counting, sequence)
#   "compare"    - choose which group has more (tap A or B)
#   "compare_equal" - choose which group (may be equal)
#   "compare_length" - which object is taller/longer
#
# Interaction flow: intro → quest_start (show problem) → player answers → success → complete
#                                                         → failure (retry, max 3)
const NPCS_TEMPLATE := [
	{
		"id": "mae",
		"display_name": "Mae",
		"sprite_path": "res://assets/characters/world1/mae-idle.png",
		"tile": Vector2i(9, 5),
		"building": "henhouse",
		"item": "egg",
		"container": "basket",
		"intro": "Oh! So glad you arrived! The storm messed everything up around the henhouse.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 4, "b": 3, "answer": 7,
				"setup": "I collected 4 eggs from the nesting boxes this morning. Then I found 3 more behind the hay! Drag them into my basket so we know the total.",
				"success": "Seven eggs! That's a great morning for the hens.",
				"hint1": "Let's count together - how many are already in the basket?"},
			{"phase": 2, "mode": "basket_out", "start": 9, "remove": 2, "answer": 7, "tray": "Grandma Rose",
				"setup": "I have 9 eggs in my basket, but 2 of them are for Grandma Rose's baking. Drag 2 eggs out so I know how many are left for selling.",
				"success": "Seven left to sell - perfect!",
				"hint1": "Try taking just one egg out first, then count what's left."},
			{"phase": 3, "mode": "text", "answer": 12, "grid": [3, 4],
				"setup": "Each of my 3 hens laid 4 eggs today. How many eggs is that in total?",
				"success": "Twelve eggs - you did that fast!",
				"hint1": "Try adding 4 three times: 4 + 4 + 4."},
			{"phase": 4, "mode": "text", "answer": 3, "grid": [4, 3], "groups": 4,
				"setup": "I have 12 eggs and want to put the same number in each of my 4 baskets. How many eggs go in each basket?",
				"success": "Three in each basket - nice and even!",
				"hint1": "Try sharing them out one at a time, basket by basket."}
		]
	},
	{
		"id": "chester",
		"display_name": "Chester",
		"sprite_path": "res://assets/characters/world1/chester-idle.png",
		"tile": Vector2i(14, 4),
		"building": "stable",
		"item": "carrot",
		"container": "feed basket",
		"intro": "*Neigh!* I'm Chester the horse. Well - I'm his stable hand, but he does the talking.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 5, "b": 6, "answer": 11,
				"setup": "Chester ate 5 carrots this morning, and I'm bringing him 6 more for lunch. Drag them all into his feed basket.",
				"success": "Chester's going to be one happy horse!",
				"hint1": "Count the carrots already there, then add the new ones."},
			{"phase": 2, "mode": "basket_out", "start": 10, "remove": 4, "answer": 6, "tray": "Old Mac's pony",
				"setup": "Chester's basket has 10 carrots, but 4 need to go to Old Mac's pony too. Drag 4 out.",
				"success": "Six carrots left for Chester - just right.",
				"hint1": "Take away one carrot at a time and count what's left."},
			{"phase": 3, "mode": "text", "answer": 6, "grid": [2, 3],
				"setup": "Chester eats 3 flakes of hay, 2 times a day. How many flakes does he eat in one day?",
				"success": "Six flakes - Chester's schedule, all figured out!",
				"hint1": "Try adding 3 two times: 3 + 3."},
			{"phase": 4, "mode": "text", "answer": 5, "grid": [3, 5], "groups": 3,
				"setup": "I have 15 carrots to split evenly between Chester and the two ponies next door - 3 animals total. How many carrots does each one get?",
				"success": "Five each - everybody's fed fair and square.",
				"hint1": "Try giving one carrot to each animal, then another round, and see how far you get."}
		]
	},
	{
		"id": "farmer-joe",
		"display_name": "Farmer Joe",
		"sprite_path": "res://assets/characters/world1/farmer-joe-idle.png",
		"tile": Vector2i(24, 4),
		"building": "barn",
		"item": "hay bale",
		"container": "cart",
		"intro": "Hey there! I'm Farmer Joe. I'm fixing up the barn and I could use a sharp counter.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 6, "b": 5, "answer": 11,
				"setup": "I stacked 6 hay bales this morning, and just brought in 5 more from the field. Drag them all onto the cart.",
				"success": "Eleven bales - that'll last us a while!",
				"hint1": "Count what's on the cart first, then add the new bales."},
			{"phase": 2, "mode": "basket_out", "start": 14, "remove": 6, "answer": 8, "tray": "Stable",
				"setup": "I've got 14 bales on the cart, but 6 need to go over to the Stable for Chester. Drag 6 off.",
				"success": "Eight bales staying right here - good count.",
				"hint1": "Try removing one bale at a time and counting what's left."},
			{"phase": 3, "mode": "text", "answer": 20, "grid": [4, 5],
				"setup": "Each row in my field has 5 pumpkins, and I've got 4 rows planted. How many pumpkins is that altogether?",
				"success": "Twenty pumpkins - that's a whole lot of pie!",
				"hint1": "Try adding 5 four times."},
			{"phase": 4, "mode": "text", "answer": 6, "grid": [3, 6], "groups": 3,
				"setup": "I picked 18 pumpkins and want to load them equally onto 3 wagons. How many pumpkins per wagon?",
				"success": "Six per wagon - perfectly balanced loads.",
				"hint1": "Try handing out pumpkins one at a time to each wagon."}
		]
	},
	{
		"id": "lily",
		"display_name": "Lily",
		"sprite_path": "res://assets/characters/world1/lily-idle.png",
		"tile": Vector2i(2, 10),
		"building": "coop",
		"item": "chick",
		"container": "coop basket",
		"intro": "Hi! I'm Lily. The chicks got out during the storm and I'm rounding them up.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 3, "b": 4, "answer": 7,
				"setup": "I found 3 baby chicks by the fence, and 4 more near the barn! Drag them all into the coop basket to keep them safe.",
				"success": "Seven little chicks, all safe and sound!",
				"hint1": "Count the chicks already in, then add the ones you found."},
			{"phase": 2, "mode": "basket_out", "start": 8, "remove": 3, "answer": 5, "tray": "Mama hen",
				"setup": "I have 8 chicks in the basket, but 3 are ready to go live with their mama hen. Drag 3 out.",
				"success": "Five still here with us - the others are happy with mama.",
				"hint1": "Take one chick out at a time and count what's left."},
			{"phase": 3, "mode": "text", "answer": 8, "grid": [4, 2],
				"setup": "Each hen has 2 chicks following her, and I count 4 hens. How many chicks is that in total?",
				"success": "Eight little chicks - quite the parade!",
				"hint1": "Try adding 2 four times."},
			{"phase": 4, "mode": "text", "answer": 5, "grid": [2, 5], "groups": 2,
				"setup": "I have 10 chicks and want to put the same number in each of my 2 coop pens. How many chicks in each pen?",
				"success": "Five in each pen - nice and cozy.",
				"hint1": "Try sharing them out one at a time between the two pens."}
		]
	},
	{
		"id": "vera",
		"display_name": "Dr. Vera",
		"sprite_path": "res://assets/characters/world1/vera-idle.png",
		"tile": Vector2i(25, 10),
		"building": "clinic",
		"item": "bandage",
		"container": "medical basket",
		"intro": "Welcome to the clinic! Every patient gets counted here - supplies too.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 5, "b": 6, "answer": 11,
				"setup": "I have 5 bandages ready, and just restocked 6 more from the supply closet. Drag them all into my medical basket.",
				"success": "Eleven bandages - fully stocked for whatever comes in!",
				"hint1": "Count what's in the basket, then add the new ones."},
			{"phase": 2, "mode": "basket_out", "start": 10, "remove": 4, "answer": 6, "tray": "Chester's checkup",
				"setup": "I have 10 treats for good patients, but I just used 4 on Chester's checkup. Drag 4 out.",
				"success": "Six treats left - plenty for the next visit.",
				"hint1": "Take one treat out at a time and count what's left."},
			{"phase": 3, "mode": "text", "answer": 6, "grid": [3, 2],
				"setup": "Each of my 3 animal patients today needs 2 check-up stickers. How many stickers do I need in total?",
				"success": "Six stickers - every patient gets their reward!",
				"hint1": "Try adding 2 three times."},
			{"phase": 4, "mode": "text", "answer": 3, "grid": [4, 3], "groups": 4,
				"setup": "I have 12 treats and want to give the same number to each of my 4 furry patients today. How many treats per patient?",
				"success": "Three each - every patient gets a fair share!",
				"hint1": "Try handing out treats one at a time to each patient."}
		]
	},
	{
		"id": "grandma-rose",
		"display_name": "Grandma Rose",
		"sprite_path": "res://assets/characters/world1/grandma-rose-idle.png",
		"tile": Vector2i(25, 14),
		"building": "garden",
		"item": "tomato",
		"container": "basket",
		"intro": "Well hello, dear! The garden always needs a careful pair of eyes.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 7, "b": 5, "answer": 12,
				"setup": "I picked 7 tomatoes this morning, and just found 5 more hiding under the leaves. Drag them all into my basket.",
				"success": "Twelve tomatoes - perfect for tonight's sauce!",
				"hint1": "Count what's in the basket, then add the new tomatoes."},
			{"phase": 2, "mode": "basket_out", "start": 13, "remove": 5, "answer": 8, "tray": "Sam's bakery",
				"setup": "My basket has 13 tomatoes, but 5 are going to Sam's bakery in town. Drag 5 out.",
				"success": "Eight tomatoes staying with me - plenty for us.",
				"hint1": "Take away one tomato at a time and count what's left."},
			{"phase": 3, "mode": "text", "answer": 12, "grid": [4, 3],
				"setup": "I planted 4 flower pots, with 3 flowers in each. How many flowers is that in total?",
				"success": "Twelve flowers - my garden's never looked prettier!",
				"hint1": "Try adding 3 four times."},
			{"phase": 4, "mode": "text", "answer": 4, "grid": [4, 4], "groups": 4,
				"setup": "I picked 16 flowers and want to make equal bouquets for my 4 neighbors. How many flowers in each bouquet?",
				"success": "Four flowers each - every bouquet just as lovely.",
				"hint1": "Try handing out flowers one at a time to each neighbor's bunch."}
		]
	},
	{
		"id": "billy",
		"display_name": "Billy",
		"sprite_path": "res://assets/characters/world1/billy-idle.png",
		"tile": Vector2i(15, 10),
		"building": "",
		"item": "nail",
		"container": "toolbox",
		"intro": "Hey! I'm Billy. This fence won't fix itself - want to help me count supplies?",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 6, "b": 4, "answer": 10,
				"setup": "I've got 6 nails in my toolbox, and Old Mac just gave me 4 more. Drag them all into the box.",
				"success": "Ten nails - enough to finish this fence!",
				"hint1": "Count what's in the box, then add the new nails."},
			{"phase": 2, "mode": "basket_out", "start": 9, "remove": 3, "answer": 6, "tray": "Scrap pile",
				"setup": "I have 9 planks stacked up, but 3 are warped and need to go to the scrap pile. Drag 3 out.",
				"success": "Six good planks left - plenty to work with.",
				"hint1": "Take one plank out at a time and count what's left."},
			{"phase": 3, "mode": "text", "answer": 12, "grid": [3, 4],
				"setup": "Each fence section needs 4 nails, and I'm building 3 sections today. How many nails do I need in total?",
				"success": "Twelve nails - exactly enough, nothing wasted!",
				"hint1": "Try adding 4 three times."},
			{"phase": 4, "mode": "text", "answer": 3, "grid": [5, 3], "groups": 5,
				"setup": "I have 15 nails and need to split them evenly across 5 fence posts. How many nails per post?",
				"success": "Three per post - the fence is going to be so sturdy!",
				"hint1": "Try handing out nails one at a time to each post."}
		]
	},
	{
		"id": "old-mac",
		"display_name": "Old Mac",
		"sprite_path": "res://assets/characters/world1/old-mac-idle.png",
		"tile": Vector2i(15, 19),
		"building": "",
		"item": "key",
		"container": "keyring basket",
		"intro": "Hmm. So you're the one everybody's talking about. This gate's been stuck since the storm.",
		"exercises": [
			{"phase": 1, "mode": "basket_in", "a": 4, "b": 5, "answer": 9,
				"setup": "I found 4 old keys in the shed, and just discovered 5 more in the workbench drawer. Drag them all into my keyring basket.",
				"success": "Nine keys - one of these has got to open the gate!",
				"hint1": "Count what's in the basket, then add the new keys."},
			{"phase": 2, "mode": "basket_out", "start": 11, "remove": 5, "answer": 6, "tray": "Rusty pile",
				"setup": "I've got 11 tools in my belt, but 5 are too rusty to use. Drag 5 out.",
				"success": "Six good tools left - enough to fix this old gate.",
				"hint1": "Take one tool out at a time and count what's left."},
			{"phase": 3, "mode": "text", "answer": 12, "grid": [4, 3],
				"setup": "The gate has 4 hinges, and each one needs 3 screws. How many screws do I need in total?",
				"success": "Twelve screws - the gate's going to swing perfectly!",
				"hint1": "Try adding 3 four times."},
			{"phase": 4, "mode": "text", "answer": 5, "grid": [4, 5], "groups": 4, "final": true,
				"setup": "I have 20 screws and want to split them evenly across the gate's 4 hinges for spares. How many screws per hinge?",
				"success": "Five spares per hinge - this gate isn't going anywhere for a long while! Welcome to Downtown.",
				"hint1": "Try handing out screws one at a time to each hinge."}
		]
	}
]

# Building footprints - layout from the latest user spec (30x20 grid, exact
# col/row per building). Sprites unchanged (current PixelLab pixel art).
# Buildings - exactly as exported from the in-game Map Editor
# (townville_map_export.json): the 4 originals at their edited positions plus
# the 2 placed in the editor (second Garden, second Clinic).
const BUILDINGS := [
	{"id": "garden", "sprite": "res://assets/buildings/world1/building-garden.png", "footprintCol": 27, "footprintRow": 13, "footprintW": 2, "footprintH": 2, "label": "GARDEN", "scale": 1.0, "flip_h": false},
	{"id": "clinic", "sprite": "res://assets/buildings/world1/building-animal-clinic.png", "footprintCol": 25, "footprintRow": 7, "footprintW": 2, "footprintH": 2, "label": "CLINIC", "scale": 1.5, "flip_h": false},
	{"id": "henhouse", "sprite": "res://assets/buildings/world1/building-henhouse.png", "footprintCol": 8, "footprintRow": 3, "footprintW": 2, "footprintH": 2, "label": "HENHOUSE", "scale": 1.0, "flip_h": true},
	{"id": "stable", "sprite": "res://assets/buildings/world1/building-stable.png", "footprintCol": 13, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "STABLE", "scale": 1.5, "flip_h": false},
	{"id": "barn", "sprite": "res://assets/buildings/world1/building-barn.png", "footprintCol": 23, "footprintRow": 2, "footprintW": 2, "footprintH": 2, "label": "BARN", "scale": 2.0, "flip_h": false},
	{"id": "coop", "sprite": "res://assets/buildings/world1/building-coop.png", "footprintCol": 2, "footprintRow": 7, "footprintW": 2, "footprintH": 2, "label": "COOP", "scale": 1.0, "flip_h": true},
]

# Painted in the in-game Map Editor and exported (townville_map_export.json,
# v2). Applied literally. EDITOR_DIRT = ground look ('.' = dirt),
# EDITOR_WALKABLE = collision ('.' = walkable). They are independent layers.
const EDITOR_DIRT := [
	"##############################",
	"##############################",
	"#############..##.#####..#####",
	"########..###..#####.##..#####",
	"########..####.########...####",
	"#..#...##.####.####..........#",
	"##....#....#.#.....######.####",
	"##...##.#######..########..###",
	"##...#.########..########..###",
	"##...##.#######..########.####",
	"##....#########..####.....####",
	"###############..####.########",
	"###############..##.#.########",
	"############.##..####.#####..#",
	"###############..............#",
	"###############.............##",
	"###########.###..########...##",
	"###############..#############",
	"###############..#############",
	"###############..#############",
]
const EDITOR_WALKABLE := [
	"#.##########.###....##########",
	"################.##...####...#",
	"################.##...####...#",
	"##########.#####.##########..#",
	"#.......##.##.#...##....#..###",
	"#.......##..#..#.............#",
	"##......................#.####",
	".###...#..#..#..........######",
	"####....##...#....###...######",
	"##.....##..#...............###",
	"###....###...#.#..##.....#.###",
	"#......###.###....##.........#",
	"#..........###....##....#..###",
	"#......#######...........#.###",
	"#........................#.###",
	"#........#.###...............#",
	"#..........#..................",
	"#.................######......",
	"#.................###########.",
	"################.#############",
]

var walkable: Array[Array] = []
var path_mask: Array[Array] = []
var NPCS: Array = []

func _init() -> void:
	# Deep-duplicate the template so each NPC dict is a fresh, WRITABLE copy -
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

	# Both layers come straight from the editor export. NPC tiles and building
	# footprints still block movement (the game needs that), nothing else is
	# derived or "corrected" here.
	for y in ROWS:
		for x in COLS:
			walkable[y][x] = EDITOR_WALKABLE[y][x] == "."
			path_mask[y][x] = EDITOR_DIRT[y][x] == "."
	for npc in NPCS:
		var t: Vector2i = npc.tile
		if _in_bounds(t):
			walkable[t.y][t.x] = false
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
		# Chebyshev distance 1: diagonals count, so an NPC standing beside the
		# path (EXACT-map-data standingTile) is reachable from the path tile.
		if max(delta.x, delta.y) == 1:
			return npc
	return {}

func interaction_text(tile: Vector2i) -> String:
	var npc := get_adjacent_npc(tile)
	return npc.get("intro", "") if npc else ""

# Per-NPC progress: npc_id -> next phase index (0..4). 4 == all done.
var npc_phase := {}

func get_phase(npc_id: String) -> int:
	return int(npc_phase.get(npc_id, 0))

func advance_phase(npc_id: String) -> void:
	npc_phase[npc_id] = min(get_phase(npc_id) + 1, 4)

func is_npc_complete(npc_id: String) -> bool:
	return get_phase(npc_id) >= 4

func get_current_exercise(npc: Dictionary) -> Dictionary:
	if npc.is_empty() or not npc.has("exercises"):
		return {}
	var idx := get_phase(npc.id)
	var list: Array = npc.exercises
	if idx >= list.size():
		return {}
	return list[idx]

# Kept for the test-suite / editor: returns the NPC's *current* exercise.
func get_adjacent_npc_quest(tile: Vector2i) -> Dictionary:
	return get_current_exercise(get_adjacent_npc(tile))

# --- Prop definitions per world ---

# World 1 props - exactly the 50 placed in the in-game Map Editor
# (townville_map_export.json). Edit them in the editor, not here.
const WORLD1_PROPS := [
	{"id": "flower-pot", "display_name": "Flower Pot", "sprite_path": "res://assets/scenery/world1/scenery-flower-pot.png", "tile": Vector2i(24, 12)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(18, 11)},
	{"id": "mailbox", "display_name": "Mailbox", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(19, 12)},
	{"id": "bench", "display_name": "Bench", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(20, 3)},
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(18, 8)},
	{"id": "stone", "display_name": "Stone", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(20, 8)},
	{"id": "well", "display_name": "Well", "sprite_path": "res://assets/scenery/world1/scenery-well.png", "tile": Vector2i(17, 2)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(5, 1)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(2, 1)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(1, 3)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(4, 3)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(3, 2)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(6, 2)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(7, 1)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(10, 1)},
	{"id": "tree", "display_name": "Tree", "sprite_path": "res://assets/scenery/world1/scenery-tree.png", "tile": Vector2i(0, 1)},
	{"id": "stone", "display_name": "Stone", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(9, 8)},
	{"id": "mailbox", "display_name": "Mailbox", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(11, 4)},
	{"id": "mailbox", "display_name": "Mailbox", "sprite_path": "res://assets/scenery/world1/scenery-mailbox.png", "tile": Vector2i(7, 9)},
	{"id": "bench", "display_name": "Bench", "sprite_path": "res://assets/scenery/world1/scenery-bench.png", "tile": Vector2i(12, 13)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(13, 8)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(11, 9)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(8, 13)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(9, 15)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(10, 13)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(11, 12)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(13, 10)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(11, 11)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(7, 11)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(7, 13)},
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(9, 10)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(9, 11)},
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(8, 9)},
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(13, 11)},
	{"id": "fountain", "display_name": "Fountain", "sprite_path": "res://assets/scenery/world1/scenery-fountain.png", "tile": Vector2i(11, 16)},
	{"id": "lamppost", "display_name": "Lamppost", "sprite_path": "res://assets/scenery/world1/scenery-lamppost.png", "tile": Vector2i(13, 15)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(26, 19)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(25, 18)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(24, 18)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(21, 17)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(18, 17)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(18, 19)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(28, 18)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(27, 10)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(28, 8)},
	{"id": "bush", "display_name": "Bush", "sprite_path": "res://assets/scenery/world1/scenery-bush.png", "tile": Vector2i(29, 8)},
	{"id": "flower-red", "display_name": "Red Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-red.png", "tile": Vector2i(28, 10)},
	{"id": "flower-yellow", "display_name": "Yellow Flower", "sprite_path": "res://assets/scenery/world1/scenery-flower-yellow.png", "tile": Vector2i(19, 18)},
	{"id": "stone", "display_name": "Stone", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(22, 18)},
	{"id": "stone", "display_name": "Stone", "sprite_path": "res://assets/scenery/world1/scenery-stone.png", "tile": Vector2i(10, 7)},
]

# Fine-detail clutter - repositioned for the new 30x20 layout, each entry
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
# - purely flat, rendered just above the tilemap, always sit ON walkable path
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
