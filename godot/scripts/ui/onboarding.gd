extends CanvasLayer
## Onboarding - Title -> 2 How-to-Play cards -> fade -> map.
## Enter/Space/Right advances; Left/Backspace returns; taps use the visible controls.
## Runs as an overlay over the already-built world so the farm art is the title background.

const SAVE_PATH := "user://save_data.cfg"
const DirectionKeysScript := preload("res://scripts/ui/direction_keys.gd")
const CARDS := [
	["", "Use these keys to walk around Townville!"],
	["[ E ]", "Walk up to a friend and press E to talk!"],
]

## Bordered button style — matches InteractionFlow's buttons so every button
## in the game reads as clickable UI, not flat text.
static func _button_style(bg: Color, border: Color = Color("#c9a36b")) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(8)
	return sb

static func _apply_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _button_style(Color("#3a2a1a")))
	btn.add_theme_stylebox_override("hover", _button_style(Color("#4a3624"), Color("#ffd75a")))
	btn.add_theme_stylebox_override("pressed", _button_style(Color("#241a10"), Color("#ffd75a")))
	btn.add_theme_stylebox_override("focus", _button_style(Color("#3a2a1a"), Color("#ffd75a")))

signal finished

var step := -1          # -1 title, 0..2 cards, 3 done
var active := false
var _busy := false

var root: Control
var dim: ColorRect
var title_box: VBoxContainer
var card_box: VBoxContainer
var card_icon: Label
var direction_keys: Control
var card_text: Label
var back_button: Button
var next_button: Button
var tap_label: Label
var _pulse: Tween

static func has_seen_onboarding() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return false
	return bool(cfg.get_value("player", "onboarding_seen", false))

static func mark_onboarding_complete() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("player", "onboarding_seen", true)
	cfg.save(SAVE_PATH)

static func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _ready() -> void:
	layer = 30
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.gui_input.connect(_on_gui_input)
	add_child(root)

	dim = ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.05, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	# --- Title ---
	title_box = _center_box()
	var logo := Label.new()
	logo.text = "TOWNVILLE"
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.add_theme_font_size_override("font_size", 84)
	logo.add_theme_color_override("font_color", Color("#ffd75a"))
	logo.add_theme_color_override("font_shadow_color", Color("#3a2a1a"))
	logo.add_theme_constant_override("shadow_offset_x", 4)
	logo.add_theme_constant_override("shadow_offset_y", 4)
	title_box.add_child(logo)
	var sub := Label.new()
	sub.text = "A math adventure on the farm"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color("#fff2a8"))
	title_box.add_child(sub)
	var spacer := Control.new(); spacer.custom_minimum_size = Vector2(0, 40)
	title_box.add_child(spacer)
	tap_label = Label.new()
	tap_label.text = "Tap, Enter, or Space to start"
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.add_theme_font_size_override("font_size", 24)
	tap_label.add_theme_color_override("font_color", Color.WHITE)
	title_box.add_child(tap_label)

	# --- Cards ---
	card_box = _center_box()
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1e1a16f2"); sb.border_color = Color("#c9a36b")
	sb.set_border_width_all(3); sb.set_corner_radius_all(12); sb.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", sb)
	# SHRINK_CENTER (not the container default FILL) makes the card a compact
	# box centered on screen instead of stretching edge-to-edge — it must
	# look like a dialog floating over the map, not a full-width banner.
	panel.custom_minimum_size = Vector2(480, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_box.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	card_icon = Label.new()
	card_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_icon.add_theme_font_size_override("font_size", 40)
	card_icon.add_theme_color_override("font_color", Color("#ffd75a"))
	v.add_child(card_icon)
	var direction_holder := CenterContainer.new()
	v.add_child(direction_holder)
	direction_keys = Control.new()
	direction_keys.set_script(DirectionKeysScript)
	direction_holder.add_child(direction_keys)
	card_text = Label.new()
	card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size = Vector2(430, 0)
	card_text.add_theme_font_size_override("font_size", 20)
	v.add_child(card_text)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 14)
	v.add_child(controls)
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(104, 38)
	_apply_button_style(back_button)
	back_button.pressed.connect(back)
	controls.add_child(back_button)
	next_button = Button.new()
	next_button.text = "Next"
	next_button.custom_minimum_size = Vector2(104, 38)
	_apply_button_style(next_button)
	next_button.pressed.connect(advance)
	controls.add_child(next_button)

	visible = false

func _center_box() -> VBoxContainer:
	var b := VBoxContainer.new()
	b.alignment = BoxContainer.ALIGNMENT_CENTER
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.visible = false
	root.add_child(b)
	return b

func start() -> void:
	active = true
	visible = true
	step = -1
	_show()

func _show() -> void:
	title_box.visible = step == -1
	card_box.visible = step >= 0 and step < CARDS.size()
	if step == -1:
		if _pulse: _pulse.kill()
		_pulse = create_tween().set_loops()
		_pulse.tween_property(tap_label, "modulate:a", 0.25, 0.7)
		_pulse.tween_property(tap_label, "modulate:a", 1.0, 0.7)
	elif step < CARDS.size():
		card_icon.text = CARDS[step][0]
		card_icon.visible = step != 0
		direction_keys.visible = step == 0
		card_text.text = CARDS[step][1]
		back_button.visible = true
		next_button.text = "Play" if step == CARDS.size() - 1 else "Next"

func advance() -> void:
	if not active or _busy:
		return
	step += 1
	if step >= CARDS.size():
		_finish()
	else:
		_show()

func back() -> void:
	if not active or _busy or step <= -1:
		return
	step -= 1
	_show()

func _finish() -> void:
	_busy = true
	if _pulse: _pulse.kill()
	mark_onboarding_complete()
	var t := create_tween()
	t.tween_property(root, "modulate:a", 0.0, 0.45)
	await t.finished
	active = false
	visible = false
	root.modulate.a = 1.0
	_busy = false
	finished.emit()

func _on_gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
		advance()
		get_viewport().set_input_as_handled()

func _input(ev: InputEvent) -> void:
	if not active or not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	if ev.keycode in [KEY_LEFT, KEY_BACKSPACE]:
		back()
		get_viewport().set_input_as_handled()
	elif ev.keycode in [KEY_RIGHT, KEY_ENTER, KEY_SPACE]:
		advance()
		get_viewport().set_input_as_handled()

func debug_state() -> Dictionary:
	return {"active": active, "step": step, "card_text": card_text.text if card_box.visible else "", "title_visible": title_box.visible}
