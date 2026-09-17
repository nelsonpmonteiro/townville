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

# Quest UI
var quest_panel: PanelContainer
var quest_title: Label
var quest_problem: Label
var quest_visual: HBoxContainer
var quest_input: LineEdit
var quest_submit: Button
var quest_feedback: Label
var quest_hint: Label
var quest_close: Button

# Quest state
var quest_state = "idle"  # idle dialogue quest_active success complete
var active_quest = {}
var active_npc = {}
var attempt_count = 0
var max_attempts = 3

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
	add_quest_ui()

func add_buildings() -> void:
	for b in world.BUILDINGS:
		var texture := load(b.sprite) as Texture2D
		var building_scale: float = b.get("scale", 1.0)
		var flip_h: bool = b.get("flip_h", false)
		var fp_center: Vector2 = Vector2(b.footprintCol + b.footprintW / 2.0, b.footprintRow + b.footprintH / 2.0) * world.TILE_SIZE
		var fp_bottom: float = (b.footprintRow + b.footprintH) * world.TILE_SIZE
		var scaled_height: float = texture.get_height() * building_scale if texture != null else 0.0

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
		sprite.position = Vector2(fp_center.x, fp_bottom - scaled_height / 2.0)
		sprite.z_index = 5
		add_child(sprite)
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
	instructions.text = "Move: WASD / Arrows  •  Interact: E or Space"
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

