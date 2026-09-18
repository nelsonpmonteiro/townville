extends SceneTree
## Audio: background music on its own bus, and a volume popover whose two
## sliders move Music and SFX independently.
##
## The point of the separate buses is that a child who mutes the music still
## hears the placement "pop" feedback (and vice versa), so every assertion here
## checks that one slider does NOT move the other bus.

var failures := 0

func expect(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	# Never let the test clobber the player's real saved levels.
	var save_path := "user://save_data.cfg"
	var original := ""
	if FileAccess.file_exists(save_path):
		original = FileAccess.get_file_as_string(save_path)

	expect(AudioServer.get_bus_index("Music") > 0, "Music bus exists in the bus layout")
	expect(AudioServer.get_bus_index("SFX") > 0, "SFX bus exists in the bus layout")

	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	# ---- background music ----
	expect(game.music_player != null, "game builds a background music player")
	expect(game.music_player.stream != null, "music track loaded from assets/audio")
	expect(game.music_player.bus == "Music", "music plays on the Music bus")
	if game.music_player.stream is AudioStreamMP3:
		expect(game.music_player.stream.loop, "background music loops")

	# ---- placement SFX stays on its own bus ----
	expect(game.flow.pop_player.bus == "SFX", "placement pop plays on the SFX bus")

	# ---- volume control UI ----
	var vc = game.volume_control
	expect(vc != null, "volume control added to the scene")
	expect(vc.button != null and vc.button.texture_normal != null, "speaker icon button has its PixelLab texture")
	expect(not vc.panel_open and not vc.panel.visible, "volume panel starts closed")
	expect(vc.music_slider != null and vc.sfx_slider != null, "panel holds two separate sliders")

	vc.toggle_panel()
	expect(vc.panel_open and vc.panel.visible, "clicking the speaker opens the panel")
	vc.toggle_panel()
	expect(not vc.panel_open and not vc.panel.visible, "clicking again closes the panel")
	vc.toggle_panel()

	# ---- sliders drive their own bus only ----
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")

	vc.set_levels(0.25, 0.9)
	await process_frame
	var sfx_db_before := AudioServer.get_bus_volume_db(sfx_idx)
	expect(is_equal_approx(AudioServer.get_bus_volume_db(music_idx), linear_to_db(0.25)),
		"music slider sets the Music bus volume")
	expect(is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), linear_to_db(0.9)),
		"sfx slider sets the SFX bus volume")

	# Moving music alone must leave SFX untouched — the whole reason for two buses.
	vc.set_levels(0.6, 0.9)
	await process_frame
	expect(is_equal_approx(AudioServer.get_bus_volume_db(music_idx), linear_to_db(0.6)),
		"music slider moves again")
	expect(is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), sfx_db_before),
		"changing music leaves the SFX bus untouched")

	# ...and the mirror case.
	var music_db_before := AudioServer.get_bus_volume_db(music_idx)
	vc.set_levels(0.6, 0.2)
	await process_frame
	expect(is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), linear_to_db(0.2)),
		"sfx slider moves again")
	expect(is_equal_approx(AudioServer.get_bus_volume_db(music_idx), music_db_before),
		"changing sfx leaves the Music bus untouched")

	# Zero mutes outright instead of shipping -inf dB to the web audio backend.
	vc.set_levels(0.0, 0.5)
	await process_frame
	expect(AudioServer.is_bus_mute(music_idx), "music at 0 mutes the Music bus")
	expect(not AudioServer.is_bus_mute(sfx_idx), "muting music does not mute SFX")
	vc.set_levels(0.5, 0.0)
	await process_frame
	expect(AudioServer.is_bus_mute(sfx_idx), "sfx at 0 mutes the SFX bus")
	expect(not AudioServer.is_bus_mute(music_idx), "muting SFX does not mute music")

	# ---- levels persist across a restart ----
	vc.set_levels(0.35, 0.65)
	await process_frame
	game.queue_free()
	await process_frame
	var game2 = packed.instantiate()
	root.add_child(game2)
	await process_frame
	expect(is_equal_approx(game2.volume_control.music_level, 0.35), "music level restored after restart")
	expect(is_equal_approx(game2.volume_control.sfx_level, 0.65), "sfx level restored after restart")
	game2.queue_free()
	await process_frame

	# Restore whatever the player had before the test ran.
	if original.is_empty():
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	else:
		var f := FileAccess.open(save_path, FileAccess.WRITE)
		f.store_string(original)
		f.close()

	print("ALL TESTS PASSED" if failures == 0 else "TEST FAILURES: %d" % failures)
	quit(0 if failures == 0 else 1)
