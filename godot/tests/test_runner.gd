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
	expect(world.NPCS.size() == 8, "all 8 World 1 NPCs configured")
	expect(not world.is_walkable(world.NPCS[0].tile), "NPC tile blocks movement")
	var adjacent_npc = world.get_adjacent_npc(world.NPCS[0].tile + Vector2i(1, 0))
	expect(adjacent_npc.size() > 0, "NPC adjacent detection works")
	expect(world.interaction_text(world.NPCS[0].tile + Vector2i(1, 0)).length() > 0, "NPC interaction returns dialogue")
	expect(not world.get_adjacent_npc(world.SPAWN).size(), "no NPC near spawn")

	# --- Exercise script: 4 phases × 8 NPCs, values from TOWNVILLE-w1-exercise-script.md ---
	var expected := {
		"mae": [7, 7, 12, 3], "chester": [11, 6, 6, 5], "farmer-joe": [11, 8, 20, 6],
		"lily": [7, 5, 8, 5], "grandma-rose": [12, 8, 12, 4], "billy": [10, 6, 12, 3],
		"vera": [11, 6, 6, 3], "old-mac": [9, 6, 12, 5],
	}
	var all_ok := true
	for npc in world.NPCS:
		var ex: Array = npc.get("exercises", [])
		if ex.size() != 4:
			all_ok = false
			continue
		for i in 4:
			var e: Dictionary = ex[i]
			var want_mode: String = ["basket_in", "basket_out", "text", "text"][i]
			if e.mode != want_mode or int(e.answer) != expected[npc.id][i] or e.phase != i + 1:
				all_ok = false
			if e.mode == "basket_in" and int(e.a) + int(e.b) != int(e.answer):
				all_ok = false
			if e.mode == "basket_out" and int(e.start) - int(e.remove) != int(e.answer):
				all_ok = false
			if e.setup.is_empty() or e.success.is_empty() or e.hint1.is_empty():
				all_ok = false
	expect(all_ok, "every NPC has 4 exercises (in/out/text/text) with the scripted answers")
	expect(world.get_phase("mae") == 0 and world.get_current_exercise(world.NPCS[0]).phase == 1, "NPC starts at phase 1")
	world.advance_phase("mae")
	expect(world.get_current_exercise(world.NPCS[0]).phase == 2, "advance_phase moves to phase 2")
	for i in 5: world.advance_phase("mae")
	expect(world.is_npc_complete("mae") and world.get_current_exercise(world.NPCS[0]).is_empty(), "phase caps at 4 → complete, no more exercises")
	world.npc_phase.clear()

	# --- InteractionFlow: run the full loop headlessly (dialogue → exercise → feedback → map) ---
	var FlowScript = load("res://scripts/ui/interaction_flow.gd")
	var flow = FlowScript.new()
	flow.world = world
	root.add_child(flow)
	await process_frame
	var mae: Dictionary = world.NPCS[0]
	expect(flow.state_name() == "map" and not flow.is_locked(), "flow boots in MAP, input unlocked")
	flow.start(mae)
	expect(flow.state_name() == "dialogue" and flow.is_locked(), "E next to NPC → DIALOGUE, movement locked")
	expect(flow.dialogue_screen.visible and not flow.exercise_screen.visible and not flow.feedback_screen.visible, "only DialogueScreen visible")
	flow.advance_dialogue()  # skip typewriter
	expect(not flow.is_typing and flow.dialogue_text.visible_ratio == 1.0, "tap while typing → full text")
	flow.advance_dialogue()  # → exercise
	expect(flow.state_name() == "exercise" and flow.exercise.mode == "basket_in", "dialogue dismissed → EXERCISE phase 1 basket_in")
	expect(not flow.dialogue_screen.visible and flow.exercise_screen.visible, "dialogue hidden, exercise visible (no overlap)")
	expect(flow.basket_count == 4 and flow.source_items.get_child_count() == 3, "basket pre-filled 4, 3 draggable eggs outside")
	# wrong drop target does nothing
	flow.debug_drag_one("TrayDropZone")
	expect(flow.basket_count == 4, "dropping outside the basket is ignored")
	for i in 3: flow.debug_drag_one("BasketDropZone")
	expect(flow.basket_count == 7 and flow.source_items.get_child_count() == 0 and flow.state_name() == "exercise", "3 drags in → basket 7, still in EXERCISE until Done")
	flow.debug_done()
	expect(flow.state_name() == "feedback" and flow.last_correct, "Done with 7 → FEEDBACK correct")
	expect(flow.result_label.text == "Seven eggs! That's a great morning for the hens.", "success line from script")
	await create_timer(2.0).timeout
	expect(flow.state_name() == "map" and world.get_phase("mae") == 1, "feedback auto-dismiss → MAP, phase advanced to 2")

	# phase 2 basket_out with a WRONG attempt first
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.exercise.mode == "basket_out" and flow.basket_count == 9, "phase 2: 9 eggs in basket, drag out")
	for i in 3: flow.debug_drag_one("TrayDropZone")  # 3 out instead of 2
	flow.debug_done()
	expect(flow.state_name() == "feedback" and not flow.last_correct, "Done with 3 out (6 left) → wrong feedback")
	await create_timer(2.0).timeout
	expect(flow.state_name() == "exercise" and flow.exercise.mode == "basket_out", "wrong → back to SAME exercise, not map")
	expect(flow.hint_label.visible and flow.hint_label.text.contains("one egg out first"), "tier-1 hint shown after 1st wrong")
	flow.debug_drag_one("TrayDropZone"); flow.debug_done()  # 1 out → 8 left, wrong again
	await create_timer(2.0).timeout
	expect(flow.wrong_attempts == 2 and (flow.basket_zone.get_child(0).get_node("Ghost") as Label).visible, "tier-2 ghost numeral after 2nd wrong")
	for i in 2: flow.debug_drag_one("TrayDropZone")
	flow.debug_done()
	expect(flow.state_name() == "feedback" and flow.last_correct, "2 out → 7 left → correct")
	await create_timer(2.0).timeout
	expect(world.get_phase("mae") == 2, "phase 2 done")

	# phase 3 text with numeric filter + wrong then right
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.exercise.mode == "text" and flow.text_row.visible and not flow.basket_row.visible, "phase 3 → text input layout")
	flow.answer_input.text = "1a2"
	flow._digits_only("1a2")
	expect(flow.answer_input.text == "12", "non-digits stripped from input")
	flow.debug_submit("11")
	await create_timer(2.0).timeout
	expect(flow.state_name() == "exercise" and flow.hint_label.text.contains("4 + 4 + 4"), "wrong text answer → tier-1 hint")
	flow.debug_submit("10")
	await create_timer(2.0).timeout
	expect(flow.icon_grid.visible and flow.icon_grid.get_child_count() == 12 and flow.icon_grid.columns == 4, "2nd wrong → 3×4 icon grid")
	flow.debug_submit("12")
	await create_timer(2.0).timeout
	expect(world.get_phase("mae") == 3 and flow.state_name() == "map", "phase 3 correct → phase 4 unlocked")
	flow.start(mae); flow.advance_dialogue(); flow.advance_dialogue()
	flow.debug_submit("3")
	await create_timer(2.0).timeout
	expect(world.is_npc_complete("mae"), "phase 4 correct → Mae complete (4/4)")
	flow.start(mae)
	expect(flow.dialogue_text.text.begins_with("Thanks for all your help"), "completed NPC shows thank-you line")
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.state_name() == "map", "completed NPC dialogue returns to map")
	flow.queue_free()
	world.npc_phase.clear()

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
