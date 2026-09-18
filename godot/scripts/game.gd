extends Node2D

const WorldDataScript = preload("res://scripts/world_data.gd")
const MapRendererScript = preload("res://scripts/map_renderer.gd")
const PlayerScript = preload("res://scripts/player.gd")
const MapEditorScript = preload("res://scripts/editor/simple_map_editor.gd")
const InteractionFlowScript = preload("res://scripts/ui/interaction_flow.gd")
const OnboardingScript = preload("res://scripts/ui/onboarding.gd")

var world
var player
var prompt_label: Label
var dialogue_label: Label
var fps_label: Label
var built := false
var map_editor: Node2D
var map_renderer_node: Node2D
var hud_layer: CanvasLayer

# Interaction flow (dialogue → exercise → feedback), one screen at a time
var flow: CanvasLayer
var building_progress := {}  # building_id -> Label overlay
var onboarding: CanvasLayer

func _ready() -> void:
	build_world()
	_install_js_bridge()
	_maybe_start_onboarding()
	if "--capture" in OS.get_cmdline_user_args():
		capture_after_render.call_deferred()

# Web-only introspection hook used by scripts/web-perf-probe.cjs to verify the
# game from a real browser (FPS, player tile, quest state, editor mode, grid).
# Godot's JS callbacks can't return values, so we publish state into
# window.__townville_state each frame via eval. No-op on non-web platforms.
var _js_bridge_on := false
var _js_frame := 0

func _install_js_bridge() -> void:
	_js_bridge_on = OS.has_feature("web")

func _publish_js_state() -> void:
	if not _js_bridge_on:
		return
	_js_frame += 1
	if _js_frame % 6 != 0:
		return
	var t: Vector2i = player.current_tile() if player else Vector2i(-1, -1)
	var grid_visible := false
	if map_editor and map_editor.grid_lines:
		grid_visible = map_editor.grid_lines.visible
	var d := {
		"fps": Engine.get_frames_per_second(),
		"tile": [t.x, t.y],
		"edit_mode": map_editor.edit_mode if map_editor else false,
		"grid_visible": grid_visible,
		"flow": flow.debug_state() if flow else {},
		"phases": world.npc_phase if world else {},
		"npcs": _npc_tiles(),
		"walkable": _walkable_rows(),
		"onboarding": onboarding.debug_state() if onboarding else {},
		"seen_onboarding": OnboardingScript.has_seen_onboarding(),
	}
	JavaScriptBridge.eval("window.__townville_state=" + JSON.stringify(d) + ";", true)
	# Command channel for the browser probe: window.__townville_cmd = "..."
	var cmd = JavaScriptBridge.eval("(function(){var c=window.__townville_cmd||'';window.__townville_cmd='';return c;})()", true)
	if cmd is String and not cmd.is_empty():
		_run_probe_cmd(cmd)

func _run_probe_cmd(cmd: String) -> void:
	var parts := cmd.split(" ")
	match parts[0]:
		"rects":
			# publish screen rects of the drag targets so the probe can do REAL mouse drags
			var r := {}
			if flow and flow.state == flow.State.EXERCISE:
				var src: HBoxContainer = flow.source_items if flow.exercise.mode == "basket_in" else flow.basket_items
				var i := 0
				for ch in src.get_children():
					if ch.get_script() == flow.DragItemScript:
						r["item%d" % i] = _rect(ch); i += 1
				r["basket"] = _rect(flow.basket_zone)
				r["tray"] = _rect(flow.tray_zone)
				r["done"] = _rect(flow.done_btn)
				r["input"] = _rect(flow.answer_input)
				r["submit"] = _rect(flow.submit_btn)
			if flow and flow.state == flow.State.DIALOGUE:
				r["dialogue_box"] = _rect(flow.dialogue_screen.get_node("DialogueBox"))
			JavaScriptBridge.eval("window.__townville_rects=" + JSON.stringify(r) + ";", true)
		"drag_one":
			flow.debug_drag_one(parts[1])
		"done":
			flow.debug_done()
		"submit":
			flow.debug_submit(parts[1])
		"advance":
			flow.advance_dialogue()
		"onboard_reset":
			OnboardingScript.reset_save()

func _rect(c: Control) -> Array:
	var g := c.get_global_rect()
	return [g.position.x, g.position.y, g.size.x, g.size.y]

func build_world() -> void:
	if built:
		return
	built = true
	world = WorldDataScript.new()
	# Depth: buildings, NPCs and the player share z=10 and are Y-sorted by
	# their ground anchor (building = footprint bottom, characters = tile
	# center). Walking on the tile ABOVE a building puts the player behind
	# its roof; walking below puts them in front. Ground/props stay below.
	y_sort_enabled = true

	var map = MapRendererScript.new()
	map.name = "Compact32x24Map"
	map.setup(world)
	add_child(map)
	map_renderer_node = map

	add_buildings()
	add_npcs()
	player = PlayerScript.new()
	player.name = "Player"
	player.z_index = 10
	add_child(player)
	player.setup(world)
	add_hud()
	add_interaction_flow()
	add_map_editor()

