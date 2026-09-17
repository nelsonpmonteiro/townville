extends Node2D

const TILE_SIZE = 48
const COLS = 30
const ROWS = 20

var grid = []
var entities = []
var tool = "select"
var paint_type = 1
var active_npc = "mae"
var active_building = "henhouse"
var active_prop = "tree"
var dragged_entity = null
var drag_offset = Vector2.ZERO

var npc_images = {}
var building_images = {}
var prop_images = {}

@onready var tile_container: Node2D = get_node_or_null("TileContainer")
@onready var grid_lines: Node2D = get_node_or_null("GridLines")
@onready var entity_layer: Node2D = get_node_or_null("EntityLayer")

var tool_buttons = {}
var npc_buttons = {}
var building_buttons = {}
var prop_buttons = {}
var status_label: Label

func _ready() -> void:
	if not tile_container:
		tile_container = Node2D.new()
		tile_container.name = "TileContainer"
		add_child(tile_container)
		tile_container.z_index = 0
	if not grid_lines:
		grid_lines = Node2D.new()
		grid_lines.name = "GridLines"
		add_child(grid_lines)
		grid_lines.z_index = 5
	if not entity_layer:
		entity_layer = Node2D.new()
		entity_layer.name = "EntityLayer"
		add_child(entity_layer)
		entity_layer.z_index = 10
	for npc in ["mae","chester","farmer-joe","vera","lily","grandma-rose","billy","old-mac"]:
		npc_images[npc] = load("res://assets/characters/world1/%s-idle.png" % npc)
	for b in ["henhouse","stable","barn","coop","animal-clinic","garden"]:
		building_images[b] = load("res://assets/buildings/world1/building-%s.png" % b)
	for p in ["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"]:
		prop_images[p] = load("res://assets/scenery/world1/scenery-%s.png" % p)
	visible = false
	# Overlay mode: this editor draws ON TOP of the already-running World1 map
	# (same coordinate space, same camera). The tile grid below is a
	# semi-transparent EDIT OVERLAY, not the ground truth terrain — it only
	# exists to preview/paint changes; it does not replace map_renderer.
	_setup_grid()
	_build_ui()

func toggle() -> void:
	visible = not visible
	if ui_layer:
		ui_layer.visible = visible

func _setup_grid() -> void:
	grid.clear()
	for y in range(ROWS):
		var row = []
		row.resize(COLS)
		row.fill(0)
		grid.append(row)
	_redraw_tiles()
	_draw_grid()

func _redraw_tiles() -> void:
	for child in tile_container.get_children():
		child.queue_free()
	for y in range(ROWS):
		for x in range(COLS):
			if grid[y][x] == 0:
				continue
			var cr = ColorRect.new()
			cr.size = Vector2.ONE * TILE_SIZE
			cr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			match grid[y][x]:
				1: cr.color = Color(0.6, 0.45, 0.25, 0.6)
				2: cr.color = Color(0.2, 0.4, 0.6, 0.6)
				_: cr.color = Color(0.35, 0.55, 0.25, 0.6)
			tile_container.add_child(cr)

func _draw_grid() -> void:
	for child in grid_lines.get_children():
		child.queue_free()
	for x in range(COLS + 1):
		var l = Line2D.new()
		l.points = [Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, ROWS * TILE_SIZE)]
		l.width = 1.5
		l.default_color = Color(0, 0, 0, 0.55)
		grid_lines.add_child(l)
	for y in range(ROWS + 1):
		var l = Line2D.new()
		l.points = [Vector2(0, y * TILE_SIZE), Vector2(COLS * TILE_SIZE, y * TILE_SIZE)]
		l.width = 1.5
		l.default_color = Color(0, 0, 0, 0.55)
		grid_lines.add_child(l)

func _get_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func _tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5

