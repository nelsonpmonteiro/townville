extends CanvasLayer
## RestartControl — circular-arrow icon in the TOP-LEFT of the HUD that asks for
## confirmation before wiping the session.
##
## Clicking the icon opens a modal (dimmed backdrop + Cancel / Restart buttons).
## Cancel closes it and changes nothing. Restart clears the saved progress —
## including the onboarding flag — and reloads the scene, so the player lands
## back on the onboarding title exactly like a first launch.
##
## The modal is genuinely modal: its backdrop swallows clicks so the map and the
## exercise UI underneath cannot be operated while the question is on screen,
## and Esc cancels.

const SAVE_PATH := "user://save_data.cfg"
const ICON_PATH := "res://assets/ui/restart-icon.png"

signal restart_confirmed

var button: TextureButton
var modal: Control
var confirm_button: Button
var cancel_button: Button
var modal_open := false

static func _panel_style(bg: Color, border: Color = Color("#c9a36b")) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	return sb

static func _button_style(bg: Color, border: Color = Color("#c9a36b")) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)
	return sb

static func _apply_button_style(btn: Button, bg: Color, hover: Color) -> void:
	btn.add_theme_stylebox_override("normal", _button_style(bg))
	btn.add_theme_stylebox_override("hover", _button_style(hover, Color("#ffd75a")))
	btn.add_theme_stylebox_override("pressed", _button_style(bg, Color("#ffd75a")))
	btn.add_theme_stylebox_override("focus", _button_style(bg, Color("#ffd75a")))

func _ready() -> void:
	# Above the HUD and the interaction flow so the confirmation is never
	# painted over by a dialogue or an exercise panel.
	layer = 25
	_build_button()
	_build_modal()

func _build_button() -> void:
	button = TextureButton.new()
	button.name = "RestartButton"
	if ResourceLoader.exists(ICON_PATH):
		button.texture_normal = load(ICON_PATH) as Texture2D
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(44, 44)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Top-left corner, clear of the FPS label at (18, 16).
	button.anchor_left = 0.0; button.anchor_right = 0.0
	button.anchor_top = 0.0; button.anchor_bottom = 0.0
	button.offset_left = 16; button.offset_right = 60
	button.offset_top = 14; button.offset_bottom = 58
	button.tooltip_text = "Restart the game"
	button.pressed.connect(open_modal)
	add_child(button)

func _build_modal() -> void:
	modal = Control.new()
	modal.name = "RestartModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	# STOP on the root means the backdrop eats every click: nothing behind the
	# modal can be dragged or pressed while the question is open.
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.visible = false
	add_child(modal)

	var dim := ColorRect.new()
	dim.name = "RestartModalDim"
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "RestartModalPanel"
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#1e1a16f7")))
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -240; panel.offset_right = 240
	panel.offset_top = -110; panel.offset_bottom = 110
	modal.add_child(panel)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var title := Label.new()
	title.text = "Restart the game?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#ffd75a"))
	v.add_child(title)

	var body := Label.new()
	body.name = "RestartModalBody"
	body.text = "This clears your progress and takes you back to the beginning."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(420, 0)
	body.add_theme_font_size_override("font_size", 17)
	body.add_theme_color_override("font_color", Color("#f5e9cf"))
	v.add_child(body)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	v.add_child(row)

	cancel_button = Button.new()
	cancel_button.name = "RestartCancelButton"
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(150, 44)
	_apply_button_style(cancel_button, Color("#3a2a1a"), Color("#4a3624"))
	cancel_button.pressed.connect(close_modal)
	row.add_child(cancel_button)

	confirm_button = Button.new()
	confirm_button.name = "RestartConfirmButton"
	confirm_button.text = "Restart"
	confirm_button.custom_minimum_size = Vector2(150, 44)
	_apply_button_style(confirm_button, Color("#6d2b22"), Color("#8a3a2e"))
	confirm_button.pressed.connect(confirm_restart)
	row.add_child(confirm_button)

func open_modal() -> void:
	modal_open = true
	modal.visible = true
	cancel_button.grab_focus()

func close_modal() -> void:
	modal_open = false
	modal.visible = false

## Wipe the session and boot the scene fresh. Removing the progress keys (not
## the whole file) is what sends the player back through onboarding, since
## Onboarding.has_seen_onboarding() reads that same file — while the audio
## section survives, because a restart is not a request to reset the volume.
func confirm_restart() -> void:
	close_modal()
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	for section in cfg.get_sections():
		if section != "audio":
			cfg.erase_section(section)
	cfg.save(SAVE_PATH)
	restart_confirmed.emit()
	get_tree().reload_current_scene.call_deferred()

## Esc cancels, matching the dialogue screens. Handled at _input level because
## the modal's backdrop already blocks the gameplay input path.
func _input(event: InputEvent) -> void:
	if not modal_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close_modal()
		get_viewport().set_input_as_handled()
