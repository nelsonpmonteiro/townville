extends Node2D

const WorldDataScript = preload("res://scripts/world_data.gd")
const MapRendererScript = preload("res://scripts/map_renderer.gd")
const PlayerScript = preload("res://scripts/player.gd")
const MapEditorScript = preload("res://scripts/editor/simple_map_editor.gd")
const InteractionFlowScript = preload("res://scripts/ui/interaction_flow.gd")
const OnboardingScript = preload("res://scripts/ui/onboarding.gd")
const VolumeControlScript = preload("res://scripts/ui/volume_control.gd")
const MusicPlayerScript = preload("res://scripts/ui/music_player.gd")
const RestartControlScript = preload("res://scripts/ui/restart_control.gd")

var world
var player
var prompt_label: Label
var dialogue_label: Label
var fps_label: Label
var fps_visible := false
var info_button: TextureButton
var info_panel: PanelContainer
var info_panel_open := false
var built := false
var map_editor: Node2D
var map_renderer_node: Node2D
var hud_layer: CanvasLayer

# Interaction flow (dialogue → exercise → feedback), one screen at a time
var flow: CanvasLayer
var building_progress := {}  # building_id -> Label overlay
var onboarding: CanvasLayer
var volume_control: CanvasLayer
var restart_control: CanvasLayer
var music_player: AudioStreamPlayer

func _ready() -> void:
	build_world()
	_install_js_bridge()
	_maybe_start_onboarding()
	_maybe_preview_ending()
	if "--capture" in OS.get_cmdline_user_args():
		capture_after_render.call_deferred()

## Review shortcut: index.html?ending=1 (or --preview-ending on desktop) jumps
## straight to the end-of-demo message without replaying all eight NPCs.
func _maybe_preview_ending() -> void:
	var preview := "--preview-ending" in OS.get_cmdline_user_args()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("/[?&]ending=1/.test(location.search)?1:0", true)
		preview = preview or (q is float and q > 0) or (q is int and q > 0)
	if not preview:
		return
	if onboarding and onboarding.active:
		onboarding._finish()
		await onboarding.finished
	await get_tree().process_frame
	flow.show_ending()

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
		"audio": _audio_state(),
		"restart_modal_open": restart_control.modal_open if restart_control else false,
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
				var mode: String = flow.exercise.mode
				var src: Control
				if mode in ["array", "share"]:
					src = flow.visual_source_items
				else:
					src = flow.source_items if mode == "basket_in" else flow.basket_items
				var i := 0
				for ch in src.get_children():
					if ch.get_script() == flow.DragItemScript:
						r["item%d" % i] = _rect(ch); i += 1
				for cell_index in flow.visual_cells.size():
					r["array%d" % cell_index] = _rect(flow.visual_cells[cell_index])
				for zone_index in flow.share_zones.size():
					r["share%d" % zone_index] = _rect(flow.share_zones[zone_index])
				r["basket"] = _rect(flow.basket_zone)
				r["tray"] = _rect(flow.tray_zone)
				r["done"] = _rect(flow.done_btn)
				r["input"] = _rect(flow.answer_input)
				r["submit"] = _rect(flow.submit_btn)
			if flow and flow.state == flow.State.DIALOGUE:
				r["dialogue_box"] = _rect(flow.dialogue_screen.get_node("DialogueBox"))
			if volume_control:
				r["volume_button"] = _rect(volume_control.button)
				if volume_control.panel_open:
					r["volume_music_slider"] = _rect(volume_control.music_slider)
					r["volume_sfx_slider"] = _rect(volume_control.sfx_slider)
			if restart_control:
				r["restart_button"] = _rect(restart_control.button)
				if restart_control.modal_open:
					r["restart_confirm"] = _rect(restart_control.confirm_button)
					r["restart_cancel"] = _rect(restart_control.cancel_button)
			JavaScriptBridge.eval("window.__townville_rects=" + JSON.stringify(r) + ";", true)
		"drag_one":
			flow.debug_drag_one(parts[1])
		"done":
			flow.debug_done()
		"hint":
			flow.debug_hint()
		"submit":
			flow.debug_submit(parts[1])
		"advance":
			flow.advance_dialogue()
		"onboard_reset":
			OnboardingScript.reset_save()
		"volume_toggle":
			if volume_control:
				volume_control.toggle_panel()
		"volume_set":
			# volume_set <music 0..1> <sfx 0..1>
			if volume_control and parts.size() >= 3:
				volume_control.set_levels(float(parts[1]), float(parts[2]))

func _rect(c: Control) -> Array:
	var g := c.get_global_rect()
	return [g.position.x, g.position.y, g.size.x, g.size.y]