func _in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < COLS and tile.y >= 0 and tile.y < ROWS

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if _mouse_over_panel(event.position):
			return
		var world_pos: Vector2 = get_global_mouse_position()
		var tile = _get_tile(world_pos)
		if not _in_bounds(tile):
			return
		if event.pressed:
			_on_left_press(tile, world_pos)
		else:
			dragged_entity = null
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed and not _mouse_over_panel(event.position):
			_remove_entity_at(_get_tile(get_global_mouse_position()))
	elif event is InputEventMouseMotion:
		if not _mouse_over_panel(event.position):
			_on_mouse_motion(get_global_mouse_position())

func _mouse_over_panel(screen_pos: Vector2) -> bool:
	if not panel_ref or not panel_open:
		return false
	return screen_pos.x <= PANEL_WIDTH

func _on_left_press(tile: Vector2i, world_pos: Vector2) -> void:
	print("MAP CLICKED at tile: ", tile, " world_pos: ", world_pos, " tool=", tool)
	if tool == "select":
		for e in entities:
			var e_pos = _tile_to_world(Vector2i(e.x, e.y))
			if world_pos.distance_to(e_pos) < TILE_SIZE * 0.8:
				dragged_entity = e
				drag_offset = e_pos - world_pos
				return
	elif tool == "paint":
		grid[tile.y][tile.x] = paint_type
		_redraw_tiles()
	elif tool == "erase":
		grid[tile.y][tile.x] = 0
		_redraw_tiles()
		_remove_entity_at(tile)
	elif tool == "npc":
		print("PLACING NPC: ", active_npc, " at ", tile)
		_add_entity("npc", active_npc, tile)
	elif tool == "building":
		print("PLACING BUILDING: ", active_building, " at ", tile)
		_add_entity("building", active_building, tile)
	elif tool == "prop":
		print("PLACING PROP: ", active_prop, " at ", tile)
		_add_entity("prop", active_prop, tile)

func _on_mouse_motion(world_pos: Vector2) -> void:
	if dragged_entity:
		var raw_tile = Vector2i(int((world_pos.x + drag_offset.x) / TILE_SIZE),
			int((world_pos.y + drag_offset.y) / TILE_SIZE))
		if _in_bounds(raw_tile):
			dragged_entity.x = raw_tile.x
			dragged_entity.y = raw_tile.y
			dragged_entity.node.position = _tile_to_world(raw_tile)

func _add_entity(type: String, id: String, tile: Vector2i) -> void:
	for i in range(entities.size() - 1, -1, -1):
		var e = entities[i]
		if e.x == tile.x and e.y == tile.y:
			e.node.queue_free()
			entities.remove_at(i)
	var spr = _make_sprite(type, id)
	if not spr:
		return
	var node = Node2D.new()
	node.name = "%s_%s_%d_%d" % [type, id, tile.x, tile.y]
	node.position = _tile_to_world(tile)
	node.add_child(spr)
	entity_layer.add_child(node)
	entities.append({"id": id, "type": type, "x": tile.x, "y": tile.y, "node": node})

func _make_sprite(type: String, id: String) -> Sprite2D:
	var path = ""
	match type:
		"npc": if npc_images.has(id): path = npc_images[id].get_path().replace(".import", "")
		"building": if building_images.has(id): path = building_images[id].get_path().replace(".import", "")
		"prop": if prop_images.has(id): path = prop_images[id].get_path().replace(".import", "")
	if path.is_empty():
		return null
	var s = Sprite2D.new()
	s.texture = load(path)
	s.centered = true
	if type == "building":
		s.scale = Vector2.ONE * 2.0
	elif type == "prop":
		s.scale = Vector2.ONE * 1.2
	else:
		s.scale = Vector2.ONE * 1.4
	return s

func _remove_entity_at(tile: Vector2i) -> void:
	for i in range(entities.size() - 1, -1, -1):
		var e = entities[i]
		if e.x == tile.x and e.y == tile.y:
			e.node.queue_free()
			entities.remove_at(i)
			return

