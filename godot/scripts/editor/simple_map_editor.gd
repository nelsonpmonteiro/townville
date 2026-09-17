extends Node2D

const TILE_SIZE = 48
const COLS = 30
const ROWS = 20

# Map data
var grid = []
var entities = []  # {id, type, x, y, node}

# Editor state
var tool = "select"  # select paint erase npc building prop
var paint_type = 1
var active_npc = "mae"
var active_building = "henhouse"
var active_prop = "tree"
var dragged_entity = null
var drag_offset = Vector2.ZERO

# Textures
var img_grass
var img_dirt
var img_water
var npc_images = {}
var building_images = {}
var prop_images = {}

@onready var entity_layer = $EntityLayer

# UI references
var tool_buttons = {}
var npc_buttons = {}
var building_buttons = {}
var prop_buttons = {}
var status_label: Label

func _ready() -> void:
	img_grass = load("res://assets/terrain/tileset-grass-dirt.png")
	img_dirt = load("res://assets/terrain/tileset-grass-dirt.png")
	img_water = load("res://assets/terrain/tileset-water-grass.png")

	for npc in ["mae","chester","farmer-joe","vera","lily","grandma-rose","billy","old-mac"]:
		npc_images[npc] = load("res://assets/characters/world1/%s-idle.png" % npc)

	for b in ["henhouse","stable","barn","coop","animal-clinic","garden"]:
		building_images[b] = load("res://assets/buildings/world1/building-%s.png" % b)

	for p in ["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"]:
		prop_images[p] = load("res://assets/scenery/world1/scenery-%s.png" % p)

	if not entity_layer:
		entity_layer = Node2D.new()
		entity_layer.name = "EntityLayer"
		add_child(entity_layer)

	_setup_grid()
	_build_ui()

func _setup_grid() -> void:
	grid.clear()
	for y in range(ROWS):
		var row = []
		row.resize(COLS)
		row.fill(0)
		grid.append(row)

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
			_on_left_release(tile)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_on_right_click(_get_tile(event.position))
	elif event is InputEventMouseMotion:
		_on_mouse_motion(event.position)

func _on_left_press(tile: Vector2i, world_pos: Vector2) -> void:
	if tool == "select":
		for e in entities:
			var e_pos = _tile_to_world(Vector2i(e.x, e.y))
			if world_pos.distance_to(e_pos) < TILE_SIZE * 0.8:
				dragged_entity = e
				drag_offset = e_pos - world_pos
				_update_status()
				return
	elif tool == "paint":
		grid[tile.y][tile.x] = paint_type
		queue_redraw()
	elif tool == "erase":
		grid[tile.y][tile.x] = 0
		queue_redraw()
		_remove_entity_at(tile)
	elif tool == "npc":
		_add_entity("npc", active_npc, tile)
		_update_status()
	elif tool == "building":
		_add_entity("building", active_building, tile)
		_update_status()
	elif tool == "prop":
		_add_entity("prop", active_prop, tile)
		_update_status()

func _on_left_release(_tile: Vector2i) -> void:
	dragged_entity = null

func _on_right_click(tile: Vector2i) -> void:
	_remove_entity_at(tile)

func _remove_entity_at(tile: Vector2i) -> void:
	for i in range(entities.size() - 1, -1, -1):
		var e = entities[i]
		if e.x == tile.x and e.y == tile.y:
			e.node.queue_free()
			entities.remove_at(i)
			_update_status()
			return

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
	entity_layer.add_node(node)

	entities.append({"id": id, "type": type, "x": tile.x, "y": tile.y, "node": node})

func _make_sprite(type: String, id: String) -> Sprite2D:
	var path = ""
	match type:
		"npc":
			if npc_images.has(id):
				path = npc_images[id].get_path().replace(".import", "")
		"building":
			if building_images.has(id):
				path = building_images[id].get_path().replace(".import", "")
		"prop":
			if prop_images.has(id):
				path = prop_images[id].get_path().replace(".import", "")
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

