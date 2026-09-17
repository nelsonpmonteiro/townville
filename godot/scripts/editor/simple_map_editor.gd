extends Node2D

const TILE_SIZE = 48
const COLS = 30
const ROWS = 20

var world = null
var map_renderer: Node2D = null

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
var collision_layer: Node2D

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
	collision_layer = Node2D.new()
	collision_layer.name = "CollisionLayer"
	collision_layer.z_index = 12
	collision_layer.visible = false
	add_child(collision_layer)
	for npc in ["mae","chester","farmer-joe","vera","lily","grandma-rose","billy","old-mac"]:
		npc_images[npc] = load("res://assets/characters/world1/%s-idle.png" % npc)
	for b in ["henhouse","stable","barn","coop","animal-clinic","garden"]:
		building_images[b] = load("res://assets/buildings/world1/building-%s.png" % b)
	for p in ["tree","bush","flower-red","flower-yellow","stone","well","bench","mailbox","fountain","lamppost","flower-pot"]:
		prop_images[p] = load("res://assets/scenery/world1/scenery-%s.png" % p)
	# This root Node2D itself must stay visible at all times — it hosts
	# entity_layer, which holds every placed prop/building/npc. Hiding this
	# node (visible=false) would hide entity_layer too and make everything
	# placed disappear the moment the editor UI closes. Only the editor's
	# own guide layers (grid_lines/tile_container/collision_layer/ui_layer)
	# toggle with edit_mode; entity_layer never does.
	# Overlay mode: this editor draws ON TOP of the already-running World1 map
	# (same coordinate space, same camera). The tile grid below is a
	# semi-transparent EDIT OVERLAY, not the ground truth terrain — it only
	# exists to preview/paint changes; it does not replace map_renderer.
	_setup_grid()
	_build_ui()

var edit_mode := false

func toggle() -> void:
	edit_mode = not edit_mode
	if ui_layer:
		ui_layer.visible = edit_mode
	if grid_lines:
		grid_lines.visible = edit_mode
	if tile_container:
		tile_container.visible = edit_mode
	if collision_layer:
		collision_layer.visible = edit_mode and tool == "collision"
	# entity_layer (placed props/buildings/npcs) stays visible always —
	# it must NOT be tied to the editor's own on/off state, otherwise
	# everything placed disappears the moment you close the editor.
	if edit_mode:
		_register_existing_entities()

# Finds the already-placed BuildingGroup_*/NPCGroup_* containers created by
# game.gd (add_buildings/add_npcs) and registers them as movable/deletable
# entities, so Select+drag and Delete work on what's ALREADY on the map,
# not only on new items placed through this editor session.
func _register_existing_entities() -> void:
	# Preserve editor-placed items (new props/buildings/npcs) — only
	# rebuild the "*_existing" (world_data.gd) portion of the list, since
	# those node references can go stale across scene changes but the
	# freshly-placed ones are already correct and must not be discarded.
	entities = entities.filter(func(e): return e.type not in ["building_existing", "npc_existing"])
	var game_root = get_parent()
	if game_root == null:
		return
	for child in game_root.get_children():
		if not child.has_meta("building_id") and not child.has_meta("npc_id"):
			continue
		if child.has_meta("building_id"):
			var col: int = child.get_meta("footprint_col")
			var row: int = child.get_meta("footprint_row")
			var fw: int = child.get_meta("footprint_w")
			var fh: int = child.get_meta("footprint_h")
			entities.append({"id": child.get_meta("building_id"), "type": "building_existing", "x": col, "y": row, "fw": fw, "fh": fh, "node": child})
		elif child.has_meta("npc_id"):
			var tx: int = child.get_meta("tile_x")
			var ty: int = child.get_meta("tile_y")
			entities.append({"id": child.get_meta("npc_id"), "type": "npc_existing", "x": tx, "y": ty, "node": child})
	print("Registered ", entities.size(), " existing entities for select/move/delete")

func _setup_grid() -> void:
	grid.clear()
	for y in range(ROWS):
		var row = []
		row.resize(COLS)
		row.fill(0)
		grid.append(row)
	_sync_grid_from_world()
	_draw_grid()

# Mirrors world.path_mask into the editor's local grid array so the overlay
# always reflects the REAL terrain already painted by map_renderer, instead
# of starting blank / out of sync with what's actually on screen.
func _sync_grid_from_world() -> void:
	if world == null or world.path_mask.is_empty():
		return
	for y in range(ROWS):
		for x in range(COLS):
			grid[y][x] = 1 if world.path_mask[y][x] else 0
	_redraw_tiles()