func add_map_editor() -> void:
	map_editor = MapEditorScript.new()
	map_editor.name = "MapEditor"
	map_editor.z_index = 50
	map_editor.world = world
	map_editor.map_renderer = map_renderer_node
	add_child(map_editor)
	# Reapply any previously saved edits (new props/buildings/npcs +
	# terrain/collision changes) so they survive a restart — Save alone
	# only wrote the file, nothing reloaded it before this.
	map_editor.load_map("user://map.json")

func is_map_editor_active() -> bool:
	return map_editor != null and map_editor.edit_mode

func add_buildings() -> void:
	for b in world.BUILDINGS:
		var texture := load(b.sprite) as Texture2D
		# EXACT-map-data renderRule: height = render_h tiles, aspect preserved.
		var building_scale: float = b.get("scale", 1.0)
		if b.has("render_h") and texture != null and texture.get_height() > 0:
			building_scale = (float(b.render_h) * world.TILE_SIZE) / float(texture.get_height())
		var flip_h: bool = b.get("flip_h", false)
		var fp_center: Vector2 = Vector2(b.footprintCol + b.footprintW / 2.0, b.footprintRow + b.footprintH / 2.0) * world.TILE_SIZE
		var fp_bottom: float = (b.footprintRow + b.footprintH) * world.TILE_SIZE
		var scaled_height: float = texture.get_height() * building_scale if texture != null else 0.0

		var container := Node2D.new()
		container.name = "BuildingGroup_" + b.id
		container.z_index = 10
		container.position = Vector2(fp_center.x, fp_bottom)
		container.set_meta("building_id", b.id)
		container.set_meta("footprint_col", b.footprintCol)
		container.set_meta("footprint_row", b.footprintRow)
		container.set_meta("footprint_w", b.footprintW)
		container.set_meta("footprint_h", b.footprintH)
		add_child(container)

		var shadow := Sprite2D.new()
		shadow.texture = load(world.SHADOW_BLOB_SPRITE) as Texture2D
		if shadow.texture != null:
			shadow.position = Vector2(6, -6)
			shadow.scale = Vector2(b.footprintW, b.footprintH) * (0.9 + building_scale * 0.35)
			shadow.z_index = 4
			shadow.modulate.a = 0.4
			container.add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "Building_" + b.id
		sprite.texture = texture
		sprite.scale = Vector2(building_scale * (-1.0 if flip_h else 1.0), building_scale)
		sprite.position = Vector2(0, -scaled_height / 2.0)
		sprite.z_index = 5
		container.add_child(sprite)
		var label := Label.new()
		label.text = b.label
		label.position = sprite.position + Vector2(-40, -scaled_height / 2.0 - 18)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.z_index = 6
		container.add_child(label)

func add_npcs() -> void:
	for npc in world.NPCS:
		var npc_pos: Vector2 = Vector2(npc.tile * world.TILE_SIZE) + Vector2.ONE * world.TILE_SIZE * 0.5

		var container := Node2D.new()
		container.name = "NPCGroup_" + npc.id
		container.z_index = 10
		container.position = npc_pos
		container.set_meta("npc_id", npc.id)
		container.set_meta("tile_x", npc.tile.x)
		container.set_meta("tile_y", npc.tile.y)
		add_child(container)

		var shadow := Sprite2D.new()
		shadow.texture = load(world.SHADOW_BLOB_SPRITE) as Texture2D
		if shadow.texture != null:
			shadow.position = Vector2(4, 14)
			shadow.scale = Vector2.ONE * 1.2
			shadow.z_index = 14
			shadow.modulate.a = 0.4
			container.add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "NPC_" + npc.id
		if npc.has("sprite_path"):
			sprite.texture = load(npc.sprite_path)
		# npcRenderRule: height = 1.4 tiles, centered on the tile, feet on the tile's bottom edge.
		var npc_scale := 1.4
		if sprite.texture != null and sprite.texture.get_height() > 0:
			npc_scale = (1.4 * world.TILE_SIZE) / float(sprite.texture.get_height())
		sprite.scale = Vector2.ONE * npc_scale
		var npc_h: float = (sprite.texture.get_height() * npc_scale) if sprite.texture != null else world.TILE_SIZE * 1.4
		sprite.position = Vector2(0, world.TILE_SIZE * 0.5 - npc_h / 2.0)
		sprite.z_index = 15
		container.add_child(sprite)
		var name_label := Label.new()
		name_label.text = npc.display_name
		name_label.position = sprite.position + Vector2(-38, -58)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		name_label.add_theme_constant_override("shadow_offset_x", 1)
		name_label.add_theme_constant_override("shadow_offset_y", 1)
		name_label.z_index = 16
		container.add_child(name_label)

