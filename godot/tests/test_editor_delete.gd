extends SceneTree
# Does the editor's save/export drop items that were deleted? Both for
# editor-placed props and for pre-existing world_data buildings/NPCs.

var fails := 0
func expect(ok: bool, msg: String) -> void:
	if ok: print("PASS: " + msg)
	else: fails += 1; push_error("FAIL: " + msg)

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var ed = game.map_editor
	ed.toggle()  # registers existing entities
	await process_frame

	var path := "user://_test_del.json"
	# 1. place two props, delete one, save → only one in file
	ed._add_entity("prop", "tree", Vector2i(10, 10))
	ed._add_entity("prop", "stone", Vector2i(11, 10))
	ed._remove_entity_at(Vector2i(10, 10))
	ed.save_map(path)
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	var ids := []
	for e in d.entities: ids.append(e.id)
	expect(ids == ["stone"], "deleted prop is NOT in save (entities=%s)" % [ids])

	# 2. delete a pre-existing building (stable) and an existing NPC, save
	var n_before = ed.entities.size()
	ed._remove_entity_at(Vector2i(13, 2))   # stable footprint
	ed._remove_entity_at(Vector2i(14, 4))   # chester standing tile
	expect(ed.entities.size() == n_before - 2, "existing building + npc removed from editor list")
	ed.save_map(path)
	d = JSON.parse_string(FileAccess.get_file_as_string(path))
	print("save keys: ", d.keys())
	var deleted: Array = d.get("deleted_existing", [])
	expect("stable" in deleted and "chester" in deleted, "save records deleted EXISTING items (deleted_existing=%s)" % [deleted])

	# 3. reload → stable/chester must stay gone
	ed.load_map(path)
	await process_frame
	var stable_node = game.get_node_or_null("BuildingGroup_stable")
	var chester_node = game.get_node_or_null("NPCGroup_chester")
	var chester_in_world := false
	for n in game.world.NPCS: if n.id == "chester": chester_in_world = true
	expect((stable_node == null or not stable_node.visible) and (chester_node == null or not chester_node.visible) and not chester_in_world,
		"after load, deleted existing building/NPC do not come back")

	# 4. export (download JSON) also excludes deleted
	var ent_ids := []
	for e in ed.entities: ent_ids.append(e.id)
	expect(not ("stable" in ent_ids) and not ("chester" in ent_ids) and not ("tree" in ent_ids), "export list excludes deleted items")

	# 5. simulate a RESTART: brand-new scene auto-loads user://map.json at boot
	ed.save_map("user://map.json")
	game.queue_free()
	await process_frame
	var game2 = packed.instantiate()
	root.add_child(game2)
	await process_frame
	await process_frame
	var st2 = game2.get_node_or_null("BuildingGroup_stable")
	var ch2 = game2.get_node_or_null("NPCGroup_chester")
	var ch_world := false
	for n in game2.world.NPCS: if n.id == "chester": ch_world = true
	expect((st2 == null or st2.is_queued_for_deletion()) and (ch2 == null or ch2.is_queued_for_deletion()) and not ch_world, "after RESTART, deleted stable + chester stay deleted")
	expect(game2.world.is_walkable(Vector2i(13, 2)) == true, "deleted building's footprint is walkable again after restart")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://map.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("ALL TESTS PASSED" if fails == 0 else "TEST FAILURES: %d" % fails)
	quit(0 if fails == 0 else 1)