func _draw() -> void:
	for y in range(ROWS):
		for x in range(COLS):
			var rect = Rect2(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
			match grid[y][x]:
				0: draw_rect(rect, Color(0.35, 0.55, 0.25))
				1: draw_rect(rect, Color(0.6, 0.45, 0.25))
				2: draw_rect(rect, Color(0.2, 0.4, 0.6))
				_: draw_rect(rect, Color(0.35, 0.55, 0.25))

	for x in range(COLS + 1):
		draw_line(Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, ROWS * TILE_SIZE), Color(0, 0, 0, 0.3))
	for y in range(ROWS + 1):
		draw_line(Vector2(0, y * TILE_SIZE), Vector2(COLS * TILE_SIZE, y * TILE_SIZE), Color(0, 0, 0, 0.3))

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)

	# Tool panel
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

	# Tool buttons
	var tool_hbox = HBoxContainer.new()
	vbox.add_child(tool_hbox)

	for t in ["select", "paint", "erase", "npc", "building", "prop"]:
		var btn = Button.new()
		btn.text = t.capitalize()
		btn.custom_minimum_size = Vector2(60, 24)
		btn.pressed.connect(func(): _set_tool(t))
		tool_hbox.add_child(btn)
		tool_buttons[t] = btn

	# Sub-panels for selecting specific items
	_build_item_panel(vbox, "NPCs", ["Mae","Chester","Farmer Joe","Lily","Vera","Grandma Rose","Billy","Old Mac"],
		["mae","chester","farmer-joe","lily","vera","grandma-rose","billy","old-mac"], npc_buttons, func(id): _set_tool("npc"); active_npc = id)

	_build_item_panel(vbox, "Buildings", ["Henhouse","Stable","Barn","Coop","Clinic","Garden"],
		["henhouse","stable","barn","coop","animal-clinic","garden"], building_buttons, func(id): _set_tool("building"); active_building = id)

	_build_item_panel(vbox, "Props", ["Tree","Bush","Red Flower","Yellow Flower","Stone","Well","Bench","Mailbox","Fountain","Lamppost","Flower Pot"],
		["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"], prop_buttons, func(id): _set_tool("prop"); active_prop = id)

	# Save/Load/Clear
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

	# Status / instructions
	status_label = Label.new()
	status_label.text = "Left-click: place/select  •  Right-click: delete  •  Drag: move (select tool)"
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
	_update_status()

func _update_tool_highlight() -> void:
	for t in tool_buttons:
		var btn = tool_buttons[t]
		if t == tool:
			btn.add_theme_color_override("font_color", Color("#fff2a8"))
		else:
			btn.add_theme_color_override("font_color", Color.WHITE)

func _update_status() -> void:
	var sel_info = ""
	if dragged_entity:
		sel_info = " | Dragging: %s" % dragged_entity.id
	status_label.text = "Tool: %s%s  •  Entities: %d" % [tool.to_upper(), sel_info, entities.size()]

func save_map(path: String) -> void:
	var ent_data = []
	for e in entities:
		ent_data.append({"id": e.id, "type": e.type, "x": e.x, "y": e.y})
	var data = {
		"version": 1,
		"cols": COLS, "rows": ROWS,
		"grid": grid,
		"entities": ent_data
	}
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()
		print("Saved: ", path)
	_update_status()

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
	if d.has("entities"):
		for e in entities:
			e.node.queue_free()
		entities.clear()
		for ed in d.entities:
			var t = Vector2i(ed.x, ed.y)
			_add_entity(ed.type, ed.id, t)
	queue_redraw()
	_update_status()

func clear_map() -> void:
	for e in entities:
		e.node.queue_free()
	entities.clear()
	for y in range(ROWS):
		for x in range(COLS):
			grid[y][x] = 0
	queue_redraw()
	_update_status()
