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

	add_farm_landmarks()
	add_npc()
	player = PlayerScript.new()
	player.name = "Player"
	player.z_index = 20
	add_child(player)
	player.setup(world)
	add_hud()

func add_farm_landmarks() -> void:
	var title := Label.new()
	title.text = "WORLD 1 · FAZENDA TOWNVILLE"
	title.position = Vector2(72, 40)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#fff2bf"))
	title.add_theme_color_override("font_shadow_color", Color("#24351d"))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)
	for landmark in [
		[Vector2(4, 3), Vector2(3, 3), Color("#a85b46"), "GALINHEIRO"],
		[Vector2(12, 3), Vector2(3, 3), Color("#8d6e63"), "ESTÁBULO"],
		[Vector2(24, 2), Vector2(4, 3), Color("#b4493f"), "CELEIRO"],
		[Vector2(18, 9), Vector2(3, 2), Color("#d7e7ef"), "CLÍNICA"]
	]:
		var panel := ColorRect.new()
		panel.position = landmark[0] * world.TILE_SIZE
		panel.size = landmark[1] * world.TILE_SIZE
		panel.color = landmark[2]
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.z_index = 2
		add_child(panel)
		var label := Label.new()
		label.text = landmark[3]
		label.position = panel.position + Vector2(8, panel.size.y * 0.5 - 10)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.z_index = 3
		add_child(label)

func add_npc() -> void:
	var npc := Sprite2D.new()
	npc.name = "VeraNPC"
	npc.texture = load("res://assets/characters/world1/vera-idle.png")
	npc.position = Vector2(world.NPC.tile * world.TILE_SIZE) + Vector2.ONE * world.TILE_SIZE * 0.5
	npc.position.y -= 12
	npc.scale = Vector2.ONE * 1.4
	npc.z_index = 15
	add_child(npc)
	var name_label := Label.new()
	name_label.text = "Dra. Vera"
	name_label.position = npc.position + Vector2(-38, -58)
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
	var nearby: bool = world.is_npc_near(player.current_tile())
	prompt_label.text = "[E] Falar com Dra. Vera" if nearby else ""
	if not nearby:
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
