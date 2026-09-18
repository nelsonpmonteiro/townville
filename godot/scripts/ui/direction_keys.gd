extends Control
## Font-independent directional-key diagram for the onboarding card.
## The arrows are drawn as vectors so the Web build never depends on Unicode glyphs.

const KEY_SIZE := Vector2(48, 46)
const FILL := Color("#29231e")
const BORDER := Color("#c9a36b")
const ARROW := Color("#f5e9cf")

func _ready() -> void:
	custom_minimum_size = Vector2(210, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _draw() -> void:
	_draw_key(Vector2(81, 4), Vector2.UP)
	_draw_key(Vector2(27, 58), Vector2.LEFT)
	_draw_key(Vector2(81, 58), Vector2.DOWN)
	_draw_key(Vector2(135, 58), Vector2.RIGHT)

func _draw_key(position: Vector2, direction: Vector2) -> void:
	var rect := Rect2(position, KEY_SIZE)
	draw_style_box(_key_style(), rect)
	var center := rect.get_center()
	var tip := center + direction * 12.0
	var base := center - direction * 9.0
	var side := Vector2(-direction.y, direction.x)
	draw_line(base, tip, ARROW, 4.0, true)
	draw_line(tip, tip - direction * 8.0 + side * 7.0, ARROW, 4.0, true)
	draw_line(tip, tip - direction * 8.0 - side * 7.0, ARROW, 4.0, true)

func _key_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 3
	return style