func add_quest_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "QuestUI"
	add_child(layer)

	quest_panel = PanelContainer.new()
	quest_panel.position = Vector2(240, 180)
	quest_panel.size = Vector2(480, 420)
	quest_panel.visible = false
	layer.add_child(quest_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	quest_panel.add_child(vbox)

	quest_title = Label.new()
	quest_title.add_theme_font_size_override("font_size", 22)
	quest_title.add_theme_color_override("font_color", Color("#fff2a8"))
	quest_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(quest_title)

	quest_problem = Label.new()
	quest_problem.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_problem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_problem.add_theme_font_size_override("font_size", 18)
	quest_problem.add_theme_color_override("font_color", Color.WHITE)
	quest_problem.custom_minimum_size = Vector2(440, 60)
	vbox.add_child(quest_problem)

	quest_visual = HBoxContainer.new()
	quest_visual.alignment = BoxContainer.ALIGNMENT_CENTER
	quest_visual.add_theme_constant_override("separation", 12)
	vbox.add_child(quest_visual)

	var input_row := HBoxContainer.new()
	input_row.alignment = BoxContainer.ALIGNMENT_CENTER
	input_row.add_theme_constant_override("separation", 8)
	vbox.add_child(input_row)

	quest_input = LineEdit.new()
	quest_input.placeholder_text = "Type your answer..."
	quest_input.custom_minimum_size = Vector2(160, 36)
	quest_input.max_length = 6
	input_row.add_child(quest_input)

	quest_submit = Button.new()
	quest_submit.text = "Submit"
	quest_submit.custom_minimum_size = Vector2(80, 36)
	input_row.add_child(quest_submit)
	quest_submit.pressed.connect(_on_quest_submit)

	quest_feedback = Label.new()
	quest_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_feedback.add_theme_font_size_override("font_size", 16)
	quest_feedback.visible = false
	vbox.add_child(quest_feedback)

	quest_hint = Label.new()
	quest_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_hint.add_theme_color_override("font_color", Color("#a0c0ff"))
	quest_hint.visible = false
	quest_hint.custom_minimum_size = Vector2(440, 30)
	vbox.add_child(quest_hint)

	quest_close = Button.new()
	quest_close.text = "Close"
	quest_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(quest_close)
	quest_close.pressed.connect(_close_quest)

func _process(_delta: float) -> void:
	if player == null:
		return
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	var nearby: Dictionary = world.get_adjacent_npc(player.current_tile())
	if nearby and quest_state == "idle":
		prompt_label.text = "[E] Talk to " + nearby.display_name
	elif nearby and quest_state == "dialogue":
		prompt_label.text = "[E] Start Quest"
	else:
		prompt_label.text = ""
		if quest_state == "idle":
			dialogue_label.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and (event.keycode == KEY_E or event.keycode == KEY_SPACE):
		if quest_state == "quest_active" or quest_state == "success":
			return
		if quest_state == "idle":
			var nearby: Dictionary = world.get_adjacent_npc(player.current_tile())
			if nearby:
				dialogue_label.text = nearby.get("dialogue", "")
				dialogue_label.visible = true
				active_npc = nearby
				quest_state = "dialogue"
				prompt_label.text = "[E] Start Quest"
				get_viewport().set_input_as_handled()
		elif quest_state == "dialogue":
			_start_quest()
			get_viewport().set_input_as_handled()

func _start_quest() -> void:
	if active_npc.has("quest"):
		active_quest = active_npc.quest
	else:
		active_quest = world.get_adjacent_npc_quest(player.current_tile())
	if active_quest.is_empty():
		quest_state = "idle"
		return

	attempt_count = 0
	quest_state = "quest_active"
	quest_panel.visible = true
	quest_title.text = active_npc.display_name + "  —  " + active_npc.get("skill", "")
	quest_problem.text = active_quest.get("problem", "")
	quest_feedback.visible = false
	quest_hint.visible = false
	_build_quest_visual()
	quest_input.text = ""
	quest_input.grab_focus()

func _build_quest_visual() -> void:
	for child in quest_visual.get_children():
		child.queue_free()

	var qtype: String = active_quest.get("type", "numberpad")
	var visual: Dictionary = active_quest.get("visual", {})

	if qtype == "compare":
		# Two columns with repeated sprites
		var va := _make_group_box("Pile A", visual.get("icon_a", ""), visual.get("count_a", 1))
		quest_visual.add_child(va)
		var vb := _make_group_box("Pile B", visual.get("icon_b", ""), visual.get("count_b", 1))
		quest_visual.add_child(vb)
	elif qtype == "compare_length":
		var va := _make_group_box("A", visual.get("icon_a", ""), 1)
		quest_visual.add_child(va)
		var vb := _make_group_box("B", visual.get("icon_b", ""), 1)
		quest_visual.add_child(vb)
	elif qtype == "numberpad":
		var icon_path: String = visual.get("icon", "")
		var count: int = visual.get("count", 1)
		for i in count:
			if not icon_path.is_empty():
				var tex = load(icon_path) as Texture2D
				if tex:
					var s := Sprite2D.new()
					s.texture = tex
					s.scale = Vector2.ONE * 0.8
					quest_visual.add_child(s)

func _make_group_box(title: String, icon_path: String, count: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_l := Label.new()
	title_l.text = title
	title_l.add_theme_color_override("font_color", Color("#fff2a8"))
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_l)
	for i in count:
		if not icon_path.is_empty():
			var tex = load(icon_path) as Texture2D
			if tex:
				var s := Sprite2D.new()
				s.texture = tex
				s.scale = Vector2.ONE * 0.7
				box.add_child(s)
	return box

func _on_quest_submit() -> void:
	var answer = quest_input.text.strip_edges()
	if answer.is_empty():
		return

	var correct = active_quest.get("correct_answer", "")
	var correct_str: String = str(correct).to_lower()
	var answer_lower: String = answer.to_lower()

	# Check compare_length (options: Sunflower/Carrot or A/B)
	var qtype: String = active_quest.get("type", "numberpad")
	if qtype == "compare_length":
		var opts = active_quest.get("options", [])
		if opts.size() >= 2:
			if answer == "A" or answer == "1":
				answer_lower = opts[0].to_lower()
			elif answer == "B" or answer == "2":
				answer_lower = opts[1].to_lower()

	if answer_lower == correct_str:
		_on_correct()
	else:
		attempt_count += 1
		_on_wrong()

func _on_correct() -> void:
	quest_state = "success"
	quest_input.editable = false
	quest_submit.disabled = true
	quest_feedback.visible = true
	quest_feedback.add_theme_color_override("font_color", Color("#7fff7f"))
	var success_text: String = active_quest.get("success", "Correct!")
	quest_feedback.text = success_text.replace("{answer}", quest_input.text)
	quest_close.text = "Continue"

func _on_wrong() -> void:
	quest_feedback.visible = true
	quest_feedback.add_theme_color_override("font_color", Color("#ff7f7f"))
	quest_feedback.text = active_quest.get("failure", "Not quite, try again.")

	if attempt_count >= max_attempts:
		quest_hint.visible = true
		var hints: Array = active_quest.get("hints", [])
		if hints.size() > 0:
			quest_hint.text = "Hint: " + hints[min(attempt_count - 1, hints.size() - 1)]
		quest_close.text = "Try Again"
	else:
		quest_hint.visible = false
		quest_close.text = "Retry"

func _close_quest() -> void:
	if quest_state == "success":
		# Show completion text
		dialogue_label.text = active_quest.get("complete", "Great job!")
		dialogue_label.visible = true
		quest_panel.visible = false
		quest_state = "idle"
		active_npc = {}
		active_quest = {}
		quest_input.editable = true
		quest_submit.disabled = false
	else:
		# Retry or close
		quest_panel.visible = false
		quest_state = "idle"
		dialogue_label.visible = false
		active_npc = {}
		active_quest = {}
		quest_input.editable = true
		quest_submit.disabled = false

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
