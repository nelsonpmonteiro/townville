extends SceneTree
## Every correct exercise uses one persistent, in-place success screen.
## No NPC or mode may fall back to the timed FEEDBACK overlay.

var failures := 0
var checks := 0

func expect(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _complete_live_exercise(flow) -> void:
	var mode: String = flow.exercise.mode
	if mode == "basket_in":
		while flow.basket_count < int(flow.exercise.answer):
			flow.drop_into("BasketDropZone", flow.source_items.get_child(0))
	elif mode == "basket_out":
		while flow.basket_count > int(flow.exercise.answer):
			flow.drop_into("TrayDropZone", flow.basket_items.get_child(0))
	elif mode == "array":
		for i in flow.visual_cells.size():
			flow.drop_into("ArrayCell_%d" % i, flow.visual_source_items.get_child(0))
	elif mode == "share":
		var each: int = int(flow.exercise.answer)
		for group_index in flow.share_zones.size():
			for _item_index in each:
				flow.drop_into("ShareZone_%d" % group_index, flow.visual_source_items.get_child(0))

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	var flow = game.flow
	# Never inherit completion from a developer/user save while testing the
	# 32 exercises independently; a restart likewise starts from this state.
	game.world.npc_phase.clear()

	for npc in game.world.NPCS:
		for phase in 4:
			game.world.npc_phase[npc.id] = phase
			flow.start(npc)
			flow.advance_dialogue()
			flow.advance_dialogue()
			await process_frame
			var tag := "%s phase %d (%s)" % [npc.id, phase + 1, flow.exercise.mode]
			expect(flow.state == flow.State.EXERCISE, tag + " opens")
			_complete_live_exercise(flow)
			expect(not flow.equation_label.visible and not flow.success_title.visible,
				tag + " does not reveal success before Done")

			flow._on_done()
			await process_frame
			expect(flow.state == flow.State.EXERCISE, tag + " keeps success in the exercise screen")
			expect(not flow.feedback_screen.visible, tag + " never opens timed feedback")
			expect(flow.success_icon.visible and flow.success_icon.texture != null,
				tag + " shows happy-face art")
			expect(flow.success_title.visible and flow.success_title.text.contains("Congrats"),
				tag + " shows Congrats")
			expect(flow.success_message.visible and flow.success_message.text == flow.exercise.success,
				tag + " shows the NPC success line")
			expect(flow.equation_label.visible and not flow.equation_label.text.is_empty(),
				tag + " shows the math summary")
			expect(flow.done_btn.visible and flow.done_btn.text == "Continue",
				tag + " waits for Continue")
			expect(not flow.basket_row.visible and not flow.visual_row.visible and not flow.text_row.visible,
				tag + " replaces the live exercise instead of stacking over it")

			var phase_before: int = game.world.get_phase(npc.id)
			flow._on_done()
			await process_frame
			expect(flow.state == flow.State.MAP, tag + " Continue returns to map")
			expect(game.world.get_phase(npc.id) == phase_before + 1, tag + " advances once")
			game.world.npc_phase[npc.id] = 0

	game.queue_free()
	await process_frame
	print("ALL TESTS PASSED (%d checks)" % checks if failures == 0 else "TEST FAILURES: %d / %d" % [failures, checks])
	quit(0 if failures == 0 else 1)