var panel_ref: PanelContainer
var panel_open: bool = true
var ui_layer: CanvasLayer
var ground_swatch_row: HBoxContainer
const PANEL_WIDTH := 300.0

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	ui_layer.visible = false
	add_child(ui_layer)
	var layer = ui_layer

	var toggle_btn = Button.new()
	toggle_btn.text = "<"
	toggle_btn.position = Vector2(PANEL_WIDTH, 10)
	toggle_btn.custom_minimum_size = Vector2(24, 24)
	toggle_btn.pressed.connect(func(): _toggle_panel(toggle_btn))
	layer.add_child(toggle_btn)

	var panel = PanelContainer.new()
	panel.position = Vector2(0, 0)
	panel.custom_minimum_size = Vector2(PANEL_WIDTH, 640)
	panel.size = Vector2(PANEL_WIDTH, 640)
	panel.clip_contents = true
	layer.add_child(panel)
	panel_ref = panel

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(PANEL_WIDTH, 640)
	panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(PANEL_WIDTH - 16, 0)
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	var title = Label.new()
	title.text = "MAP EDITOR"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("#fff2a8"))
	vbox.add_child(title)

	var tool_hbox = HFlowContainer.new()
	vbox.add_child(tool_hbox)
	for t in ["select", "paint", "erase", "npc", "building", "prop"]:
		var btn = Button.new()
		btn.text = t.capitalize()
		btn.custom_minimum_size = Vector2(60, 24)
		btn.pressed.connect(func(): _set_tool(t))
		tool_hbox.add_child(btn)
		tool_buttons[t] = btn

	_build_item_panel(vbox, "NPCs", ["mae","chester","farmer-joe","lily","vera","grandma-rose","billy","old-mac"],
		npc_images, npc_buttons, func(id): _set_tool("npc"); active_npc = id; _select_thumbnail(npc_buttons, id))

	_build_item_panel(vbox, "Buildings", ["henhouse","stable","barn","coop","animal-clinic","garden"],
		building_images, building_buttons, func(id): _set_tool("building"); active_building = id; _select_thumbnail(building_buttons, id))

	_build_item_panel(vbox, "Props", ["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"],
		prop_images, prop_buttons, func(id): _set_tool("prop"); active_prop = id; _select_thumbnail(prop_buttons, id))

	ground_swatch_row = HBoxContainer.new()
	ground_swatch_row.add_theme_constant_override("separation", 4)
	ground_swatch_row.visible = false
	vbox.add_child(ground_swatch_row)
	_add_ground_swatch(ground_swatch_row, "Grass", 0, Color(0.35, 0.55, 0.25))
	_add_ground_swatch(ground_swatch_row, "Dirt Path", 1, Color(0.6, 0.45, 0.25))
	_add_ground_swatch(ground_swatch_row, "Water", 2, Color(0.2, 0.4, 0.6))

	var action_hbox = HBoxContainer.new()
	vbox.add_child(action_hbox)

	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(func(): save_map("user://map.json"))
	action_hbox.add_child(save_btn)

	var load_btn = Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(func(): load_map("user://map.json"))
	action_hbox.add_child(load_btn)

	var clear_btn = Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(clear_map)
	action_hbox.add_child(clear_btn)

	var export_btn = Button.new()
	export_btn.text = "Export JSON"
	export_btn.pressed.connect(export_map_download)
	vbox.add_child(export_btn)

	status_label = Label.new()
	status_label.text = "Left-click: place/select | Right-click: delete | Drag: move (select tool)"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color("#aaa"))
	vbox.add_child(status_label)

	_update_tool_highlight()

func _build_item_panel(parent: Node, title: String, ids: Array, images: Dictionary, buttons: Dictionary, callback: Callable) -> void:
	var sep = Label.new()
	sep.text = "— " + title + " —"
	sep.add_theme_color_override("font_color", Color("#888"))
	parent.add_child(sep)
	var flow = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 3)
	flow.add_theme_constant_override("v_separation", 3)
	parent.add_child(flow)
	for id in ids:
		var btn = TextureButton.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		if images.has(id) and images[id]:
			btn.texture_normal = images[id]
		btn.tooltip_text = id.capitalize().replace("-", " ")
		btn.pressed.connect(func(): callback.call(id))
		flow.add_child(btn)
		buttons[id] = btn

func _set_tool(t: String) -> void:
	print("TOOL SELECTED: ", t)
	tool = t
	_update_tool_highlight()
	if ground_swatch_row:
		ground_swatch_row.visible = (t == "paint")