## Volume popover + bus levels, exposed so the browser probe can verify that the
## two sliders move their own bus and nothing else.
func _audio_state() -> Dictionary:
	if not volume_control:
		return {}
	return {
		"panel_open": volume_control.panel_open,
		"music": volume_control.music_level,
		"sfx": volume_control.sfx_level,
		"music_db": AudioServer.get_bus_volume_db(maxi(AudioServer.get_bus_index("Music"), 0)),
		"sfx_db": AudioServer.get_bus_volume_db(maxi(AudioServer.get_bus_index("SFX"), 0)),
		"music_playing": music_player.is_music_playing() if music_player else false,
	}

func build_world() -> void:
	if built:
		return
	built = true
	world = WorldDataScript.new()
	# Depth policy: the player is always above NPCs and every building except
	# the clinic. Only the clinic shares the player's layer, so Y sorting can
	# place the player behind its roof when approaching from above.
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
	player.z_index = 20
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
		container.z_index = 20 if b.id == "clinic" else 0
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
			shadow.z_index = -1
			shadow.modulate.a = 0.4
			container.add_child(shadow)

		var sprite := Sprite2D.new()
		sprite.name = "Building_" + b.id
		sprite.texture = texture
		sprite.scale = Vector2(building_scale * (-1.0 if flip_h else 1.0), building_scale)
		sprite.position = Vector2(0, -scaled_height / 2.0)
		sprite.z_index = 0
		container.add_child(sprite)
		var label := Label.new()
		label.text = b.label
		label.position = sprite.position + Vector2(-40, -scaled_height / 2.0 - 18)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.z_index = 1
		container.add_child(label)

func add_npcs() -> void:
	for npc in world.NPCS:
		var npc_pos: Vector2 = Vector2(npc.tile * world.TILE_SIZE) + Vector2.ONE * world.TILE_SIZE * 0.5

		var container := Node2D.new()
		container.name = "NPCGroup_" + npc.id
		# Old Mac stands right at the gate the player spawns beside; he needs
		# to participate in Y-sort (like the clinic building) so the player
		# walking north past him draws BEHIND his sprite, not always in front.
		container.z_index = 20 if npc.id == "old-mac" else 0
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
			shadow.z_index = -1
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
		sprite.z_index = 0
		container.add_child(sprite)
		var name_label := Label.new()
		name_label.text = npc.display_name
		name_label.position = sprite.position + Vector2(-38, -58)
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		name_label.add_theme_constant_override("shadow_offset_x", 1)
		name_label.add_theme_constant_override("shadow_offset_y", 1)
		name_label.z_index = 1
		container.add_child(name_label)

func add_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	hud_layer = layer
	fps_label = Label.new()
	fps_label.name = "FpsLabel"
	fps_label.position = Vector2(18, 16)
	fps_label.add_theme_color_override("font_color", Color("#d8ffd0"))
	fps_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	fps_label.add_theme_constant_override("shadow_offset_x", 2)
	fps_label.add_theme_constant_override("shadow_offset_y", 2)
	fps_label.visible = false
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
	_build_info_tooltip(layer)
	_build_audio()

## Background music + the volume popover live outside the HUD layer so they stay
## reachable while the HUD is hidden (onboarding, map editor).
func _build_audio() -> void:
	music_player = MusicPlayerScript.new()
	add_child(music_player)
	volume_control = VolumeControlScript.new()
	volume_control.name = "VolumeControl"
	add_child(volume_control)
	restart_control = RestartControlScript.new()
	restart_control.name = "RestartControl"
	add_child(restart_control)

