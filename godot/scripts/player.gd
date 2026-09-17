class_name TownvillePlayer
extends Node2D

const MovementScript = preload("res://scripts/player_movement.gd")

var world
var movement = MovementScript.new()
var sprite: AnimatedSprite2D
var facing := "front"

func setup(world_data) -> void:
	world = world_data
	position = Vector2(world.SPAWN * world.TILE_SIZE) + Vector2.ONE * world.TILE_SIZE * 0.5
	build_sprite()
	build_camera()

func build_sprite() -> void:
	# Anchored shadow (art brief §5), drawn first (below the character sprite).
	var shadow := Sprite2D.new()
	shadow.texture = load("res://assets/scenery/world1/clutter/shadow-blob.png") as Texture2D
	if shadow.texture != null:
		shadow.position = Vector2(2, 6)
		shadow.scale = Vector2.ONE * 1.1
		shadow.z_index = -1
		shadow.modulate.a = 0.45
		add_child(shadow)

	sprite = AnimatedSprite2D.new()
	sprite.name = "StableAnimatedSprite"
	sprite.position.y = -16
	sprite.scale = Vector2.ONE * 1.35
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in ["front", "back", "left", "right"]:
		var idle_name: String = "idle_" + direction
		var walk_name: String = "walk_" + direction
		frames.add_animation(idle_name)
		frames.add_frame(idle_name, load("res://assets/player/boy-%s.png" % direction))
		frames.add_animation(walk_name)
		frames.set_animation_speed(walk_name, 10.0)
		frames.set_animation_loop(walk_name, true)
		for index in 8:
			frames.add_frame(walk_name, load("res://assets/player/walk/boy-walk-%s-%d.png" % [direction, index]))
	sprite.sprite_frames = frames
	sprite.play("idle_front")
	add_child(sprite)

func build_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "PlayerCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	var limits: Rect2i = world.camera_limits()
	camera.limit_left = limits.position.x
	camera.limit_top = limits.position.y
	camera.limit_right = limits.end.x
	camera.limit_bottom = limits.end.y
	camera.limit_smoothed = true
	add_child(camera)

func _physics_process(delta: float) -> void:
	if world == null:
		return
	if get_parent() and get_parent().has_method("is_map_editor_active") and get_parent().is_map_editor_active():
		return
	var direction := Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if Input.is_key_pressed(KEY_D): direction.x += 1.0
	if Input.is_key_pressed(KEY_A): direction.x -= 1.0
	if Input.is_key_pressed(KEY_S): direction.y += 1.0
	if Input.is_key_pressed(KEY_W): direction.y -= 1.0
	direction = direction.limit_length(1.0)
	var horizontal := movement.next_position(position, Vector2(direction.x, 0), delta, world)
	position = movement.next_position(horizontal, Vector2(0, direction.y), delta, world)
	update_animation(direction)

func update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			facing = "right" if direction.x > 0 else "left"
		else:
			facing = "front" if direction.y > 0 else "back"
		sprite.play("walk_" + facing)
	else:
		sprite.play("idle_" + facing)

func current_tile() -> Vector2i:
	return Vector2i(floori(position.x / world.TILE_SIZE), floori(position.y / world.TILE_SIZE))