func _redraw_tiles() -> void:
	if tile_container == null:
		return
	for child in tile_container.get_children():
		child.queue_free()
	# This overlay only marks the tile currently painted as PATH so the
	# editor still shows something even before the real TileMapLayer
	# repaints; the real ground texture change happens in map_renderer.
	for y in range(ROWS):
		for x in range(COLS):
			if grid[y][x] != 1:
				continue
			var cr = ColorRect.new()
			cr.size = Vector2.ONE * TILE_SIZE
			cr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			cr.color = Color(1, 1, 0, 0.12)
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
	if not edit_mode:
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

# Writes directly into the REAL terrain data (world.path_mask / world.walkable)
# and repaints the actual TileMapLayer via map_renderer, so Paint swaps the
# real ground texture instead of only drawing a colored overlay on top of it.
func _paint_real_ground(tile: Vector2i, as_path: bool) -> void:
	if world == null:
		_redraw_tiles()
		return
	if tile.y < 0 or tile.y >= world.ROWS or tile.x < 0 or tile.x >= world.COLS:
		return
	world.path_mask[tile.y][tile.x] = as_path
	world.walkable[tile.y][tile.x] = as_path
	if map_renderer and map_renderer.has_method("rebuild_tilemap"):
		map_renderer.rebuild_tilemap()
	_redraw_tiles()

# Toggles a tile's walkability directly in the REAL collision data
# (world.walkable), independent of ground texture (world.path_mask).
# This lets you mark a grass tile as blocked (e.g. decorative obstacle)
# or a dirt tile as walkable without repainting the ground underneath.
func _toggle_collision(tile: Vector2i) -> void:
	if world == null:
		return
	if tile.y < 0 or tile.y >= world.ROWS or tile.x < 0 or tile.x >= world.COLS:
		return
	world.walkable[tile.y][tile.x] = not world.walkable[tile.y][tile.x]
	print("COLLISION at ", tile, " -> walkable=", world.walkable[tile.y][tile.x])
	_redraw_collision_overlay()

func _redraw_collision_overlay() -> void:
	if collision_layer == null:
		return
	for child in collision_layer.get_children():
		child.queue_free()
	if world == null or world.walkable.is_empty():
		return
	for y in range(ROWS):
		for x in range(COLS):
			var cr = ColorRect.new()
			cr.size = Vector2.ONE * TILE_SIZE
			cr.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			cr.color = Color(0, 1, 0, 0.28) if world.walkable[y][x] else Color(1, 0, 0, 0.32)
			collision_layer.add_child(cr)

func _on_left_press(tile: Vector2i, world_pos: Vector2) -> void:
	print("MAP CLICKED at tile: ", tile, " world_pos: ", world_pos, " tool=", tool)
	if tool == "select":
		dragged_entity = _find_entity_at(tile, world_pos)
		if dragged_entity:
			drag_offset = _entity_anchor_world(dragged_entity) - world_pos
		return
	elif tool == "paint":
		grid[tile.y][tile.x] = paint_type
		_paint_real_ground(tile, paint_type == 1)
	elif tool == "erase":
		grid[tile.y][tile.x] = 0
		_paint_real_ground(tile, false)
		_remove_entity_at(tile)
	elif tool == "collision":
		_toggle_collision(tile)
	elif tool == "npc":
		print("PLACING NPC: ", active_npc, " at ", tile)
		_add_entity("npc", active_npc, tile)
	elif tool == "building":
		print("PLACING BUILDING: ", active_building, " at ", tile)
		_add_entity("building", active_building, tile)
	elif tool == "prop":
		print("PLACING PROP: ", active_prop, " at ", tile)
		_add_entity("prop", active_prop, tile)

func _entity_anchor_world(e: Dictionary) -> Vector2:
	if e.type == "building_existing":
		var fw: int = e.get("fw", 1)
		var fh: int = e.get("fh", 1)
		return Vector2(e.x + fw / 2.0, e.y + fh) * TILE_SIZE
	return _tile_to_world(Vector2i(e.x, e.y))

