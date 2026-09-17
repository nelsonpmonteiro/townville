class_name MapEditor
extends Node2D

const TILE_SIZE := 48
const COLS := 32
const ROWS := 24
const SAVE_DIR := "res://saves/"

const WorldData = preload("res://scripts/world_data.gd")
const WangTilerScript = preload("res://scripts/editor/wang_tiler.gd")
const EditorPaletteScript = preload("res://scripts/editor/palette.gd")
const EditorCameraScript = preload("res://scripts/editor/editor_camera.gd")

var wang_tiler = WangTilerScript.new()
var palette = EditorPaletteScript.new()

# Map data
var grid: Array[Array] = []       # terrain: "" | "grass" | "dirt" | "water"
var npc_placements: Array[Dictionary] = []
var building_placements: Array[Dictionary] = []
var prop_placements: Array[Dictionary] = []  # scenery props

# Tile rendering
var tilemap: TileMapLayer
var grass_dirt_tileset: TileSetAtlasSource
var water_grass_tileset: TileSetAtlasSource

# Editor state
var active_tool: String = "paint"   # "paint" | "erase" | "npc" | "building" | "prop"
var active_terrain_set: String = "grass_dirt"
var active_terrain_value: String = "grass"
var active_npc_id: String = ""
var active_building_id: String = ""
var active_prop_id: String = ""

# UI references
var tilemap_parent: Node2D
var sprite_parent: Node2D
var camera: Camera2D
var ui_root: Control
var status_label: Label

signal map_saved(path: String)
signal map_loaded(path: String)
signal tile_painted(tile: Vector2i, terrain: String)
signal tile_erased(tile: Vector2i)
signal npc_placed(tile: Vector2i, npc_id: String)
signal building_placed(tile: Vector2i, building_id: String)

func _init() -> void:
	_build_grid()

func _ready() -> void:
	_setup_scene()
	_build_ui()
	_render_full_map()

func _setup_scene() -> void:
	tilemap_parent = Node2D.new()
	tilemap_parent.name = "TileMapParent"
	add_child(tilemap_parent)

	sprite_parent = Node2D.new()
	sprite_parent.name = "SpriteParent"
	sprite_parent.z_index = 5
	add_child(sprite_parent)

	_build_tilemap()
	_build_camera()

func _build_grid() -> void:
	grid.clear()
	for y in ROWS:
		var row: Array[String] = []
		row.resize(COLS)
		row.fill("grass")  # default terrain
		grid.append(row)

func _build_tilemap() -> void:
	tilemap = TileMapLayer.new()
	tilemap.name = "MapEditorTileMap"
	tilemap.scale = Vector2.ONE * 3.0  # 16px * 3 = 48px

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	grass_dirt_tileset = _build_atlas_source("res://assets/terrain/tileset-grass-dirt.png")
	water_grass_tileset = _build_atlas_source("res://assets/terrain/tileset-water-grass.png")

	if grass_dirt_tileset:
		tileset.add_source(grass_dirt_tileset, 0)
	if water_grass_tileset:
		tileset.add_source(water_grass_tileset, 1)

	tilemap.tile_set = tileset
	tilemap_parent.add_child(tilemap)

func _build_atlas_source(path: String) -> TileSetAtlasSource:
	var tex := load(path) as Texture2D
	if tex == null:
		push_error("Cannot load tileset: " + path)
		return null

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(16, 16)
	source.margins = Vector2i.ZERO
	source.separation = Vector2i.ZERO

	for y in 4:
		for x in 4:
			source.create_tile(Vector2i(x, y))

	return source

func _build_camera() -> void:
	camera = EditorCameraScript.new()
	camera.name = "EditorCamera"
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = COLS * TILE_SIZE
	camera.limit_bottom = ROWS * TILE_SIZE
	add_child(camera)

