extends SceneTree

var failures := 0

func expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  "))

func collision_matrix(rows: int = 20, cols: int = 30) -> Array:
	var matrix := []
	for y in rows:
		var row := []
		for x in cols:
			row.append(1 if x == 15 else 0)
		matrix.append(row)
	return matrix

func make_single_pack(name: String) -> String:
	var directory := "user://world_pack_tests/" + name
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var image := Image.create(1440, 960, false, Image.FORMAT_RGBA8)
	image.fill(Color("#527c43"))
	image.save_png(directory.path_join("background.png"))
	write_json(directory.path_join("collision.json"), {"walkable": collision_matrix()})
	write_json(directory.path_join("anchors.json"), {
		"spawn": {"tile": [15, 6]},
		"npcs": [{"id": "vera", "display_name": "Dra. Vera", "tile": [24, 7], "sprite": "res://assets/characters/world1/vera-idle.png", "dialogue": "Olá"}],
		"buildings": [{"id": "clinic", "tile": [23, 8]}]
	})
	write_json(directory.path_join("manifest.json"), {
		"contract_version": 1,
		"world_id": "world1",
		"version": "1.0.0-test",
		"tile_size": 48,
		"cols": 30,
		"rows": 20,
		"width_px": 1440,
		"height_px": 960,
		"art": {"mode": "single", "file": "background.png"},
		"collision": {"file": "collision.json"},
		"anchors": {"file": "anchors.json"}
	})
	return directory

func make_chunk_pack(name: String) -> String:
	var directory := make_single_pack(name)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory.path_join("background.png")))
	var files := []
	for y in 2:
		for x in 2:
			var filename := "chunk_%d_%d.png" % [x, y]
			var image := Image.create(720, 480, false, Image.FORMAT_RGBA8)
			image.fill(Color("#4f7840"))
			image.save_png(directory.path_join(filename))
			files.append(filename)
	write_json(directory.path_join("manifest.json"), {
		"contract_version": 1,
		"world_id": "world1",
		"version": "1.0.0-chunks",
		"tile_size": 48,
		"cols": 30,
		"rows": 20,
		"width_px": 1440,
		"height_px": 960,
		"art": {"mode": "chunks", "grid_cols": 2, "grid_rows": 2, "chunk_width_px": 720, "chunk_height_px": 480, "files": files},
		"collision": {"file": "collision.json"},
		"anchors": {"file": "anchors.json"}
	})
	return directory

func _initialize() -> void:
	var implementation := "res://scripts/world_data.gd"
	expect(FileAccess.file_exists(implementation), "world data implementation exists")
	if not FileAccess.file_exists(implementation):
		finish()
		return

	var WorldData = load(implementation)
	var world = WorldData.new()
	expect(world.COLS == 30, "world has 30 columns")
	expect(world.ROWS == 20, "world has 20 rows")
	expect(world.world_size_px() == Vector2i(1440, 960), "world is exactly 1440x960 pixels")
	expect(world.walkable.size() == 20 and world.walkable[0].size() == 30, "collision matrix is the single 30x20 map source")
	expect(world.is_walkable(world.SPAWN), "spawn is walkable")
	expect(world.is_walkable(world.SPAWN + Vector2i(1, 0)), "player can walk east from spawn")
	expect(not world.is_walkable(Vector2i(-1, 8)), "left world boundary blocks movement")
	expect(not world.is_walkable(Vector2i(30, 8)), "right world boundary blocks movement")
	expect(not world.is_walkable(Vector2i(0, 0)), "blocked matrix tile rejects movement")
	expect(world.camera_limits() == Rect2i(0, 0, 1440, 960), "camera limits match compact world")
	expect(world.NPCS.size() == 6, "all 6 World 1 NPCs configured")
	expect(not world.is_walkable(world.NPCS[0].tile), "NPC tile blocks movement")
	var adjacent_npc = world.get_adjacent_npc(world.NPCS[0].tile + Vector2i(1, 0))
	expect(adjacent_npc.size() > 0, "NPC adjacent detection works")
	expect(world.interaction_text(world.NPCS[0].tile + Vector2i(1, 0)).length() > 0, "NPC interaction returns dialogue")
	expect(not world.get_adjacent_npc(world.SPAWN).size(), "no NPC near spawn")

	var movement_path := "res://scripts/player_movement.gd"
	expect(FileAccess.file_exists(movement_path), "player movement implementation exists")
	if FileAccess.file_exists(movement_path):
		var PlayerMovement = load(movement_path)
		var movement = PlayerMovement.new()
		var spawn_px: Vector2i = world.SPAWN * world.TILE_SIZE + Vector2i(world.TILE_SIZE / 2, world.TILE_SIZE / 2)
		expect(movement.next_position(Vector2(spawn_px), Vector2.RIGHT, 0.1, world).x > spawn_px.x, "four-direction movement advances on walkable terrain")
		var blocked_px := Vector2(24, 24)
		expect(movement.next_position(blocked_px, Vector2.LEFT, 1.0, world) == blocked_px, "movement cannot enter blocked or out-of-bounds tiles")

	var scene_path := "res://scenes/main.tscn"
	expect(FileAccess.file_exists(scene_path), "playable main scene exists")
	if FileAccess.file_exists(scene_path):
		var packed: PackedScene = load(scene_path)
		var scene = packed.instantiate()
		expect(scene.name == "TownvilleWorld1", "main scene instantiates as World 1")
		expect(scene.has_method("build_world"), "scene exposes world construction")
		scene.free()
	finish()

func finish() -> void:
	if failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TEST FAILURES: ", failures)
		quit(1)
