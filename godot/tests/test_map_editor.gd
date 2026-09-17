extends SceneTree

var failures := 0

func expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	test_files_exist()
	test_wang_tiler()
	test_palette()
	test_editor_camera()
	test_map_editor()
	test_save_load_roundtrip()

	finish()

func finish() -> void:
	if failures == 0:
		print("ALL MAP EDITOR TESTS PASSED")
		quit(0)
	else:
		print("MAP EDITOR TEST FAILURES: ", failures)
		quit(1)


# ------------------------------------------------------------
# 1. File existence
# ------------------------------------------------------------
func test_files_exist() -> void:
	expect(FileAccess.file_exists("res://scripts/editor/map_editor.gd"), "map_editor.gd exists")
	expect(FileAccess.file_exists("res://scripts/editor/palette.gd"), "palette.gd exists")
	expect(FileAccess.file_exists("res://scripts/editor/wang_tiler.gd"), "wang_tiler.gd exists")
	expect(FileAccess.file_exists("res://scripts/editor/editor_camera.gd"), "editor_camera.gd exists")
	expect(FileAccess.file_exists("res://scenes/editor/map_editor.tscn"), "map_editor.tscn exists")


# ------------------------------------------------------------
# 2. Wang tile neighbour analysis
# ------------------------------------------------------------
func test_wang_tiler() -> void:
	var WangTiler = load("res://scripts/editor/wang_tiler.gd")
	expect(WangTiler != null, "wang_tiler.gd loads as a script")
	if WangTiler == null:
		return

	var tiler = WangTiler.new()
	expect(tiler != null, "wang_tiler.gd can be instantiated")

	# All four corners grass ("upper") = 0 (no edges)
	expect(tiler.get_wang_id(["upper", "upper", "upper", "upper"]) == 0,
		"all-grass corners map to Wang id 0")

	# All four corners dirt ("lower") = 15 (all edges)
	expect(tiler.get_wang_id(["lower", "lower", "lower", "lower"]) == 15,
		"all-dirt corners map to Wang id 15")

	# SE corner only is dirt (lower) = bit 0 = 1
	expect(tiler.get_wang_id(["upper", "upper", "upper", "lower"]) == 1,
		"single-SE-dirt corner maps to Wang id 1")

	# Neighbour analysis: tile surrounded by same terrain should pick full tile
	var grid := {
		0: "grass", 1: "grass", 2: "grass",
		3: "grass", 4: "grass", 5: "grass",
		6: "grass", 7: "grass", 8: "grass"
	}
	expect(tiler.analyze_neighbors(grid, 1, 1, 3) == 0,
		"tile surrounded by grass maps to Wang id 0")

	# Neighbour analysis: tile with all dirt neighbors
	var grid2 := {
		0: "dirt", 1: "dirt", 2: "dirt",
		3: "dirt", 4: "dirt", 5: "dirt",
		6: "dirt", 7: "dirt", 8: "dirt"
	}
	expect(tiler.analyze_neighbors(grid2, 1, 1, 3) == 15,
		"tile surrounded by dirt maps to Wang id 15")


# ------------------------------------------------------------
# 3. Palette management
# ------------------------------------------------------------
func test_palette() -> void:
	var Palette = load("res://scripts/editor/palette.gd")
	expect(Palette != null, "palette.gd loads as a script")
	if Palette == null:
		return

	var palette = Palette.new()
	expect(palette != null, "palette.gd can be instantiated")

	# NPC palette should have 8 entries
	expect(palette.get_npc_count() == 8, "palette lists all 8 NPCs")

	# Building palette should have 6 entries
	expect(palette.get_building_count() == 6, "palette lists all 6 buildings")

	# Tile palette should have grass-dirt and water-grass sets
	expect(palette.get_terrain_set_count() >= 2, "palette has at least 2 terrain sets")

	# Getters should return valid data
	var npc = palette.get_npc(0)
	expect(npc.has("id") and npc.has("sprite_path"), "palette NPC entries have id and sprite_path")

	var building = palette.get_building(0)
	expect(building.has("id") and building.has("sprite"), "palette building entries have id and sprite")


