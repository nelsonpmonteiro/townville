extends SceneTree
# Reproduce the user's real flow: F1 → drag Mae → F1 (close) → F1 (open) → Export.
# Does the export carry Mae's NEW tile? And after Save + restart?

var fails := 0
func expect(ok: bool, msg: String) -> void:
	if ok: print("PASS: " + msg)
	else: fails += 1; push_error("FAIL: " + msg)

func mae_in(list: Array) -> Variant:
	for e in list: if e.id == "mae": return e
	return null

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var ed = game.map_editor
	var test_export_path := "user://test_townville_map_export.json"
	ed.native_export_path = test_export_path
	var orig: Vector2i = mae_in(game.world.NPCS).tile
	var target := orig + Vector2i(2, 1)

	ed.toggle()                       # F1 open
	ed.tool = "select"
	var e = mae_in(ed.entities)
	ed.dragged_entity = e
	ed.drag_offset = Vector2.ZERO
	ed._on_mouse_motion(Vector2(target) * ed.TILE_SIZE + Vector2.ONE * 4)  # drag
	ed.dragged_entity = null          # release
	expect(mae_in(ed.entities).x == target.x and mae_in(ed.entities).y == target.y, "drag updates editor entity")
	expect(mae_in(game.world.NPCS).tile == target, "drag updates world.NPCS")

	ed.toggle()                       # F1 close
	ed.toggle()                       # F1 open again
	e = mae_in(ed.entities)
	expect(e.x == target.x and e.y == target.y, "after F1 close/open, editor still has Mae at NEW tile (%s,%s vs %s)" % [e.x, e.y, target])

	# Save → writes user://map.json AND the downloaded JSON (same bytes)
	ed.save_map("user://map.json")
	var saved := FileAccess.get_file_as_string("user://map.json")
	var downloaded := FileAccess.get_file_as_string(test_export_path)
	expect(saved == downloaded and saved.length() > 100, "Save writes browser save AND downloads the SAME json")
	var d = JSON.parse_string(saved)
	var mm = mae_in(d.get("moved_existing", []))
	expect(mm != null and mm.x == target.x and mm.y == target.y, "downloaded JSON has Mae at NEW tile")
	expect(d.has("walkable") and d.has("path_mask") and d.has("deleted_existing"), "downloaded JSON has terrain + deletions (v2)")

	# Import that JSON into a DIFFERENT fresh game (what I do when you send it)
	var g3 = packed.instantiate(); root.add_child(g3); await process_frame
	g3.map_editor.load_map(test_export_path)
	await process_frame
	expect(mae_in(g3.world.NPCS).tile == target, "importing the downloaded JSON puts Mae at NEW tile")
	g3.queue_free(); await process_frame
	game.queue_free(); await process_frame
	var g2 = packed.instantiate(); root.add_child(g2); await process_frame; await process_frame
	expect(mae_in(g2.world.NPCS).tile == target, "after restart Mae is at NEW tile (%s)" % [mae_in(g2.world.NPCS).tile])
	var node = g2.get_node("NPCGroup_mae")
	expect(Vector2i(node.get_meta("tile_x"), node.get_meta("tile_y")) == target, "after restart Mae's node meta at NEW tile")
	g2.map_editor.toggle()
	var e2 = mae_in(g2.map_editor.entities)
	expect(e2.x == target.x and e2.y == target.y, "after restart, editor registers Mae at NEW tile → Export would be right")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://map.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_export_path))
	print("ALL TESTS PASSED" if fails == 0 else "TEST FAILURES: %d" % fails)
	quit(0 if fails == 0 else 1)
