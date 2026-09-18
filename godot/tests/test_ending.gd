extends SceneTree
## End-of-demo message after Old Mac's final phase.
##
## The rules being locked in here:
##   1. it reuses the SAME dialogue box as every NPC — not a new "game over"
##      screen — so the child reads it in a language they already know;
##   2. it is ASCII-only (no emoji), because the Web export's default font
##      renders emoji as tofu boxes;
##   3. dismissing it returns the player to a LIVE map: free to walk, and free
##      to revisit any NPC and replay their dialogue. Nothing locks or darkens.

var failures := 0

func expect(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var flow = game.flow

	# --- the copy itself ---
	var body: String = flow.ENDING_BODY
	var title: String = flow.ENDING_TITLE
	expect(title.contains("You did it"), "leads with the child's accomplishment")
	expect(body.contains("helped everyone in Townville"), "names what they achieved")
	expect(body.to_lower().contains("come back soon"), "invites a return visit")
	expect(not body.to_lower().contains("demo") and not body.to_lower().contains("beta")
		and not body.to_lower().contains("preview"),
		"no production jargon (demo/beta/preview) a child cannot parse")
	for text in [title, body]:
		var ascii_only := true
		for i in text.length():
			if text.unicode_at(i) > 127:
				ascii_only = false
		expect(ascii_only, "ending copy is ASCII-only so the Web font cannot tofu it")

	# --- the ending fires only when the WHOLE farm is complete ---
	var old_mac: Dictionary = {}
	for n in game.world.NPCS:
		if n.id == "old-mac":
			old_mac = n
	var ending_emissions := [0]
	flow.world_completed.connect(func(): ending_emissions[0] += 1)

	# Completing Old Mac after a fresh restart must NOT end the game while the
	# other seven NPCs are incomplete.
	game.world.npc_phase.clear()
	game.world.npc_phase["old-mac"] = 3
	flow.start(old_mac)
	flow.advance_dialogue(); flow.advance_dialogue()
	await process_frame
	var each: int = int(flow.exercise.answer)
	for group_index in flow.share_zones.size():
		for _item_index in each:
			flow.drop_into("ShareZone_%d" % group_index, flow.visual_source_items.get_child(0))
	flow._on_done() # persistent success
	flow._on_done() # Continue
	await process_frame
	expect(ending_emissions[0] == 0, "Old Mac alone does not trigger the ending after restart")
	expect(flow.state == flow.State.MAP, "partial completion returns to the live map")
	expect(not game.world.is_world_complete(), "partial farm is not considered complete")

	# Now complete every NPC and finish Old Mac last: exactly one ending.
	for n in game.world.NPCS:
		game.world.npc_phase[n.id] = 4
	game.world.npc_phase["old-mac"] = 3
	flow.start(old_mac)
	flow.advance_dialogue(); flow.advance_dialogue()
	await process_frame
	each = int(flow.exercise.answer)
	for group_index in flow.share_zones.size():
		for _item_index in each:
			flow.drop_into("ShareZone_%d" % group_index, flow.visual_source_items.get_child(0))
	flow._on_done()
	flow._on_done()
	await process_frame
	expect(ending_emissions[0] == 1, "whole-farm completion triggers the ending exactly once")
	expect(game.world.is_world_complete(), "all eight NPCs are complete")

	# --- it is the regular dialogue box, not a new screen ---
	expect(flow.state == flow.State.DIALOGUE, "ending uses the DIALOGUE state")
	expect(flow.dialogue_screen.visible, "ending shows in the shared dialogue screen")
	expect(flow.dialogue_screen.has_node("DialogueBox"),
		"ending reuses the same DialogueBox container as every NPC")
	expect(flow.exercise_screen != null and not flow.exercise_screen.visible,
		"no exercise panel behind the ending")
	expect(flow.feedback_screen != null and not flow.feedback_screen.visible,
		"the ending is not the feedback/game-over panel")
	expect(flow.dialogue_name.text == title, "title shown in the dialogue name slot")
	expect(flow.dialogue_text.text == body, "body shown in the dialogue text slot")

	# --- celebratory flourish reuses the correct-answer art ---
	expect(flow.dialogue_portrait.texture != null and flow.dialogue_portrait.visible,
		"a celebratory flourish (happy-face art) stands in for the emoji")

	# --- tap to dismiss, exactly like every other dialogue ---
	flow.advance_dialogue()   # first tap completes the typewriter
	flow.advance_dialogue()   # second tap dismisses
	await process_frame
	expect(flow.state == flow.State.MAP, "tapping dismisses the ending back to the map")
	expect(not flow.dialogue_screen.visible, "dialogue box hidden after dismissing")

	# --- the world stays live: player free, NPCs replayable ---
	# The onboarding overlay is unrelated to the ending; skip it so this
	# assertion measures the ending's effect on input, not the title cards'.
	if game.onboarding and game.onboarding.active:
		game.onboarding._finish()
		await game.onboarding.finished   # _finish() fades out over 0.45s
		await process_frame
	expect(not game.is_input_locked(), "player can walk again after the ending")
	var mae: Dictionary = {}
	for n in game.world.NPCS:
		if n.id == "mae":
			mae = n
	flow.start(mae)
	await process_frame
	expect(flow.state == flow.State.DIALOGUE,
		"an NPC can still be talked to after the ending (world not locked)")

	# --- never replays: finishing another phase later must not re-open it ---
	# Mae's last phase is rolled back and replayed while the farm is otherwise
	# complete; the ending already happened, so it must stay closed.
	game.world.npc_phase["mae"] = 3
	flow.start(mae)
	flow.advance_dialogue(); flow.advance_dialogue()
	await process_frame
	if flow.state == flow.State.EXERCISE:
		var mae_each: int = int(flow.exercise.answer)
		if flow.share_zones.size() > 0:
			for group_index in flow.share_zones.size():
				for _i in mae_each:
					flow.drop_into("ShareZone_%d" % group_index, flow.visual_source_items.get_child(0))
			flow._on_done()
			flow._on_done()
			await process_frame
	expect(ending_emissions[0] == 1, "the ending never replays once it has been shown")

	game.queue_free()
	await process_frame
	print("ALL TESTS PASSED" if failures == 0 else "TEST FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
