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

@onready var tile_container = $TileContainer
@onready var grid_lines = $GridLines
@onready var entity_layer = $EntityLayer

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
	for npc in ["mae","chester","farmer-joe","vera","lily","grandma-rose","billy","old-mac"]:
		npc_images[npc] = load("res://assets/characters/world1/%s-idle.png" % npc)
	for b in ["henhouse","stable","barn","coop","animal-clinic","garden"]:
		building_images[b] = load("res://assets/buildings/world1/building-%s.png" % b)
	for p in ["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"]:
		prop_images[p] = load("res://assets/scenery/world1/scenery-%s.png" % p)
	_setup_grid()
	_build_ui()

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
			var cr = ColorRect.new()
			cr.size = Vector2.ONE * TILE_SIZE
			cr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			match grid[y][x]:
				0: cr.color = Color(0.35, 0.55, 0.25)
				1: cr.color = Color(0.6, 0.45, 0.25)
				2: cr.color = Color(0.2, 0.4, 0.6)
				_: cr.color = Color(0.35, 0.55, 0.25)
			tile_container.add_child(cr)

func _draw_grid() -> void:
	for child in grid_lines.get_children():
		child.queue_free()
	for x in range(COLS + 1):
		var l = Line2D.new()
		l.points = [Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, ROWS * TILE_SIZE)]
		l.width = 0.5
		l.default_color = Color(0, 0, 0, 0.3)
		grid_lines.add_child(l)
	for y in range(ROWS + 1):
		var l = Line2D.new()
		l.points = [Vector2(0, y * TILE_SIZE), Vector2(COLS * TILE_SIZE, y * TILE_SIZE)]
		l.width = 0.5
		l.default_color = Color(0, 0, 0, 0.3)
		grid_lines.add_child(l)

func _get_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / TILE_SIZE), int(world_pos.y / TILE_SIZE))

func _tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5

func _in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < COLS and tile.y >= 0 and tile.y < ROWS

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var tile = _get_tile(event.position)
		if not _in_bounds(tile):
			return
		if event.pressed:
			_on_left_press(tile, event.position)
		else:
			dragged_entity = null
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_remove_entity_at(_get_tile(event.position))
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event.position)

func _on_left_press(tile: Vector2i, world_pos: Vector2) -> void:
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
		_add_entity("npc", active_npc, tile)
	elif tool == "building":
		_add_entity("building", active_building, tile)
	elif tool == "prop":
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

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	var panel = PanelContainer.new()
	panel.position = Vector2(10, 10)
	layer.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "MAP EDITOR"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("#fff2a8"))
	vbox.add_child(title)

	var tool_hbox = HBoxContainer.new()
	vbox.add_child(tool_hbox)
	for t in ["select", "paint", "erase", "npc", "building", "prop"]:
		var btn = Button.new()
		btn.text = t.capitalize()
		btn.custom_minimum_size = Vector2(60, 24)
		btn.pressed.connect(func(): _set_tool(t))
		tool_hbox.add_child(btn)
		tool_buttons[t] = btn

	_build_item_panel(vbox, "NPCs", ["Mae","Chester","Farmer Joe","Lily","Vera","Grandma Rose","Billy","Old Mac"],
		["mae","chester","farmer-joe","lily","vera","grandma-rose","billy","old-mac"], npc_buttons, func(id): _set_tool("npc"); active_npc = id)

	_build_item_panel(vbox, "Buildings", ["Henhouse","Stable","Barn","Coop","Clinic","Garden"],
		["henhouse","stable","barn","coop","animal-clinic","garden"], building_buttons, func(id): _set_tool("building"); active_building = id)

	_build_item_panel(vbox, "Props", ["Tree","Bush","Red Flower","Yellow Flower","Stone","Well","Bench","Mailbox","Fountain","Lamppost","Flower Pot"],
		["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"], prop_buttons, func(id): _set_tool("prop"); active_prop = id)

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

	status_label = Label.new()
	status_label.text = "Left-click: place/select | Right-click: delete | Drag: move (select tool)"
	status_label.add_theme_font_size_override("font_size", 11)
	status_label.add_theme_color_override("font_color", Color("#aaa"))
	vbox.add_child(status_label)

	_update_tool_highlight()

func _build_item_panel(parent: Node, title: String, labels: Array, ids: Array, buttons: Dictionary, callback: Callable) -> void:
	var sep = Label.new()
	sep.text = "— " + title + " —"
	sep.add_theme_color_override("font_color", Color("#888"))
	parent.add_child(sep)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 2)
	parent.add_child(hbox)
	for i in range(labels.size()):
		var btn = Button.new()
		btn.text = labels[i]
		btn.custom_minimum_size = Vector2(55, 22)
		var id = ids[i]
		btn.pressed.connect(func(): callback.call(id))
		hbox.add_child(btn)
		buttons[ids[i]] = btn

func _set_tool(t: String) -> void:
	tool = t
	_update_tool_highlight()

func _update_tool_highlight() -> void:
	for t in tool_buttons:
		var btn = tool_buttons[t]
		if t == tool:
			btn.add_theme_color_override("font_color", Color("#fff2a8"))
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)

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
