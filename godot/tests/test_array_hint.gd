extends SceneTree
## The multiplication pool must NOT label its own size by default.
##
## "Field to place: 20" sat above the pool while the exercise asked the child
## to work out that 4 rows x 5 pumpkins = 20 — the label simply handed over the
## answer. It is now a hint: hidden until the child asks for one.

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
	var mae: Dictionary = {}
	for n in game.world.NPCS:
		if n.id == "mae":
			mae = n

	# Jump to phase 3 (the multiplication array).
	game.world.npc_phase["mae"] = 2
	flow.start(mae)
	flow.advance_dialogue()
	flow.advance_dialogue()
	await process_frame
	expect(flow.exercise.mode == "array", "phase 3 is the multiplication array")

	var total: int = flow.visual_source_items.get_child_count()
	expect(total > 0, "pool is filled with the items to place")

	# --- the giveaway label is hidden by default ---
	expect(not flow.visual_source_title.visible,
		"the pool count is NOT shown by default (it would be the answer)")
	expect(flow.visual_source_panel.visible, "the pool itself is still visible")
	expect(flow.hint_btn.visible, "a Hint button is offered for the array exercise")

	# Placing items must not make it reappear on its own.
	flow.drop_into("ArrayCell_0", flow.visual_source_items.get_child(0))
	await process_frame
	expect(not flow.visual_source_title.visible,
		"placing an item does not reveal the count either")

	# --- asking for a hint reveals it ---
	flow._on_hint_requested()
	await process_frame
	expect(flow.visual_source_title.visible, "the Hint button reveals the pool count")
	expect(flow.visual_source_title.text.contains(str(flow.visual_source_items.get_child_count())),
		"the revealed count matches what is actually left in the pool")
	expect(flow.hint_label.visible, "the worded hint is shown too")
	expect(flow.hints_used_this_exercise == 1, "hint usage is tracked for the teacher panel")

	# --- a fresh exercise hides it again ---
	flow.start(mae)
	flow.advance_dialogue()
	flow.advance_dialogue()
	await process_frame
	if flow.exercise.mode == "array":
		expect(not flow.visual_source_title.visible, "reopening the exercise hides the count again")
		expect(flow.hints_used_this_exercise == 0, "hint counter resets per exercise")

	game.queue_free()
	await process_frame
	print("ALL TESTS PASSED" if failures == 0 else "TEST FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