## Bottom-right "?" icon button that opens/closes a tooltip panel with the
## movement/interact instructions and the journey goal — replaces the two
## always-on labels that used to sit in the top-left permanently.
func _build_info_tooltip(layer: CanvasLayer) -> void:
	# Semi-transparent circular backdrop behind the icon so the PixelLab
	# glyph (mostly light pixels) stays legible over any background tile
	# (grass, water, dark dirt) instead of floating with no contrast.
	var info_backdrop := Panel.new()
	info_backdrop.name = "InfoTooltipBackdrop"
	var info_bg_sb := StyleBoxFlat.new()
	info_bg_sb.bg_color = Color(0.12, 0.1, 0.08, 0.55)
	info_bg_sb.border_color = Color("#c9a36b")
	info_bg_sb.set_border_width_all(2)
	info_bg_sb.set_corner_radius_all(24)
	info_backdrop.add_theme_stylebox_override("panel", info_bg_sb)
	info_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_backdrop.anchor_left = 1.0; info_backdrop.anchor_right = 1.0
	info_backdrop.anchor_top = 1.0; info_backdrop.anchor_bottom = 1.0
	info_backdrop.offset_left = -64; info_backdrop.offset_right = -16
	info_backdrop.offset_top = -64; info_backdrop.offset_bottom = -16
	layer.add_child(info_backdrop)

	info_button = TextureButton.new()
	info_button.name = "InfoTooltipButton"
	var icon_path := "res://assets/ui/info-tooltip.png"
	if ResourceLoader.exists(icon_path):
		var tex := load(icon_path) as Texture2D
		info_button.texture_normal = tex
		info_button.ignore_texture_size = true
		info_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	info_button.custom_minimum_size = Vector2(48, 48)
	info_button.anchor_left = 1.0; info_button.anchor_right = 1.0
	info_button.anchor_top = 1.0; info_button.anchor_bottom = 1.0
	info_button.offset_left = -64; info_button.offset_right = -16
	info_button.offset_top = -64; info_button.offset_bottom = -16
	info_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	info_button.pressed.connect(_toggle_info_panel)
	layer.add_child(info_button)

	info_panel = PanelContainer.new()
	info_panel.name = "InfoTooltipPanel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1e1a16f2")
	sb.border_color = Color("#c9a36b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	info_panel.add_theme_stylebox_override("panel", sb)
	info_panel.custom_minimum_size = Vector2(360, 0)
	info_panel.anchor_left = 1.0; info_panel.anchor_right = 1.0
	info_panel.anchor_top = 1.0; info_panel.anchor_bottom = 1.0
	info_panel.offset_left = -392; info_panel.offset_right = -16
	info_panel.offset_top = -172; info_panel.offset_bottom = -76
	info_panel.visible = false
	layer.add_child(info_panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	info_panel.add_child(v)

	var instructions := Label.new()
	instructions.text = "Move: WASD / Arrows  |  Interact: E or Space"
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	v.add_child(instructions)

	var objective := Label.new()
	objective.name = "ObjectiveLabel"
	objective.text = "Goal: Help people on the farm with their problems to continue your journey."
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size", 15)
	objective.add_theme_color_override("font_color", Color("#fff2a8"))
	v.add_child(objective)

func _toggle_info_panel() -> void:
	info_panel_open = not info_panel_open
	info_panel.visible = info_panel_open

func _toggle_fps() -> void:
	fps_visible = not fps_visible
	fps_label.visible = fps_visible


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
	# Hide the HUD *and* the volume popover behind the title cards, but leave the
	# music player running so the farm theme plays under the onboarding.
	if hud_layer: hud_layer.visible = false
	if volume_control: volume_control.visible = false
	if restart_control: restart_control.visible = false
	onboarding.finished.connect(func():
		if hud_layer: hud_layer.visible = true
		if volume_control: volume_control.visible = true
		if restart_control: restart_control.visible = true)
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

## Old Mac's final phase is the end of what's built. Downtown is not wired in
## for this build, so the farm-to-downtown transition is replaced by the
## end-of-demo message — shown in the regular dialogue box, after which the
## player stays free on the map to revisit any NPC.
func _on_world_completed() -> void:
	dialogue_label.visible = false
	flow.show_ending()

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
	if fps_visible:
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

## Mouse gestures unlock web audio too — the whole basket UI is click-driven,
## so a player who never touches the keyboard still gets music.
func _input(event: InputEvent) -> void:
	if music_player and event is InputEventMouseButton and event.pressed:
		music_player.kickstart()

func _unhandled_key_input(event: InputEvent) -> void:
	# Browsers keep the audio context suspended until the first real user
	# gesture, so the music started at _ready() is silent until one arrives.
	if event.pressed and music_player:
		music_player.kickstart()
	if event.pressed and not event.echo and event.keycode == KEY_HOME:
		_toggle_fps()
		get_viewport().set_input_as_handled()
		return
	if event.pressed and not event.echo and event.keycode == KEY_F1:
		if map_editor:
			map_editor.toggle()
			if hud_layer:
				hud_layer.visible = not map_editor.edit_mode
			if volume_control:
				volume_control.visible = not map_editor.edit_mode
			if restart_control:
				restart_control.visible = not map_editor.edit_mode
		get_viewport().set_input_as_handled()
		return
	if map_editor and map_editor.edit_mode:
		return
	if onboarding and onboarding.active:
		return
	if not (event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE and flow.state == flow.State.DIALOGUE:
		flow.cancel_dialogue()
		get_viewport().set_input_as_handled()
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
