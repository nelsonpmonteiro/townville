extends Node2D

const WorldDataScript = preload("res://scripts/world_data.gd")
const MapRendererScript = preload("res://scripts/map_renderer.gd")
const PlayerScript = preload("res://scripts/player.gd")

var world
var player
var prompt_label: Label
var dialogue_label: Label
var fps_label: Label
var built := false

func _ready() -> void:
	build_world()
	if "--capture" in OS.get_cmdline_user_args():
		capture_after_render.call_deferred()

func build_world() -> void:
	if built:
		return
	built = true
	world = WorldDataScript.new()

	var map = MapRendererScript.new()
	map.name = "Compact32x24Map"
	map.setup(world)
	add_child(map)

	add_buildings()
	add_npcs()
	player = PlayerScript.new()
	player.name = "Player"
	player.z_index = 20
	add_child(player)
	player.setup(world)
	add_hud()

func add_buildings() -> void:
	# Per-building scale and horizontal flip, set individually per user spec:
	# henhouse/coop keep their size but flip horizontally, stable is 1.5x,
	# barn/clinic are 2x, garden stays default. Footprint/collision (2x2
	# tiles) is unchanged — sprite is bottom-anchored so its doorway still
	# sits on the footprint's bottom edge regardless of scale.
	for b in world.BUILDINGS:
		var texture := load(b.sprite) as Texture2D
		var building_scale: float = b.get("scale", 1.0)
		var flip_h: bool = b.get("flip_h", false)
		var fp_center: Vector2 = Vector2(b.footprintCol + b.footprintW / 2.0, b.footprintRow + b.footprintH / 2.0) * world.TILE_SIZE
		var fp_bottom: float = (b.footprintRow + b.footprintH) * world.TILE_SIZE
		var scaled_height: float = texture.get_height() * building_scale if texture != null else 0.0

		# Anchored shadow (art brief §5): larger scale for buildings so the blob
		# reads under the whole footprint instead of floating.
		var shadow := Sprite2D.new()
		shadow.texture = load(world.SHADOW_BLOB_SPRITE) as Texture2D
		if shadow.texture != null:
			shadow.position = Vector2(fp_center.x + 6, fp_bottom - 6)
			shadow.scale = Vector2(b.footprintW, b.footprintH) * (0.9 + building_scale * 0.35)
			shadow.z_index = 4
			shadow.modulate.a = 0.4
			add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "Building_" + b.id
		sprite.texture = texture
		sprite.scale = Vector2(building_scale * (-1.0 if flip_h else 1.0), building_scale)
		# Center horizontally in footprint, bottom-align to the footprint's
		# bottom edge (with default centered=true, offset the center up by
		# half the scaled height so the sprite's base touches the doorway).
		sprite.position = Vector2(fp_center.x, fp_bottom - scaled_height / 2.0)
		sprite.z_index = 5
		add_child(sprite)
		# Building label
		var label := Label.new()
		label.text = b.label
		label.position = sprite.position + Vector2(-40, -scaled_height / 2.0 - 18)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.z_index = 6
		add_child(label)

func add_npcs() -> void:
	for npc in world.NPCS:
		var npc_pos: Vector2 = Vector2(npc.tile * world.TILE_SIZE) + Vector2.ONE * world.TILE_SIZE * 0.5

		# Anchored shadow (art brief §5) so NPCs read as standing on the ground.
		var shadow := Sprite2D.new()
		shadow.texture = load(world.SHADOW_BLOB_SPRITE) as Texture2D
		if shadow.texture != null:
			shadow.position = npc_pos + Vector2(4, 14)
			shadow.scale = Vector2.ONE * 1.2
			shadow.z_index = 14
			shadow.modulate.a = 0.4
			add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "NPC_" + npc.id
		if npc.has("sprite_path"):
			sprite.texture = load(npc.sprite_path)
		sprite.position = npc_pos
		sprite.position.y -= 12
		sprite.scale = Vector2.ONE * 1.4
		sprite.z_index = 15
		add_child(sprite)
		var name_label := Label.new()
		name_label.text = npc.display_name
		name_label.position = sprite.position + Vector2(-38, -58)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		name_label.add_theme_constant_override("shadow_offset_x", 1)
		name_label.add_theme_constant_override("shadow_offset_y", 1)
		name_label.z_index = 16
		add_child(name_label)

func add_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var instructions := Label.new()
	instructions.position = Vector2(18, 16)
	instructions.text = "Mover: WASD / setas  •  Interagir: E ou Espaço"
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	instructions.add_theme_color_override("font_shadow_color", Color.BLACK)
	instructions.add_theme_constant_override("shadow_offset_x", 2)
	instructions.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(instructions)
	fps_label = Label.new()
	fps_label.position = Vector2(18, 44)
	fps_label.add_theme_color_override("font_color", Color("#d8ffd0"))
	layer.add_child(fps_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(350, 470)
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.add_theme_color_override("font_color", Color("#fff2a8"))
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 2)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(prompt_label)
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(130, 395)
	dialogue_label.size = Vector2(700, 64)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_font_size_override("font_size", 18)
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	dialogue_label.add_theme_constant_override("shadow_offset_x", 2)
	dialogue_label.add_theme_constant_override("shadow_offset_y", 2)
	dialogue_label.visible = false
	layer.add_child(dialogue_label)

func _process(_delta: float) -> void:
	if player == null:
		return
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	var nearby: Dictionary = world.get_adjacent_npc(player.current_tile())
	if nearby:
		prompt_label.text = "[E] Falar com " + nearby.display_name
	else:
		prompt_label.text = ""
		dialogue_label.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and (event.keycode == KEY_E or event.keycode == KEY_SPACE):
		var text: String = world.interaction_text(player.current_tile())
		if not text.is_empty():
			dialogue_label.text = text
			dialogue_label.visible = true
			get_viewport().set_input_as_handled()

func capture_after_render() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var texture := get_viewport().get_texture()
	if texture == null:
		push_warning("Screenshot unavailable with the active headless renderer")
		get_tree().quit(2)
		return
	var image := texture.get_image()
	if image == null:
		push_warning("Screenshot image unavailable with the active renderer")
		get_tree().quit(2)
		return
	var error := image.save_png("res://artifacts/townville-godot-poc.png")
	print("SCREENSHOT_RESULT: ", error, " res://artifacts/townville-godot-poc.png")
	get_tree().quit(0 if error == OK else 1)