func _select_thumbnail(buttons: Dictionary, active_id: String) -> void:
	print("ITEM SELECTED: ", active_id)
	for id in buttons:
		var btn: TextureButton = buttons[id]
		btn.modulate = Color(1, 1, 0.4) if id == active_id else Color.WHITE
		btn.self_modulate = Color(1, 1, 1, 1)
	# Yellow border highlight via a StyleBox overlay would need a Panel;
	# modulate tint is the simplest reliable "selected" indicator on TextureButton.

func _add_ground_swatch(parent: Node, label_text: String, type_id: int, color: Color) -> void:
	var vbox := VBoxContainer.new()
	var swatch := ColorRect.new()
	swatch.custom_minimum_size = Vector2(32, 32)
	swatch.color = color
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(60, 20)
	btn.text = label_text
	btn.pressed.connect(func(): paint_type = type_id; _highlight_ground_swatch(parent, type_id))
	vbox.add_child(swatch)
	vbox.add_child(btn)
	parent.add_child(vbox)

func _highlight_ground_swatch(parent: Node, active_type: int) -> void:
	for i in range(parent.get_child_count()):
		var vb: VBoxContainer = parent.get_child(i)
		var swatch: ColorRect = vb.get_child(0)
		swatch.modulate = Color(1, 1, 0.4) if i == active_type else Color.WHITE

func _update_tool_highlight() -> void:
	for t in tool_buttons:
		var btn = tool_buttons[t]
		if t == tool:
			btn.add_theme_color_override("font_color", Color("#fff2a8"))
			btn.modulate = Color(1.3, 1.3, 0.7)
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.modulate = Color.WHITE

func save_map(path: String) -> void:
	var ent_data = []
	for e in entities:
		ent_data.append({"id": e.id, "type": e.type, "x": e.x, "y": e.y})
	var data = {"version": 1, "cols": COLS, "rows": ROWS, "grid": grid, "entities": ent_data}
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()

func load_map(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var j = JSON.new()
	j.parse(f.get_as_text())
	f.close()
	var d = j.data
	if d.has("grid"):
		grid = d.grid
		_redraw_tiles()
	if d.has("entities"):
		for e in entities:
			e.node.queue_free()
		entities.clear()
		for ed in d.entities:
			_add_entity(ed.type, ed.id, Vector2i(ed.x, ed.y))

func clear_map() -> void:
	for e in entities:
		e.node.queue_free()
	entities.clear()
	for y in range(ROWS):
		for x in range(COLS):
			grid[y][x] = 0
	_redraw_tiles()

func _toggle_panel(toggle_btn: Button) -> void:
	panel_open = not panel_open
	panel_ref.visible = panel_open
	toggle_btn.position.x = PANEL_WIDTH if panel_open else 0
	toggle_btn.text = "<" if panel_open else ">"

func export_map_download() -> void:
	var ent_data = []
	for e in entities:
		ent_data.append({"id": e.id, "type": e.type, "x": e.x, "y": e.y})
	var data = {"version": 1, "cols": COLS, "rows": ROWS, "grid": grid, "entities": ent_data}
	var json_text = JSON.stringify(data, "  ")
	if OS.has_feature("web") and JavaScriptBridge:
		var js_code = """
			(function(text){
				var blob = new Blob([text], {type: 'application/json'});
				var url = URL.createObjectURL(blob);
				var a = document.createElement('a');
				a.href = url; a.download = 'townville_map_export.json';
				document.body.appendChild(a); a.click(); document.body.removeChild(a);
				URL.revokeObjectURL(url);
			})(%s)
		""" % JSON.stringify(json_text)
		JavaScriptBridge.eval(js_code, true)
		status_label.text = "Exported: check your browser Downloads folder."
	else:
		var f = FileAccess.open("res://../artifacts/townville_map_export.json", FileAccess.WRITE)
		if f:
			f.store_string(json_text)
			f.close()
			status_label.text = "Exported to godot/artifacts/townville_map_export.json"
