extends SceneTree
## A correct basket exercise is ONE screen, not two.
##
## Before: Done showed the equation, Continue opened a SEPARATE feedback panel
## with the happy face and the NPC's success line. That is two celebrations for
## one achievement, and the child has to dismiss twice.
##
## Now: Done replaces the exercise with a single success screen carrying the
## congratulation, the NPC's line AND the equation together; Continue closes it
## straight to the map.

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

	flow.start(mae)
	flow.advance_dialogue()
	flow.advance_dialogue()
	await process_frame
	expect(flow.state == flow.State.EXERCISE, "phase 1 exercise open")
	expect(flow.exercise.mode == "basket_in", "phase 1 is a basket exercise")

	# Fill the basket to the target with real drops.
	var target: int = int(flow.exercise.answer)
	var guard := 0
	while flow.basket_count < target and guard < 40:
		flow.drop_into("BasketDropZone", flow.source_items.get_child(0))
		guard += 1
	expect(flow.basket_count == target, "basket filled to the target")

	# --- Done: the celebration and the equation share ONE screen ---
	flow._on_done()
	await process_frame
	expect(flow.state == flow.State.EXERCISE,
		"success is shown in place, still on the exercise screen")
	expect(flow.feedback_screen != null and not flow.feedback_screen.visible,
		"no separate feedback panel is opened")
	expect(flow.success_title.visible and flow.success_title.text.contains("Congrats"),
		"congratulation is on the success screen")
	expect(flow.success_icon.visible and flow.success_icon.texture != null,
		"happy-face art is on the success screen")
	expect(flow.success_message.visible and flow.success_message.text == flow.exercise.success,
		"the NPC's success line is on the SAME screen as the equation")
	expect(flow.equation_label.visible and flow.equation_label.text.contains("="),
		"the equation is on that same screen")
	expect(not flow.prompt_label.visible, "the original instruction is replaced, not stacked")
	expect(not flow.basket_row.visible, "the live basket is replaced by the celebration")
	expect(flow.done_btn.text == "Continue", "the single button reads Continue")

	# --- Continue: straight back to the map, no second panel ---
	var phase_before: int = game.world.get_phase("mae")
	flow._on_done()
	await process_frame
	expect(flow.state == flow.State.MAP, "Continue goes straight back to the map")
	expect(not flow.feedback_screen.visible, "no second celebration panel on the way out")
	expect(game.world.get_phase("mae") == phase_before + 1, "the phase still advances")
	expect(flow.last_correct, "the exercise is still recorded as correct")

	# --- a wrong answer still uses the retry feedback panel ---
	flow.start(mae)
	flow.advance_dialogue()
	flow.advance_dialogue()
	await process_frame
	if flow.state == flow.State.EXERCISE and flow.exercise.mode == "basket_out":
		flow.drop_into("TrayDropZone", flow.basket_items.get_child(0))
		flow._on_done()
		await process_frame
		expect(flow.state == flow.State.FEEDBACK and not flow.last_correct,
			"a WRONG answer still shows the retry feedback panel")

	game.queue_free()
	await process_frame
	print("ALL TESTS PASSED" if failures == 0 else "TEST FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
