class_name EditorCamera
extends Camera2D

const MIN_ZOOM := 0.25
const MAX_ZOOM := 4.0
const ZOOM_STEP := 0.1

var _zoom_level: float = 1.0

func _init() -> void:
	zoom = Vector2.ONE * _zoom_level
	position_smoothing_enabled = true
	position_smoothing_speed = 10.0

## Pan the camera by a pixel delta (already in world space)
func pan(delta: Vector2) -> void:
	position += delta

## Zoom toward a screen point
func zoom_at(screen_point: Vector2, factor: float) -> void:
	var world_before := get_global_mouse_position()
	_zoom_level = clamp(_zoom_level * factor, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2.ONE * _zoom_level
	var world_after := get_global_mouse_position()
	position += world_before - world_after

## Set zoom level directly (clamped)
func set_zoom_level(level: float) -> void:
	_zoom_level = clamp(level, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2.ONE * _zoom_level

## Reset view to origin with default zoom
func reset_view() -> void:
	position = Vector2.ZERO
	set_zoom_level(1.0)

func _unhandled_input(event: InputEvent) -> void:
	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(event.position, 1.0 + ZOOM_STEP)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(event.position, 1.0 - ZOOM_STEP)
			get_viewport().set_input_as_handled()
		# Middle-mouse or right-mouse drag to pan
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				set_meta("_panning", true)
			else:
				set_meta("_panning", false)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if has_meta("_panning") and get_meta("_panning"):
			# Pan inversely to motion (drag the world)
			pan(-event.relative / zoom.x)
			get_viewport().set_input_as_handled()