# Point-type entities (npc/npc_existing/prop) are checked first, within a
# tight radius, so a small NPC standing near/inside a large building's
# footprint is still selectable — otherwise the building's wide bounding
# box would always win and you could never grab the NPC again.
func _find_entity_at(tile: Vector2i, world_pos: Vector2):
	var best_point = null
	var best_point_dist := INF
	for e in entities:
		if e.type == "building_existing":
			continue
		var e_pos = _entity_anchor_world(e)
		var d = world_pos.distance_to(e_pos)
		if d < TILE_SIZE * 0.8 and d < best_point_dist:
			best_point = e
			best_point_dist = d
	if best_point:
		return best_point
	for e in entities:
		if e.type != "building_existing":
			continue
		var fw: int = e.get("fw", 1)
		var fh: int = e.get("fh", 1)
		if tile.x >= e.x and tile.x < e.x + fw and tile.y >= e.y and tile.y < e.y + fh:
			return e
	return null

# Interaction (talking to NPCs, quests) reads from world.NPCS[i].tile, NOT
# from the visual sprite position. Dragging an NPC only moved the sprite;
# without this, the NPC would render in the new spot but be un-interactable
# there (and still interactable in its old, now-empty spot).
func _sync_npc_tile_in_world(npc_id: String, new_tile: Vector2i) -> void:
	if world == null:
		return
	for npc in world.NPCS:
		if npc.id == npc_id:
			var old_tile: Vector2i = npc.tile
			if _wd_in_bounds(old_tile):
				world.walkable[old_tile.y][old_tile.x] = true
			npc.tile = new_tile
			if _wd_in_bounds(new_tile):
				world.walkable[new_tile.y][new_tile.x] = false
			return

func _wd_in_bounds(t: Vector2i) -> bool:
	return world != null and t.x >= 0 and t.x < world.COLS and t.y >= 0 and t.y < world.ROWS

# world.path_mask/walkable are strictly-typed Array[Array of bool]; JSON
# always deserializes as loosely-typed Array/Variant, so a direct assignment
# (world.path_mask = json_array) raises "Invalid assignment ... on typed
# array". Copy values in place, row by row, instead of replacing the array.
func _assign_bool_grid(target: Array, source: Array) -> void:
	for y in range(min(target.size(), source.size())):
		var src_row = source[y]
		for x in range(min(target[y].size(), src_row.size())):
			target[y][x] = bool(src_row[x])

func _on_mouse_motion(world_pos: Vector2) -> void:
	if dragged_entity:
		var target_anchor: Vector2 = world_pos + drag_offset
		if dragged_entity.type == "building_existing":
			var fw: int = dragged_entity.get("fw", 1)
			var fh: int = dragged_entity.get("fh", 1)
			var raw_col := int(target_anchor.x / TILE_SIZE - fw / 2.0)
			var raw_row := int(target_anchor.y / TILE_SIZE - fh)
			var top_left := Vector2i(raw_col, raw_row)
			var bottom_right := Vector2i(raw_col + fw - 1, raw_row + fh - 1)
			if _in_bounds(top_left) and _in_bounds(bottom_right):
				dragged_entity.x = raw_col
				dragged_entity.y = raw_row
				dragged_entity.node.position = Vector2(raw_col + fw / 2.0, raw_row + fh) * TILE_SIZE
				dragged_entity.node.set_meta("footprint_col", raw_col)
				dragged_entity.node.set_meta("footprint_row", raw_row)
		else:
			var raw_tile = Vector2i(int(target_anchor.x / TILE_SIZE), int(target_anchor.y / TILE_SIZE))
			if _in_bounds(raw_tile):
				dragged_entity.x = raw_tile.x
				dragged_entity.y = raw_tile.y
				dragged_entity.node.position = _tile_to_world(raw_tile)
				if dragged_entity.type == "npc_existing":
					dragged_entity.node.set_meta("tile_x", raw_tile.x)
					dragged_entity.node.set_meta("tile_y", raw_tile.y)
					_sync_npc_tile_in_world(dragged_entity.id, raw_tile)

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
		var hit := false
		if e.type == "building_existing":
			var fw: int = e.get("fw", 1)
			var fh: int = e.get("fh", 1)
			hit = tile.x >= e.x and tile.x < e.x + fw and tile.y >= e.y and tile.y < e.y + fh
		else:
			hit = e.x == tile.x and e.y == tile.y
		if hit:
			e.node.queue_free()
			entities.remove_at(i)
			return