# ------------------------------------------------------------
# 4. Editor camera
# ------------------------------------------------------------
func test_editor_camera() -> void:
	var EditorCamera = load("res://scripts/editor/editor_camera.gd")
	expect(EditorCamera != null, "editor_camera.gd loads as a script")
	if EditorCamera == null:
		return

	var camera = EditorCamera.new()
	expect(camera != null, "editor_camera.gd can be instantiated")
	expect(camera is Camera2D, "editor_camera extends Camera2D")

	# Pan: position should change after pan
	var start_pos: Vector2 = camera.position
	camera.pan(Vector2(100, 50))
	expect(camera.position.x == start_pos.x + 100 and camera.position.y == start_pos.y + 50,
		"pan translates camera position")

	# Zoom: clamp to min/max bounds
	camera.set_zoom_level(0.1)
	expect(camera.zoom.x >= camera.MIN_ZOOM, "zoom clamps to MIN_ZOOM")
	camera.set_zoom_level(100.0)
	expect(camera.zoom.x <= camera.MAX_ZOOM, "zoom clamps to MAX_ZOOM")


# ------------------------------------------------------------
# 5. Map editor
# ------------------------------------------------------------
func test_map_editor() -> void:
	var MapEditor = load("res://scripts/editor/map_editor.gd")
	expect(MapEditor != null, "map_editor.gd loads as a script")
	if MapEditor == null:
		return

	var editor = MapEditor.new()
	expect(editor != null, "map_editor.gd can be instantiated")
	expect(editor.has_method("paint_tile"), "editor has paint_tile method")
	expect(editor.has_method("erase_tile"), "editor has erase_tile method")
	expect(editor.has_method("place_npc"), "editor has place_npc method")
	expect(editor.has_method("place_building"), "editor has place_building method")
	expect(editor.has_method("save_map"), "editor has save_map method")
	expect(editor.has_method("load_map"), "editor has load_map method")

	# Painting a tile at (5,5) should change the grid
	editor.paint_tile(Vector2i(5, 5), "grass")
	expect(editor.get_tile_terrain(Vector2i(5, 5)) == "grass",
		"paint_tile sets terrain at tile coordinate")

	# Painting a different terrain
	editor.paint_tile(Vector2i(5, 5), "dirt")
	expect(editor.get_tile_terrain(Vector2i(5, 5)) == "dirt",
		"paint_tile can change terrain to dirt")

	# Erasing should reset to grass (the default/empty state)
	editor.erase_tile(Vector2i(5, 5))
	expect(editor.get_tile_terrain(Vector2i(5, 5)) == "grass",
		"erase_tile resets terrain to default grass")

	# Placing an NPC should register it
	editor.place_npc(Vector2i(10, 10), "mae")
	var npc_result = editor.get_npc_at(Vector2i(10, 10))
	expect(npc_result.id == "mae",
		"place_npc registers NPC at tile coordinate")

	# Placing a building should register it
	editor.place_building(Vector2i(15, 15), "barn")
	var bldg_result = editor.get_building_at(Vector2i(15, 15))
	expect(bldg_result.id == "barn",
		"place_building registers building at tile coordinate")


# ------------------------------------------------------------
# 6. Save / load round-trip
# ------------------------------------------------------------
func test_save_load_roundtrip() -> void:
	var MapEditor = load("res://scripts/editor/map_editor.gd")
	if MapEditor == null:
		return

	# Create editor and paint some data
	var editor1 = MapEditor.new()
	editor1.paint_tile(Vector2i(1, 1), "grass")
	editor1.paint_tile(Vector2i(2, 2), "dirt")
	editor1.place_npc(Vector2i(10, 10), "chester")
	editor1.place_building(Vector2i(15, 15), "barn")

	var test_path := "res://saves/test_roundtrip.json"
	editor1.save_map(test_path)
	expect(FileAccess.file_exists(test_path), "save_map creates JSON file on disk")

	# Create a second editor and load the saved file
	var editor2 = MapEditor.new()
	editor2.load_map(test_path)
	expect(editor2.get_tile_terrain(Vector2i(1, 1)) == "grass",
		"loaded map preserves tile at (1,1)")
	expect(editor2.get_tile_terrain(Vector2i(2, 2)) == "dirt",
		"loaded map preserves tile at (2,2)")
	var loaded_npc = editor2.get_npc_at(Vector2i(10, 10))
	expect(loaded_npc.id == "chester",
		"loaded map preserves NPC placement")
	var loaded_bldg = editor2.get_building_at(Vector2i(15, 15))
	expect(loaded_bldg.id == "barn",
		"loaded map preserves building placement")

	# Cleanup
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
