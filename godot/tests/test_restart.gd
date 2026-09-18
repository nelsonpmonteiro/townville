extends SceneTree
## Restart button: a top-left icon that asks before it wipes the session.
##
## The rules being locked in here:
##   1. one click NEVER restarts — it only opens the confirmation modal;
##   2. Cancel (and Esc) leave progress completely untouched;
##   3. Confirm clears the progress so the next boot shows onboarding again;
##   4. the saved volume levels survive a restart (a restart is not a request
##      to reset the sound settings).

const SAVE_PATH := "user://save_data.cfg"

var failures := 0

func expect(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	var original := ""
	if FileAccess.file_exists(SAVE_PATH):
		original = FileAccess.get_file_as_string(SAVE_PATH)

	# Simulate a player mid-run: onboarding already seen, volume customised.
	var cfg := ConfigFile.new()
	cfg.set_value("player", "onboarding_seen", true)
	cfg.set_value("audio", "music", 0.3)
	cfg.set_value("audio", "sfx", 0.7)
	cfg.save(SAVE_PATH)

	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var rc = game.restart_control
	expect(rc != null, "restart control added to the scene")
	expect(rc.button != null and rc.button.texture_normal != null,
		"restart icon button has its PixelLab texture")

	# --- positioned in the TOP-LEFT corner ---
	var btn_rect: Rect2 = rc.button.get_global_rect()
	var viewport_size: Vector2 = Vector2(get_root().get_visible_rect().size)
	expect(btn_rect.position.x < viewport_size.x * 0.25,
		"restart button sits on the left side (x=%.0f)" % btn_rect.position.x)
	expect(btn_rect.position.y < viewport_size.y * 0.25,
		"restart button sits at the top (y=%.0f)" % btn_rect.position.y)
	# It must not collide with the bottom-right volume/info cluster.
	expect(not btn_rect.intersects(game.volume_control.button.get_global_rect()),
		"restart button does not overlap the volume button")

	# --- click 1: opens the modal, changes nothing ---
	expect(not rc.modal_open and not rc.modal.visible, "modal starts closed")
	rc.open_modal()
	await process_frame
	expect(rc.modal_open and rc.modal.visible, "clicking restart opens the confirmation modal")
	expect(rc.confirm_button != null and rc.cancel_button != null,
		"modal offers both confirm and cancel")
	expect(rc.modal.mouse_filter == Control.MOUSE_FILTER_STOP,
		"modal backdrop blocks clicks on the game underneath")
	expect(ConfigFile.new().load(SAVE_PATH) == OK and _seen_onboarding(),
		"opening the modal did NOT reset anything yet")

	# --- Cancel: closes, still nothing reset ---
	rc.close_modal()
	await process_frame
	expect(not rc.modal_open and not rc.modal.visible, "Cancel closes the modal")
	expect(_seen_onboarding(), "Cancel leaves progress untouched")

	# --- Esc also cancels ---
	rc.open_modal()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	rc._input(esc)
	await process_frame
	expect(not rc.modal_open, "Escape cancels the restart modal")
	expect(_seen_onboarding(), "Escape leaves progress untouched")

	# --- Confirm: clears progress, keeps audio ---
	rc.open_modal()
	var fired := [false]
	rc.restart_confirmed.connect(func(): fired[0] = true)
	rc.confirm_restart()
	await process_frame
	expect(fired[0], "confirming emits restart_confirmed")
	expect(not rc.modal_open, "confirming closes the modal")
	expect(not _seen_onboarding(), "confirming clears the onboarding flag -> next boot shows onboarding")

	var after := ConfigFile.new()
	after.load(SAVE_PATH)
	expect(is_equal_approx(float(after.get_value("audio", "music", -1.0)), 0.3),
		"restart keeps the saved music level")
	expect(is_equal_approx(float(after.get_value("audio", "sfx", -1.0)), 0.7),
		"restart keeps the saved sfx level")

	# --- a fresh boot after the restart really starts onboarding ---
	await process_frame
	var game2 = packed.instantiate()
	root.add_child(game2)
	await process_frame
	expect(game2.onboarding != null and game2.onboarding.active,
		"the game booted after a restart shows the onboarding again")
	game2.queue_free()
	await process_frame

	if original.is_empty():
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	else:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		f.store_string(original)
		f.close()

	print("ALL TESTS PASSED" if failures == 0 else "TEST FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)

func _seen_onboarding() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return bool(cfg.get_value("player", "onboarding_seen", false))