func _build_ui() -> void:
	ui_root = Control.new()
	ui_root.name = "EditorUI"
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(ui_root)

	# Top toolbar
	var toolbar := HBoxContainer.new()
	toolbar.name = "Toolbar"
	toolbar.position = Vector2(8, 8)
	toolbar.add_theme_constant_override("separation", 6)
	ui_root.add_child(toolbar)

	# Tool buttons
	var btn_paint := Button.new()
	btn_paint.text = "Paint"
	btn_paint.pressed.connect(_on_tool_selected.bind("paint"))
	toolbar.add_child(btn_paint)

	var btn_erase := Button.new()
	btn_erase.text = "Erase"
	btn_erase.pressed.connect(_on_tool_selected.bind("erase"))
	toolbar.add_child(btn_erase)

	var btn_npc := Button.new()
	btn_npc.text = "NPC"
	btn_npc.pressed.connect(_on_tool_selected.bind("npc"))
	toolbar.add_child(btn_npc)

	var btn_building := Button.new()
	btn_building.text = "Building"
	btn_building.pressed.connect(_on_tool_selected.bind("building"))
	toolbar.add_child(btn_building)

	var btn_prop := Button.new()
	btn_prop.text = "Prop"
	btn_prop.pressed.connect(_on_tool_selected.bind("prop"))
	toolbar.add_child(btn_prop)

	# Separator
	toolbar.add_child(VSeparator.new())

	# Save / Load
	var btn_save := Button.new()
	btn_save.text = "Save"
	btn_save.pressed.connect(_on_save_pressed)
	toolbar.add_child(btn_save)

	var btn_load := Button.new()
	btn_load.text = "Load"
	btn_load.pressed.connect(_on_load_pressed)
	toolbar.add_child(btn_load)

	# Separator
	toolbar.add_child(VSeparator.new())

	# New
	var btn_new := Button.new()
	btn_new.text = "New"
	btn_new.pressed.connect(_on_new_pressed)
	toolbar.add_child(btn_new)

	# Camera reset
	var btn_reset_cam := Button.new()
	btn_reset_cam.text = "Reset View"
	btn_reset_cam.pressed.connect(func(): camera.reset_view())
	toolbar.add_child(btn_reset_cam)

	# Left palette panel
	var palette_panel := VBoxContainer.new()
	palette_panel.name = "PalettePanel"
	palette_panel.position = Vector2(8, 50)
	palette_panel.size = Vector2(180, 400)
	palette_panel.add_theme_constant_override("separation", 4)
	ui_root.add_child(palette_panel)

	# Terrain palette
	var terrain_label := Label.new()
	terrain_label.text = "Terrain"
	palette_panel.add_child(terrain_label)

	var grass_btn := Button.new()
	grass_btn.text = "Grass"
	grass_btn.pressed.connect(_on_terrain_selected.bind("grass_dirt", "grass"))
	palette_panel.add_child(grass_btn)

	var dirt_btn := Button.new()
	dirt_btn.text = "Dirt"
	dirt_btn.pressed.connect(_on_terrain_selected.bind("grass_dirt", "dirt"))
	palette_panel.add_child(dirt_btn)

	var water_btn := Button.new()
	water_btn.text = "Water"
	water_btn.pressed.connect(_on_terrain_selected.bind("water_grass", "water"))
	palette_panel.add_child(water_btn)

	# NPC palette
	palette_panel.add_child(HSeparator.new())
	var npc_label := Label.new()
	npc_label.text = "NPCs"
	palette_panel.add_child(npc_label)

	for i in palette.get_npc_count():
		var npc = palette.get_npc(i)
		var npc_btn := Button.new()
		npc_btn.text = npc.display_name
		npc_btn.pressed.connect(_on_npc_selected.bind(npc.id))
		palette_panel.add_child(npc_btn)

	# Building palette
	palette_panel.add_child(HSeparator.new())
	var bldg_label := Label.new()
	bldg_label.text = "Buildings"
	palette_panel.add_child(bldg_label)

	for i in palette.get_building_count():
		var bldg = palette.get_building(i)
		var bldg_btn := Button.new()
		bldg_btn.text = bldg.label
		bldg_btn.pressed.connect(_on_building_selected.bind(bldg.id))
		palette_panel.add_child(bldg_btn)

	# Prop palette (scenery)
	palette_panel.add_child(HSeparator.new())
	var prop_label := Label.new()
	prop_label.text = "Props"
	palette_panel.add_child(prop_label)

	var prop_names := ["Tree", "Rock", "Bush", "Flower", "Fence"]
	for pname in prop_names:
		var prop_btn := Button.new()
		prop_btn.text = pname
		prop_btn.pressed.connect(_on_prop_selected.bind(pname.to_lower()))
		palette_panel.add_child(prop_btn)

	# Status label (bottom)
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.position = Vector2(8, 520)
	status_label.text = "Ready"
	ui_root.add_child(status_label)

