extends SceneTree

var failures := 0

func expect(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func effective_z(group: CanvasItem, visual: CanvasItem) -> int:
	return group.z_index + visual.z_index if visual.z_as_relative else visual.z_index

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var player: CanvasItem = game.player
	var player_visual: CanvasItem = game.player.sprite
	var player_z := effective_z(player, player_visual)

	# The player must always draw over every NPC, except Old Mac who stands
	# at the gate and shares the player's Y-sort layer (same mechanism as
	# the clinic building) so the player can walk behind him.
	for npc in game.world.NPCS:
		var group := game.get_node("NPCGroup_" + npc.id) as CanvasItem
		var visual := group.get_node("NPC_" + npc.id) as CanvasItem
		var npc_z := effective_z(group, visual)
		if npc.id == "old-mac":
			expect(player_z == npc_z, "Old Mac shares player depth layer for Y sorting")
		else:
			expect(player_z > npc_z, "player renders in front of NPC " + npc.id)

	# Only the clinic participates in player/building Y sorting. Every other
	# building is always behind the player.
	for building in game.world.BUILDINGS:
		var group := game.get_node("BuildingGroup_" + building.id) as CanvasItem
		var visual := group.get_node("Building_" + building.id) as CanvasItem
		var building_z := effective_z(group, visual)
		if building.id == "clinic":
			expect(player_z == building_z, "clinic shares player depth layer for Y sorting")
		else:
			expect(player_z > building_z, "player renders in front of building " + building.id)

	expect(game.y_sort_enabled, "world Y sorting remains enabled for the clinic")
	game.queue_free()
	await process_frame
	print("ALL TESTS PASSED" if failures == 0 else "TEST FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
