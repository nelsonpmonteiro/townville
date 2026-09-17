extends SceneTree

var failures := 0

func expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var implementation := "res://scripts/world_data.gd"
	expect(FileAccess.file_exists(implementation), "world data implementation exists")
	if not FileAccess.file_exists(implementation):
		finish()
		return

	var WorldData = load(implementation)
	var world = WorldData.new()
	expect(world.COLS == 32, "world has 32 columns")
	expect(world.ROWS == 24, "world has 24 rows")
	expect(world.world_size_px() == Vector2i(1536, 1152), "world is exactly 1536x1152 pixels")
	expect(world.walkable.size() == 24 and world.walkable[0].size() == 32, "collision matrix is the single 32x24 map source")
	expect(world.is_walkable(world.SPAWN), "spawn is walkable")
	expect(world.is_walkable(world.SPAWN + Vector2i(1, 0)), "player can walk east from spawn")
	expect(not world.is_walkable(Vector2i(-1, 8)), "left world boundary blocks movement")
	expect(not world.is_walkable(Vector2i(32, 8)), "right world boundary blocks movement")
	expect(not world.is_walkable(Vector2i(0, 0)), "blocked matrix tile rejects movement")
	expect(world.camera_limits() == Rect2i(0, 0, 1536, 1152), "camera limits match compact world")
	expect(world.NPC.id == "vera", "current World 1 NPC is configured")
	expect(not world.is_walkable(world.NPC.tile), "NPC occupancy is represented in the same collision matrix")
	expect(world.is_npc_near(Vector2i(20, 12)), "NPC interaction works from an adjacent tile")
	expect(world.interaction_text(Vector2i(20, 12)).contains("Vera"), "NPC interaction returns demonstrative dialogue")

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
