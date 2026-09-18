extends CanvasLayer
## Onboarding — Title → 3 How-to-Play cards → fade → map.
## Shown only on first launch (flag in user://save_data.cfg). Any key / tap advances.
## Runs as an overlay over the already-built world so the farm art is the title background.

const SAVE_PATH := "user://save_data.cfg"
const CARDS := [
	["UP  LEFT  DOWN  RIGHT", "Use the arrow keys to walk around Townville!"],
	["[ E ]", "Walk up to a friend and press E to talk!"],
	["LOCKED  ->  OPEN", "Help everyone solve their problems to unlock the whole farm!"],
]

signal finished

var step := -1          # -1 title, 0..2 cards, 3 done
var active := false
var _busy := false

var root: Control
var dim: ColorRect
var title_box: VBoxContainer
var card_box: VBoxContainer
var card_icon: Label
var card_text: Label
var card_dots: Label
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
	tap_label.text = "Tap or press any key to start"
	tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tap_label.add_theme_font_size_override("font_size", 24)
	tap_label.add_theme_color_override("font_color", Color.WHITE)
	title_box.add_child(tap_label)

	# --- Cards ---
	card_box = _center_box()
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1e1a16f2"); sb.border_color = Color("#c9a36b")
	sb.set_border_width_all(3); sb.set_corner_radius_all(12); sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(620, 0)
	card_box.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	card_icon = Label.new()
	card_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_icon.add_theme_font_size_override("font_size", 56)
	card_icon.add_theme_color_override("font_color", Color("#ffd75a"))
	v.add_child(card_icon)
	card_text = Label.new()
	card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_text.custom_minimum_size = Vector2(560, 0)
	card_text.add_theme_font_size_override("font_size", 26)
	v.add_child(card_text)
	card_dots = Label.new()
	card_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_dots.add_theme_font_size_override("font_size", 18)
	card_dots.add_theme_color_override("font_color", Color("#a0c0ff"))
	v.add_child(card_dots)

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
		card_text.text = CARDS[step][1]
		var dots := ""
		for i in CARDS.size():
			dots += ("*" if i == step else "-") + "  "
		card_dots.text = dots + "    tap to continue"

func advance() -> void:
	if not active or _busy:
		return
	step += 1
	if step >= CARDS.size():
		_finish()
	else:
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
	_maybe_advance(ev)

# Any key OR any tap/click anywhere advances. _input (not _unhandled_input) so
# the click is caught regardless of which Control is under the cursor.
func _input(ev: InputEvent) -> void:
	if not active:
		return
	_maybe_advance(ev)

func _maybe_advance(ev: InputEvent) -> void:
	if not active:
		return
	var hit := false
	if ev is InputEventKey and ev.pressed and not ev.echo:
		hit = true
	elif ev is InputEventMouseButton and ev.pressed:
		hit = true
	elif ev is InputEventScreenTouch and ev.pressed:
		hit = true
	if hit:
		advance()
		get_viewport().set_input_as_handled()

func debug_state() -> Dictionary:
	return {"active": active, "step": step, "card_text": card_text.text if card_box.visible else "", "title_visible": title_box.visible}