func add_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	hud_layer = layer
	var instructions := Label.new()
	instructions.position = Vector2(18, 16)
	instructions.text = "Move: WASD / Arrows  |  Interact: E or Space"
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
	dialogue_label.position = Vector2(320, 420)
	dialogue_label.size = Vector2(640, 64)
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

func add_interaction_flow() -> void:
	flow = InteractionFlowScript.new()
	flow.name = "InteractionFlow"
	flow.world = world
	add_child(flow)
	flow.phase_completed.connect(_on_phase_completed)
	flow.world_completed.connect(_on_world_completed)
	_build_building_progress()

func is_input_locked() -> bool:
	return (flow != null and flow.is_locked()) or (onboarding != null and onboarding.active)

# --- Onboarding: first launch only (user://save_data.cfg). Fresh-state test:
#     desktop  --reset-save   |   web  index.html?reset=1
func _maybe_start_onboarding() -> void:
	var reset := "--reset-save" in OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("/[?&]reset=1/.test(location.search)?1:0", true)
		reset = reset or (q is float and q > 0) or (q is int and q > 0)
	if reset:
		OnboardingScript.reset_save()
	onboarding = OnboardingScript.new()
	onboarding.name = "Onboarding"
	add_child(onboarding)
	if OnboardingScript.has_seen_onboarding():
		return
	if hud_layer: hud_layer.visible = false
	onboarding.finished.connect(func(): if hud_layer: hud_layer.visible = true)
	onboarding.start()

# --- Building progress overlay: "1/4" … "4/4 ✓" above each NPC's building ---
func _build_building_progress() -> void:
	for b in world.BUILDINGS:
		var group := get_node_or_null("BuildingGroup_" + b.id)
		if group == null:
			continue
		var lbl := Label.new()
		lbl.name = "Progress"
		lbl.text = "0/4"
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color("#ffd75a"))
		lbl.add_theme_color_override("font_shadow_color", Color.BLACK)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.position = Vector2(-14, -10)
		lbl.z_index = 7
		group.add_child(lbl)
		building_progress[b.id] = lbl

func _on_phase_completed(npc_id: String, _phase: int) -> void:
	var npc := _npc_by_id(npc_id)
	var bid: String = npc.get("building", "")
	var done: int = world.get_phase(npc_id)
	if bid != "" and building_progress.has(bid):
		var lbl: Label = building_progress[bid]
		lbl.text = "%d/4%s" % [done, " COMPLETE" if done >= 4 else ""]
		if done >= 4:
			lbl.add_theme_color_override("font_color", Color("#7fff7f"))
			var sprite := get_node_or_null("BuildingGroup_%s/Building_%s" % [bid, bid]) as Sprite2D
			if sprite:
				sprite.modulate = Color(1.05, 1.05, 0.9)

func _on_world_completed() -> void:
	dialogue_label.text = "World 1 complete! The farm gate swings open toward Downtown..."
	dialogue_label.visible = true

func _walkable_rows() -> Array:
	var rows := []
	if world:
		for y in world.ROWS:
			var line := ""
			for x in world.COLS:
				line += "." if world.walkable[y][x] else "#"
			rows.append(line)
	return rows

func _npc_tiles() -> Dictionary:
	var d := {}
	if world:
		for n in world.NPCS:
			d[n.id] = [n.tile.x, n.tile.y]
	return d

func _npc_by_id(id: String) -> Dictionary:
	for n in world.NPCS:
		if n.id == id:
			return n
	return {}

func _process(_delta: float) -> void:
	if player == null:
		return
	_publish_js_state()
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	if is_input_locked():
		prompt_label.text = ""
		return
	var nearby: Dictionary = world.get_adjacent_npc(player.current_tile())
	if nearby:
		var ph: int = world.get_phase(nearby.id)
		if ph >= 4:
			prompt_label.text = "[E] Talk to " + nearby.display_name + "  (complete)"
		else:
			prompt_label.text = "[E] Talk to " + nearby.display_name + "  (%d/4)" % ph
	else:
		prompt_label.text = ""

func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.keycode == KEY_F1:
		if map_editor:
			map_editor.toggle()
			if hud_layer:
				hud_layer.visible = not map_editor.edit_mode
		get_viewport().set_input_as_handled()
		return
	if map_editor and map_editor.edit_mode:
		return
	if onboarding and onboarding.active:
		return
	if not (event.pressed and not event.echo):
		return
	var is_interact: bool = event.keycode == KEY_E or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER
	if flow.state == flow.State.DIALOGUE and is_interact:
		flow.advance_dialogue()
		get_viewport().set_input_as_handled()
		return
	if flow.state != flow.State.MAP:
		return
	if is_interact:
		var nearby: Dictionary = world.get_adjacent_npc(player.current_tile())
		if nearby:
			dialogue_label.visible = false
			flow.start(nearby)
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