func _on_tool_selected(tool: String) -> void:
	active_tool = tool
	_set_status("Tool: " + tool)

func _on_terrain_selected(set_id: String, value: String) -> void:
	active_terrain_set = set_id
	active_terrain_value = value
	active_tool = "paint"
	_set_status("Terrain: " + value)

func _on_npc_selected(npc_id: String) -> void:
	active_npc_id = npc_id
	active_tool = "npc"
	_set_status("Place NPC: " + npc_id)

func _on_building_selected(bldg_id: String) -> void:
	active_building_id = bldg_id
	active_tool = "building"
	_set_status("Place Building: " + bldg_id)

func _on_prop_selected(prop_id: String) -> void:
	active_prop_id = prop_id
	active_tool = "prop"
	_set_status("Place Prop: " + prop_id)

func _on_save_pressed() -> void:
	save_map(SAVE_DIR + "map_default.json")

func _on_load_pressed() -> void:
	load_map(SAVE_DIR + "map_default.json")

func _on_new_pressed() -> void:
	_build_grid()
	npc_placements.clear()
	building_placements.clear()
	prop_placements.clear()
	_clear_sprites()
	_render_full_map()
	_set_status("New map created")

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos := get_global_mouse_position()
			var tile := _world_to_tile(mouse_pos)
			_handle_tile_click(tile)

func _handle_tile_click(tile: Vector2i) -> void:
	if not _in_bounds(tile):
		return

	match active_tool:
		"paint":
			paint_tile(tile, active_terrain_value)
		"erase":
			erase_tile(tile)
		"npc":
			if not active_npc_id.is_empty():
				place_npc(tile, active_npc_id)
		"building":
			if not active_building_id.is_empty():
				place_building(tile, active_building_id)
		"prop":
			if not active_prop_id.is_empty():
				place_prop(tile, active_prop_id)

## --- Terrain painting ------------------------------------------------

func paint_tile(tile: Vector2i, terrain: String) -> void:
	if not _in_bounds(tile):
		return
	var x: int = tile.x
	var y: int = tile.y
	grid[y][x] = terrain
	_update_tile_cell(x, y)
	_recompute_neighbors(tile)
	tile_painted.emit(tile, terrain)

func erase_tile(tile: Vector2i) -> void:
	paint_tile(tile, "grass")
	tile_erased.emit(tile)

func get_tile_terrain(tile: Vector2i) -> String:
	if not _in_bounds(tile):
		return ""
	return grid[tile.y][tile.x]

func _update_tile_cell(x: int, y: int) -> void:
	if tilemap == null:
		return
	var terrain: String = grid[y][x]
	var source_id: int = 0  # default: grass_dirt
	if terrain == "water":
		source_id = 1
	# Determine corners from neighbors
	var corners: Array = _get_corners(x, y)
	var wang_id: int = wang_tiler.get_wang_id(corners)
	var atlas_col: int = wang_id % 4
	var atlas_row: int = wang_id / 4
	tilemap.set_cell(Vector2i(x, y), source_id, Vector2i(atlas_col, atlas_row))

