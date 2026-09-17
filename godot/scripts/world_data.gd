class_name WorldData
extends RefCounted

const TILE_SIZE := 48
const COLS := 32
const ROWS := 24
const SPAWN := Vector2i(15, 8)
const NPC := {
	"id": "vera",
	"display_name": "Dra. Vera",
	"tile": Vector2i(21, 12),
	"dialogue": "Dra. Vera: Bem-vindo a Townville! A clínica cuida de todos os animais."
}

var walkable: Array[Array] = []

func _init() -> void:
	for y in ROWS:
		var row: Array[bool] = []
		row.resize(COLS)
		row.fill(false)
		walkable.append(row)
	paint_walkable(Rect2i(3, 7, 26, 2))
	paint_walkable(Rect2i(5, 5, 2, 3))
	paint_walkable(Rect2i(10, 6, 3, 2))
	paint_walkable(Rect2i(26, 5, 2, 3))
	paint_walkable(Rect2i(14, 7, 3, 17))
	paint_walkable(Rect2i(7, 14, 9, 2))
	paint_walkable(Rect2i(7, 15, 2, 2))
	paint_walkable(Rect2i(15, 11, 6, 2))
	paint_walkable(Rect2i(20, 12, 2, 2))
	paint_walkable(Rect2i(15, 17, 13, 2))
	paint_walkable(Rect2i(26, 16, 2, 2))
	paint_walkable(Rect2i(12, 19, 6, 2))
	paint_walkable(Rect2i(14, 21, 3, 3))
	# Dynamic occupants are also projected into this authoritative matrix.
	walkable[NPC.tile.y][NPC.tile.x] = false

func paint_walkable(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			walkable[y][x] = true

func world_size_px() -> Vector2i:
	return Vector2i(COLS * TILE_SIZE, ROWS * TILE_SIZE)

func camera_limits() -> Rect2i:
	return Rect2i(Vector2i.ZERO, world_size_px())

func is_walkable(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < COLS and tile.y >= 0 and tile.y < ROWS and walkable[tile.y][tile.x]

func is_npc_near(tile: Vector2i) -> bool:
	var delta: Vector2i = (tile - NPC.tile).abs()
	return delta.x + delta.y <= 1

func interaction_text(tile: Vector2i) -> String:
	return NPC.dialogue if is_npc_near(tile) else ""
