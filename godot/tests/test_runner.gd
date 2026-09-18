extends SceneTree

var failures := 0

func expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func has_sequential_count_badges(container: Control) -> bool:
	if container == null:
		return true
	var expected := 1
	for child in container.get_children():
		var badge := child.get_node_or_null("CountBadge") as Label
		if badge == null or badge.text != str(expected):
			return false
		expected += 1
	return true

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

	# The committed editor export is authoritative. Compare both 30x20 layers
	# cell-by-cell against the raw constants, before runtime NPC/building
	# footprint blocking is applied.
	var snapshot_text := FileAccess.get_file_as_string("res://artifacts/townville_map_export.json")
	var snapshot = JSON.parse_string(snapshot_text)
	var snapshot_exact := snapshot is Dictionary
	if snapshot_exact:
		snapshot_exact = snapshot.get("rows", 0) == world.ROWS and snapshot.get("cols", 0) == world.COLS
	if snapshot_exact:
		var dirt: Array = snapshot.get("path_mask", [])
		var collision: Array = snapshot.get("walkable", [])
		snapshot_exact = dirt.size() == world.ROWS and collision.size() == world.ROWS
		if snapshot_exact:
			for y in world.ROWS:
				if dirt[y].size() != world.COLS or collision[y].size() != world.COLS:
					snapshot_exact = false
					break
				for x in world.COLS:
					if bool(dirt[y][x]) != (world.EDITOR_DIRT[y][x] == ".") or bool(collision[y][x]) != (world.EDITOR_WALKABLE[y][x] == "."):
						snapshot_exact = false
						break
	expect(snapshot_exact, "runtime terrain and collision match the authoritative editor JSON tile-for-tile")
	expect(world.COLS == 30, "world has 30 columns")
	expect(world.ROWS == 20, "world has 20 rows")
	expect(world.world_size_px() == Vector2i(1440, 960), "world is exactly 1440x960 pixels")
	expect(world.walkable.size() == 20 and world.walkable[0].size() == 30, "collision matrix is the single 30x20 map source")
	expect(world.SPAWN == Vector2i(15, 19), "player starts west-adjacent to Old Mac's gate")
	expect(world.is_walkable(world.SPAWN), "spawn is walkable")
	expect(world.is_walkable(world.SPAWN + Vector2i(0, -1)), "player can walk north from spawn (toward farm)")
	expect(not world.is_walkable(Vector2i(-1, 8)), "left world boundary blocks movement")
	expect(not world.is_walkable(Vector2i(30, 8)), "right world boundary blocks movement")
	expect(not world.is_walkable(Vector2i(0, 0)), "blocked matrix tile rejects movement")
	expect(world.camera_limits() == Rect2i(0, 0, 1440, 960), "camera limits match compact world")
	expect(world.NPCS.size() == 8, "all 8 World 1 NPCs configured")
	expect(not world.is_walkable(world.NPCS[0].tile), "NPC tile blocks movement")
	var adjacent_npc = world.get_adjacent_npc(world.NPCS[0].tile + Vector2i(1, 0))
	expect(adjacent_npc.size() > 0, "NPC adjacent detection works")
	expect(world.interaction_text(world.NPCS[0].tile + Vector2i(1, 0)).length() > 0, "NPC interaction returns dialogue")
	# Old Mac stands at the bottom gate entrance (diagonally adjacent to spawn),
	# so a fresh player sees the gate NPC immediately.
	expect(world.get_adjacent_npc(world.SPAWN).size() > 0, "gate NPC (Old Mac) is adjacent to the entrance spawn")

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
			var want_mode: String = ["basket_in", "basket_out", "array", "share"][i]
			if e.mode != want_mode or int(e.answer) != expected[npc.id][i] or e.phase != i + 1:
				all_ok = false
			if e.mode == "basket_in" and int(e.a) + int(e.b) != int(e.answer):
				all_ok = false
			if e.mode == "basket_out" and int(e.start) - int(e.remove) != int(e.answer):
				all_ok = false
			if e.setup.is_empty() or e.success.is_empty() or e.hint1.is_empty():
				all_ok = false
	expect(all_ok, "every NPC has 4 exercises (in/out/array/share) with the scripted answers")
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

	# Every basket exercise shares the same move/renumber path. Exercise all
	# 8 NPCs in both directions and validate after EACH drop (including undo)
	# so labels always match current container position with no gaps/repeats.
	for basket_npc in world.NPCS:
		var npc_id: String = basket_npc.id
		world.npc_phase[npc_id] = 0
		flow.start(basket_npc)
		flow.advance_dialogue(); flow.advance_dialogue()
		flow.debug_hint()
		var addition_numbers_ok := has_sequential_count_badges(flow.source_items) and has_sequential_count_badges(flow.basket_items)
		var needed: int = int(flow.exercise.answer) - int(flow.exercise.a)
		for i in needed:
			flow.debug_drag_one("BasketDropZone")
			addition_numbers_ok = addition_numbers_ok and has_sequential_count_badges(flow.source_items) and has_sequential_count_badges(flow.basket_items)
		flow.debug_drag_one_from(flow.basket_items, "SourceDropZone")
		addition_numbers_ok = addition_numbers_ok and has_sequential_count_badges(flow.source_items) and has_sequential_count_badges(flow.basket_items)
		flow.debug_drag_one("BasketDropZone")
		addition_numbers_ok = addition_numbers_ok and has_sequential_count_badges(flow.source_items) and has_sequential_count_badges(flow.basket_items)
		expect(addition_numbers_ok, "%s phase 1 renumbers source and basket after every forward/reverse drop" % npc_id)

		world.npc_phase[npc_id] = 1
		flow.start(basket_npc)
		flow.advance_dialogue(); flow.advance_dialogue()
		flow.debug_hint()
		var subtraction_numbers_ok := has_sequential_count_badges(flow.basket_items) and has_sequential_count_badges(flow.tray_items)
		var remove_count: int = int(flow.exercise.remove)
		for i in remove_count:
			flow.debug_drag_one("TrayDropZone")
			subtraction_numbers_ok = subtraction_numbers_ok and has_sequential_count_badges(flow.basket_items) and has_sequential_count_badges(flow.tray_items)
		flow.debug_drag_one_from(flow.tray_items, "BasketDropZone")
		subtraction_numbers_ok = subtraction_numbers_ok and has_sequential_count_badges(flow.basket_items) and has_sequential_count_badges(flow.tray_items)
		flow.debug_drag_one("TrayDropZone")
		subtraction_numbers_ok = subtraction_numbers_ok and has_sequential_count_badges(flow.basket_items) and has_sequential_count_badges(flow.tray_items)
		expect(subtraction_numbers_ok, "%s phase 2 renumbers basket and tray after every forward/reverse drop" % npc_id)
	world.npc_phase.clear()

	flow.start(mae)
	expect(flow.state_name() == "dialogue" and flow.is_locked(), "E next to NPC → DIALOGUE, movement locked")
	expect(flow.dialogue_screen.visible and not flow.exercise_screen.visible and not flow.feedback_screen.visible, "only DialogueScreen visible")
	flow.cancel_dialogue()
	expect(flow.state_name() == "map" and not flow.is_locked(), "Escape/cancel closes dialogue and returns to MAP")
	flow.start(mae)
	flow.advance_dialogue()  # skip typewriter
	expect(not flow.is_typing and flow.dialogue_text.visible_ratio == 1.0, "tap while typing → full text")
	flow.advance_dialogue()  # → exercise
	expect(flow.exercise.mode == "basket_in", "dialogue dismissed → EXERCISE phase 1 basket_in")
	expect(not flow.dialogue_screen.visible and flow.exercise_screen.visible, "dialogue hidden, exercise visible (no overlap)")
	# Mae: a=4, b=3, answer=7. Needed = answer - a = 3, pool = needed + POOL_EXTRA(3) = 6.
	expect(flow.basket_count == 4 and flow.source_items.get_child_count() == 6, "basket pre-filled 4, pool has 6 draggable eggs (3 needed + 3 extra, so dragging everything overshoots)")
	expect(flow.basket_counter.text == "Basket", "basket label is plain, no live count")
	expect(flow.source_title.text == "Nest", "pool label is themed and plain, no live count — child must count the pictures")
	expect(flow.source_panel.find_child("ItemsScroll", true, false) == null and flow.basket_zone.find_child("ItemsScroll", true, false) == null and flow.basket_items.get_parent() == flow.basket_zone.get_child(0), "basket/source item rows expand their panels directly — no internal scroll containers")
	# wrong drop target does nothing
	flow.debug_drag_one("TrayDropZone")
	expect(flow.basket_count == 4, "dropping outside the basket is ignored")
	# No auto-resolve: the child can drag past the target and it's still
	# EXERCISE until they press Done — free experimentation, not a trap.
	for i in 4: flow.debug_drag_one("BasketDropZone")
	expect(flow.basket_count == 8 and flow.state_name() == "exercise", "dragging past the target does NOT auto-resolve — child can keep adjusting")
	flow.debug_done()
	expect(flow.state_name() == "feedback" and not flow.last_correct, "pressing Done at the wrong count (8) is caught at submit time")
	await create_timer(2.0).timeout
	expect(flow.state_name() == "exercise" and flow.hint_label.visible, "wrong feedback returns to the SAME exercise with hint tier 1")
	# _open_exercise() resets the layout back to its starting state (basket
	# 4, pool 6) on every wrong attempt, so undo the freshly-reset basket
	# back down from there rather than relying on the pre-reset counts.
	expect(flow.basket_count == 4 and flow.source_items.get_child_count() == 6, "wrong attempt resets the layout back to its starting counts")
	var addition_feedback_before: int = flow.pop_events
	for i in 4: flow.debug_drag_one("BasketDropZone")
	expect(flow.basket_count == 8, "re-overshoot after the reset")
	flow.debug_drag_one_from(flow.basket_items, "SourceDropZone")
	expect(flow.basket_count == 7 and flow.source_items.get_child_count() == 3, "dragging a basket item back to the pool undoes one addition")
	expect(flow.pop_events - addition_feedback_before == 4, "every item added to the basket emits placement sound feedback")
	expect(flow.state_name() == "exercise", "still in EXERCISE until Done — no auto-resolve on reaching the target either")
	expect(flow.basket_row.visible and not flow.addition_summary.visible and not flow.equation_label.visible, "no numeric summary/equation shown while still dragging")
	flow.debug_done()
	# ONE success screen: congratulation, the NPC's line and the equation
	# together, replacing the exercise instead of queueing a second panel.
	expect(flow.state_name() == "exercise" and not flow.basket_row.visible and flow.equation_label.visible and flow.equation_label.text.contains("4 + 3 = 7"), "Done at the correct count reveals the success screen with the equation")
	expect(flow.success_title.visible and flow.success_title.text.contains("Congrats"), "success screen congratulates the child")
	expect(flow.success_message.text == "Seven eggs! That's a great morning for the hens.", "success line from script, on that same screen")
	expect(not flow.feedback_screen.visible, "no separate feedback panel for a correct answer")
	expect(flow.done_btn.text == "Continue", "success screen uses Continue, not another Done")
	flow.debug_done()
	expect(flow.state_name() == "map" and flow.last_correct, "Continue closes the success screen straight to the MAP")
	expect(world.get_phase("mae") == 1, "phase advanced to 2")

	# phase 2 basket_out: same free-drag, submit-to-validate mechanic, reversed.
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.exercise.mode == "basket_out" and flow.basket_count == 9, "phase 2: 9 eggs in basket, drag out")
	expect(flow.basket_counter.text == "Basket", "basket_out basket label is also plain, no live count")
	var subtraction_feedback_before: int = flow.pop_events
	flow.debug_drag_one("TrayDropZone")
	flow.debug_drag_one("TrayDropZone")
	expect(flow.pop_events - subtraction_feedback_before == 2, "every item removed from the basket emits placement sound feedback")
	expect(flow.basket_count == 7 and flow.state_name() == "exercise", "2 out → 7 left, still in EXERCISE until Done")
	expect(flow.tray_label.text == "Grandma Rose", "removal tray label is plain too, no running count")
	expect(flow.basket_row.visible and not flow.equation_label.visible, "subtraction stays live in basket/tray squares until Done")
	flow.debug_drag_one("TrayDropZone")  # 3rd out → 6, undershoots — but no auto-resolve
	expect(flow.basket_count == 6 and flow.state_name() == "exercise", "dragging past the target does NOT auto-resolve for subtraction either")
	flow.debug_drag_one_from(flow.tray_items, "BasketDropZone")  # drag one back from tray to basket (undo)
	expect(flow.basket_count == 7 and flow.tray_items.get_child_count() == 2, "dragging a tray item back to the basket undoes one removal")
	flow.debug_done()
	expect(flow.equation_label.visible and flow.equation_label.text.contains("9 - 2 = 7"), "Done at the correct count reveals the success screen with the equation")
	expect(flow.success_title.visible and flow.success_message.text == "Seven left to sell - perfect!", "subtraction celebrates on that same screen")
	expect(flow.done_btn.text == "Continue", "success screen uses Continue, not another Done")
	flow.debug_done()
	expect(flow.state_name() == "map" and flow.last_correct, "Continue closes the success screen straight to the MAP")
	expect(world.get_phase("mae") == 2, "phase 2 done")

	# Hint button (phases 1-2): opt-in only, tracked per exercise.
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.exercise.mode == "array", "phase 3 is multiplication (array)")
	# The array pool's item count IS the answer, so it is offered as a hint
	# rather than printed above the pool by default.
	expect(flow.hint_btn.visible, "array offers a hint button too")
	expect(not flow.visual_source_title.visible, "array pool count stays hidden until the child asks")
	# Temporarily rewind to phase 1 just to exercise the hint button on a
	# basket exercise, then restore phase 2 (Mae's real progress at this
	# point in the suite) so the phase 3/4 tests below continue correctly.
	world.npc_phase["mae"] = 0
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.hint_btn.visible and not flow.hint_btn.disabled, "hint button visible and enabled at the start of a basket exercise")
	expect(flow.hints_used_this_exercise == 0, "no hints used yet")
	flow.debug_hint()
	expect(flow.hints_used_this_exercise == 1 and flow.hint_btn.disabled, "requesting a hint increments the per-exercise counter and disables re-request")
	expect(flow.hint_label.visible, "hint text shown on request")
	expect(flow.basket_items.get_child(0).get_node_or_null("CountBadge") != null, "hint numbers the pictured basket items for counting support")
	world.npc_phase["mae"] = 2

	# phase 3 multiplication: build the array physically, no typed answer
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.exercise.mode == "array" and flow.visual_row.visible and not flow.text_row.visible, "phase 3 uses the visual array layout")
	expect(flow.visual_cells.size() == 12 and flow.visual_source_items.get_child_count() == 12, "3x4 array starts empty with 12 draggable items")
	flow.debug_done()
	expect(flow.state_name() == "exercise" and flow.hint_label.visible, "incomplete array gives a gentle hint without leaving the exercise")
	var feedback_before: int = flow.pop_events
	for i in 12:
		flow.debug_drag_one("ArrayCell_%d" % i)
	expect(flow.pop_events - feedback_before == 12 and flow.bump_events >= 12, "each placed item emits gentle sound and rising-count feedback")
	expect(flow.visual_source_items.get_child_count() == 0 and not flow.equation_label.visible, "completed 3x4 array waits for Done before revealing success")
	flow.debug_done()
	expect(flow.state_name() == "exercise" and flow.success_title.visible and flow.equation_label.text.contains("3 x 4 = 12"), "completed multiplication uses the persistent success screen")
	expect(not flow.feedback_screen.visible and flow.done_btn.text == "Continue", "array success does not use the timed feedback overlay")
	flow.debug_done()
	expect(world.get_phase("mae") == 3 and flow.state_name() == "map", "Continue unlocks phase 4")

	# phase 4 division: deal items one by one into equal groups
	flow.start(mae); flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.exercise.mode == "share" and flow.share_zones.size() == 4, "phase 4 shows one drop zone per equal group")
	expect(flow.visual_source_items.get_child_count() == 12, "division starts with the full collection available to share")
	flow.debug_drag_one("ShareZone_0"); flow.debug_drag_one("ShareZone_0")
	flow.debug_done()
	expect(flow.state_name() == "exercise" and flow.hint_label.visible and flow.share_titles[0].text.contains("?"), "unequal sharing stays editable and marks the imbalance without Game Over")
	for group_index in [1, 2, 3]:
		for i in 3:
			flow.debug_drag_one("ShareZone_%d" % group_index)
	flow.debug_drag_one("ShareZone_0")
	expect(not flow.equation_label.visible, "equal groups wait for Done before revealing success")
	flow.debug_done()
	expect(flow.state_name() == "exercise" and flow.success_title.visible and flow.equation_label.text.contains("12 / 4 = 3"), "division uses the persistent success screen")
	expect(not flow.feedback_screen.visible and flow.done_btn.text == "Continue", "division success does not use the timed feedback overlay")
	flow.debug_done()
	expect(world.is_npc_complete("mae"), "Continue completes Mae phase 4")
	flow.start(mae)
	expect(flow.dialogue_text.text.begins_with("Thanks for all your help"), "completed NPC shows thank-you line")
	flow.advance_dialogue(); flow.advance_dialogue()
	expect(flow.state_name() == "map", "completed NPC dialogue returns to map")
	flow.queue_free()
	world.npc_phase.clear()

	# --- Onboarding: first launch shows title + 2 cards, flag persists, repeat skips ---
	var OnboardScript = load("res://scripts/ui/onboarding.gd")
	OnboardScript.reset_save()
	expect(not OnboardScript.has_seen_onboarding(), "fresh state: onboarding not seen")
	var ob = OnboardScript.new()
	root.add_child(ob)
	await process_frame
	ob.start()
	expect(ob.active and ob.title_box.visible and not ob.card_box.visible, "title screen first")
	ob.advance()
	expect(ob.card_box.visible and ob.card_text.text.contains("these keys") and ob.direction_keys.visible and not ob.card_icon.visible, "card 1 uses a visual directional-key diagram")
	expect(ob.back_button.visible and ob.next_button.visible, "onboarding exposes Back and Next navigation")
	ob.advance()
	expect(ob.card_text.text.contains("press E"), "card 2 = interaction")
	ob.back()
	expect(ob.card_text.text.contains("these keys") and ob.direction_keys.visible, "Back returns to the previous onboarding card")
	ob.advance()
	expect(ob.next_button.text == "Play", "interaction card is the final onboarding card")
	ob.advance()
	await create_timer(0.6).timeout
	expect(not ob.active and not ob.visible, "after card 2 → fade out, inactive")
	expect(OnboardScript.has_seen_onboarding(), "onboarding flag persisted to user://save_data.cfg")
	ob.queue_free()
	OnboardScript.reset_save()

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