func _get_corners(x: int, y: int) -> Array:
	var center: String = grid[y][x]
	var nw: String = _corner_at(x - 1, y - 1, center)
	var ne: String = _corner_at(x + 1, y - 1, center)
	var sw: String = _corner_at(x - 1, y + 1, center)
	var se: String = _corner_at(x + 1, y + 1, center)
	return [nw, ne, sw, se]

func _corner_at(x: int, y: int, center_terrain: String) -> String:
	if x < 0 or x >= COLS or y < 0 or y >= ROWS:
		return "upper"  # out-of-bounds treated as grass
	var t: String = grid[y][x]
	# If neighbor matches center, use upper (full tile), else lower (edge)
	if t == center_terrain:
		return "upper"
	else:
		return "lower"

func _recompute_neighbors(center: Vector2i) -> void:
	var offsets: Array[Vector2i] = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
				   Vector2i(-1, 0),                  Vector2i(1, 0),
				   Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)]
	for off in offsets:
		var nx: int = center.x + off.x
		var ny: int = center.y + off.y
		if nx >= 0 and nx < COLS and ny >= 0 and ny < ROWS:
			_update_tile_cell(nx, ny)

func _render_full_map() -> void:
	if tilemap == null:
		return
	tilemap.clear()
	for y in ROWS:
		for x in COLS:
			_update_tile_cell(x, y)

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / TILE_SIZE), floori(world_pos.y / TILE_SIZE))

func _in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.x < COLS and tile.y >= 0 and tile.y < ROWS

## --- NPC / Building / Prop placement --------------------------------

func place_npc(tile: Vector2i, npc_id: String) -> void:
	if not _in_bounds(tile):
		return
	# Remove any existing NPC at this tile
	npc_placements.assign(npc_placements.filter(func(p: Dictionary) -> bool: return p.tile != tile))
	npc_placements.append({"id": npc_id, "tile": tile})
	_refresh_sprite("NPC", npc_id, tile)
	npc_placed.emit(tile, npc_id)

func place_building(tile: Vector2i, bldg_id: String) -> void:
	if not _in_bounds(tile):
		return
	building_placements.assign(building_placements.filter(func(p: Dictionary) -> bool: return p.tile != tile))
	building_placements.append({"id": bldg_id, "tile": tile})
	_refresh_sprite("Building", bldg_id, tile)
	building_placed.emit(tile, bldg_id)

func place_prop(tile: Vector2i, prop_id: String) -> void:
	if not _in_bounds(tile):
		return
	prop_placements.assign(prop_placements.filter(func(p: Dictionary) -> bool: return p.tile != tile))
	prop_placements.append({"id": prop_id, "tile": tile})
	_refresh_sprite("Prop", prop_id, tile)

func get_npc_at(tile: Vector2i) -> Dictionary:
	for p in npc_placements:
		if p.tile == tile:
			return {"id": p.id, "tile": p.tile}
	return {}

func get_building_at(tile: Vector2i) -> Dictionary:
	for p in building_placements:
		if p.tile == tile:
			return {"id": p.id, "tile": p.tile}
	return {}

func get_prop_at(tile: Vector2i) -> Dictionary:
	for p in prop_placements:
		if p.tile == tile:
			return {"id": p.id, "tile": p.tile}
	return {}

func _refresh_sprite(category: String, obj_id: String, tile: Vector2i) -> void:
	if sprite_parent == null:
		return
	var node_name: String = "%s_%s" % [category, obj_id]
	# Remove old sprite
	var existing: Node = sprite_parent.get_node_or_null(node_name)
	if existing:
		existing.queue_free()
	# Create new sprite
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.position = Vector2(tile * TILE_SIZE) + Vector2.ONE * (TILE_SIZE / 2)
	sprite.z_index = 10
	# Try to load texture
	var tex_path: String = _get_sprite_path(category, obj_id)
	if tex_path != "" and ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)
	sprite_parent.add_child(sprite)