var panel_ref: PanelContainer
var panel_open: bool = true
var ui_layer: CanvasLayer
var ground_swatch_row: HBoxContainer
const PANEL_WIDTH := 340.0

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UI"
	ui_layer.visible = false
	add_child(ui_layer)
	var layer = ui_layer

	var toggle_btn = Button.new()
	toggle_btn.text = "<"
	toggle_btn.position = Vector2(PANEL_WIDTH + 4, 10)
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
	tool_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(tool_hbox)
	for t in ["select", "paint", "erase", "collision", "npc", "building", "prop"]:
		var btn = Button.new()
		btn.text = t.capitalize()
		btn.custom_minimum_size = Vector2(52, 24)
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
	flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	if collision_layer:
		collision_layer.visible = (t == "collision")
		if t == "collision":
			_redraw_collision_overlay()

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
	# New items placed through the editor (props/new buildings/npcs) are
	# saved as full entities; the original world_data.gd buildings/npcs
	# ("*_existing") are only saved as position OVERRIDES if they were
	# actually moved — re-adding them as new entities would duplicate them.
	var ent_data = []
	var moved_existing = []
	for e in entities:
		if e.type in ["building_existing", "npc_existing"]:
			moved_existing.append({"id": e.id, "type": e.type, "x": e.x, "y": e.y})
			continue
		ent_data.append({"id": e.id, "type": e.type, "x": e.x, "y": e.y})
	var data = {
		"version": 2,
		"cols": COLS,
		"rows": ROWS,
		"entities": ent_data,
		"moved_existing": moved_existing,
		"path_mask": world.path_mask if world else [],
		"walkable": world.walkable if world else [],
	}
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()
		if status_label:
			status_label.text = "Saved " + str(ent_data.size()) + " new item(s) + terrain to " + path

# Reapplies a previously saved map: new props/buildings/npcs placed through
# the editor, plus any terrain/collision edits (path_mask/walkable). Safe to
# call at boot (auto-load) — it never touches the pre-existing world_data.gd
# entities, only re-adds items this editor placed and were saved.
func load_map(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var j = JSON.new()
	var parse_err := j.parse(f.get_as_text())
	f.close()
	if parse_err != OK:
		push_warning("Map editor: failed to parse " + path)
		return
	var d = j.data
	if typeof(d) != TYPE_DICTIONARY:
		return
	if world and d.has("path_mask") and d.path_mask is Array and d.path_mask.size() == world.ROWS:
		_assign_bool_grid(world.path_mask, d.path_mask)
		if d.has("walkable") and d.walkable is Array and d.walkable.size() == world.ROWS:
			_assign_bool_grid(world.walkable, d.walkable)
		if map_renderer and map_renderer.has_method("rebuild_tilemap"):
			map_renderer.rebuild_tilemap()
		_sync_grid_from_world()
	if d.has("entities"):
		# Clear only editor-placed items (never *_existing world_data ones)
		for i in range(entities.size() - 1, -1, -1):
			if entities[i].type not in ["building_existing", "npc_existing"]:
				entities[i].node.queue_free()
				entities.remove_at(i)
		for ed in d.entities:
			_add_entity(ed.type, ed.id, Vector2i(ed.x, ed.y))
	if d.has("moved_existing"):
		# Applied directly against world.NPCS / the real building containers
		# in the scene tree — NOT against `entities`, because load_map runs
		# at boot before the editor UI (and _register_existing_entities)
		# has ever populated that array.
		for m in d.moved_existing:
			var new_tile := Vector2i(m.x, m.y)
			if m.type == "npc_existing":
				_sync_npc_tile_in_world(m.id, new_tile)
				var npc_node = get_parent().get_node_or_null("NPCGroup_" + m.id)
				if npc_node:
					npc_node.position = _tile_to_world(new_tile)
					npc_node.set_meta("tile_x", new_tile.x)
					npc_node.set_meta("tile_y", new_tile.y)
			elif m.type == "building_existing":
				var b_node = get_parent().get_node_or_null("BuildingGroup_" + m.id)
				if b_node:
					var fw: int = b_node.get_meta("footprint_w", 1)
					var fh: int = b_node.get_meta("footprint_h", 1)
					b_node.position = Vector2(new_tile.x + fw / 2.0, new_tile.y + fh) * TILE_SIZE
					b_node.set_meta("footprint_col", new_tile.x)
					b_node.set_meta("footprint_row", new_tile.y)
	if status_label:
		status_label.text = "Loaded map from " + path

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
	toggle_btn.position.x = (PANEL_WIDTH + 4) if panel_open else 0
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
