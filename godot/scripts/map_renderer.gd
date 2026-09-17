extends Node2D

var world

func setup(world_data) -> void:
	world = world_data
	queue_redraw()

func _draw() -> void:
	if world == null:
		return
	var tile_size: int = world.TILE_SIZE
	draw_rect(Rect2(Vector2.ZERO, Vector2(world.world_size_px())), Color("#79ad55"))
	for y in world.ROWS:
		for x in world.COLS:
			var tile := Vector2i(x, y)
			var rect := Rect2(x * tile_size, y * tile_size, tile_size, tile_size)
			if world.is_walkable(tile):
				draw_rect(rect, Color("#c9a66b"))
				draw_circle(rect.get_center(), 3.0, Color("#e0c38a"))
			else:
				var shade := Color("#6fa24e") if (x + y) % 2 == 0 else Color("#76aa52")
				draw_rect(rect, shade)
				if (x * 7 + y * 11) % 13 == 0:
					draw_circle(rect.get_center() + Vector2(10, -8), 4.0, Color("#f4d35e"))
			draw_rect(rect, Color(0.1, 0.2, 0.08, 0.10), false, 1.0)
	# A compact farm border makes the exact 1536x1152 extent visible.
	draw_rect(Rect2(Vector2.ZERO, Vector2(world.world_size_px())), Color("#493d2b"), false, 6.0)