func _get_sprite_path(category: String, obj_id: String) -> String:
	if category == "NPC":
		for npc in WorldData.NPCS:
			if npc.id == obj_id:
				return npc.sprite_path
	elif category == "Building":
		for b in WorldData.BUILDINGS:
			if b.id == obj_id:
				return b.sprite
	return ""

func _clear_sprites() -> void:
	if sprite_parent == null:
		return
	for child in sprite_parent.get_children():
		child.queue_free()

## --- Save / Load ----------------------------------------------------

func save_map(path: String) -> void:
	var dir_path: String = path.get_base_dir()
	if dir_path != SAVE_DIR.trim_suffix("/"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))

	# Convert Vector2i tiles to arrays for clean JSON
	var serialized_npcs: Array[Dictionary] = []
	for p in npc_placements:
		serialized_npcs.append({"id": p.id, "tile": [p.tile.x, p.tile.y]})
	var serialized_bldgs: Array[Dictionary] = []
	for p in building_placements:
		serialized_bldgs.append({"id": p.id, "tile": [p.tile.x, p.tile.y]})
	var serialized_props: Array[Dictionary] = []
	for p in prop_placements:
		serialized_props.append({"id": p.id, "tile": [p.tile.x, p.tile.y]})

	var data: Dictionary = {
		"version": 1,
		"cols": COLS,
		"rows": ROWS,
		"tile_size": TILE_SIZE,
		"grid": grid,
		"npc_placements": serialized_npcs,
		"building_placements": serialized_bldgs,
		"prop_placements": serialized_props
	}

	var json: String = JSON.stringify(data, "	")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open file for writing: " + path + " error: " + str(FileAccess.get_open_error()))
		return
	file.store_string(json)
	file.close()
	map_saved.emit(path)
	_set_status("Saved: " + path)
	print("Map saved to: " + path)

func load_map(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("File not found: " + path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open file: " + path)
		return

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result: int = json.parse(text)
	if parse_result != OK:
		push_error("Failed to parse JSON: " + path)
		return

	var data: Dictionary = json.data

	# Validate dimensions
	if data.get("cols", COLS) != COLS or data.get("rows", ROWS) != ROWS:
		push_error("Map dimensions mismatch")
		return

	# Load grid
	if data.has("grid"):
		var loaded_grid: Array = data.grid
		for y in range(min(ROWS, loaded_grid.size())):
			var row: Array = loaded_grid[y]
			for x in range(min(COLS, row.size())):
				grid[y][x] = row[x]

	# Load placements — convert tile fields from serialized dict to Vector2i
	npc_placements = _deserialize_placements(data.get("npc_placements", []))
	building_placements = _deserialize_placements(data.get("building_placements", []))
	prop_placements = _deserialize_placements(data.get("prop_placements", []))

	_render_full_map()
	_reload_sprites()
	map_loaded.emit(path)
	_set_status("Loaded: " + path)
	print("Map loaded from: " + path)

func _reload_sprites() -> void:
	_clear_sprites()
	for p in npc_placements:
		_refresh_sprite("NPC", p.id, p.tile)
	for p in building_placements:
		_refresh_sprite("Building", p.id, p.tile)
	for p in prop_placements:
		_refresh_sprite("Prop", p.id, p.tile)

## Deserialize placement entries, converting tile arrays back to Vector2i
static func _deserialize_placements(raw: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in raw:
		var d: Dictionary = item as Dictionary
		var entry := d.duplicate()
		# JSON stores Vector2i as {"x": N, "y": N} or array [N, N]
		var tile_val = entry.get("tile")
		if tile_val is Array and tile_val.size() == 2:
			entry["tile"] = Vector2i(int(tile_val[0]), int(tile_val[1]))
		elif tile_val is Dictionary and tile_val.has("x") and tile_val.has("y"):
			entry["tile"] = Vector2i(int(tile_val["x"]), int(tile_val["y"]))
		result.append(entry)
	return result
