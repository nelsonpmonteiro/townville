extends CanvasLayer
## VolumeControl — speaker icon in the HUD that opens a small panel with two
## independent sliders: background Music and sound Effects (SFX).
##
## Each slider drives its own audio bus (Music / SFX, see default_bus_layout.tres),
## so lowering the music never touches the placement "pop" feedback and vice versa.
## Levels persist in user://save_data.cfg (same file as the onboarding flag).
##
## Linear slider value (0..1) maps to decibels with linear_to_db so the knob
## feels proportional to loudness; 0 mutes the bus outright instead of applying
## -inf dB, which some web audio backends handle badly.

const SAVE_PATH := "user://save_data.cfg"
const ICON_PATH := "res://assets/ui/volume-icon.png"
const DEFAULT_MUSIC := 0.5
const DEFAULT_SFX := 0.8

signal levels_changed(music: float, sfx: float)

var button: TextureButton
var panel: PanelContainer
var music_slider: HSlider
var sfx_slider: HSlider
var music_value_label: Label
var sfx_value_label: Label
var panel_open := false

var music_level := DEFAULT_MUSIC
var sfx_level := DEFAULT_SFX

static func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1e1a16f2")
	sb.border_color = Color("#c9a36b")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	return sb

func _ready() -> void:
	layer = 12
	_load_levels()
	_build_button()
	_build_panel()
	_apply_levels()

func _build_button() -> void:
	button = TextureButton.new()
	button.name = "VolumeButton"
	if ResourceLoader.exists(ICON_PATH):
		button.texture_normal = load(ICON_PATH) as Texture2D
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(44, 44)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Bottom-right, directly left of the "?" info button (which sits at -64..-16).
	button.anchor_left = 1.0; button.anchor_right = 1.0
	button.anchor_top = 1.0; button.anchor_bottom = 1.0
	button.offset_left = -120; button.offset_right = -76
	button.offset_top = -62; button.offset_bottom = -18
	button.tooltip_text = "Volume"
	button.pressed.connect(toggle_panel)
	add_child(button)

func _build_panel() -> void:
	panel = PanelContainer.new()
	panel.name = "VolumePanel"
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.custom_minimum_size = Vector2(300, 0)
	panel.anchor_left = 1.0; panel.anchor_right = 1.0
	panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
	panel.offset_left = -332; panel.offset_right = -16
	panel.offset_top = -216; panel.offset_bottom = -72
	panel.visible = false
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	var title := Label.new()
	title.text = "Sound"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#ffd75a"))
	v.add_child(title)

	var music_pair := _build_row(v, "Music", music_level)
	music_slider = music_pair[0]
	music_value_label = music_pair[1]
	music_slider.value_changed.connect(_on_music_changed)

	var sfx_pair := _build_row(v, "Effects", sfx_level)
	sfx_slider = sfx_pair[0]
	sfx_value_label = sfx_pair[1]
	sfx_slider.value_changed.connect(_on_sfx_changed)

## One labelled slider row: "Music   [=====----]  50"
func _build_row(parent: Control, label_text: String, value: float) -> Array:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = label_text
	name_label.custom_minimum_size = Vector2(74, 0)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("#f5e9cf"))
	row.add_child(name_label)

	var slider := HSlider.new()
	slider.name = label_text + "Slider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(160, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d" % roundi(value * 100.0)
	value_label.custom_minimum_size = Vector2(38, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color("#ffd75a"))
	row.add_child(value_label)

	return [slider, value_label]

func toggle_panel() -> void:
	set_panel_open(not panel_open)

func set_panel_open(open: bool) -> void:
	panel_open = open
	panel.visible = open

func _on_music_changed(value: float) -> void:
	music_level = value
	music_value_label.text = "%d" % roundi(value * 100.0)
	_apply_levels()
	_save_levels()

func _on_sfx_changed(value: float) -> void:
	sfx_level = value
	sfx_value_label.text = "%d" % roundi(value * 100.0)
	_apply_levels()
	_save_levels()

## Public setter so tests / the JS bridge can drive the sliders directly.
func set_levels(music: float, sfx: float) -> void:
	music_level = clampf(music, 0.0, 1.0)
	sfx_level = clampf(sfx, 0.0, 1.0)
	if music_slider:
		music_slider.set_value_no_signal(music_level)
		music_value_label.text = "%d" % roundi(music_level * 100.0)
	if sfx_slider:
		sfx_slider.set_value_no_signal(sfx_level)
		sfx_value_label.text = "%d" % roundi(sfx_level * 100.0)
	_apply_levels()
	_save_levels()

func _apply_levels() -> void:
	_apply_bus("Music", music_level)
	_apply_bus("SFX", sfx_level)
	levels_changed.emit(music_level, sfx_level)

func _apply_bus(bus_name: String, level: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	# A 0 slider mutes the bus instead of sending -inf dB down the graph.
	AudioServer.set_bus_mute(idx, level <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(level, 0.0001)))

func _load_levels() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	music_level = clampf(float(cfg.get_value("audio", "music", DEFAULT_MUSIC)), 0.0, 1.0)
	sfx_level = clampf(float(cfg.get_value("audio", "sfx", DEFAULT_SFX)), 0.0, 1.0)

func _save_levels() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("audio", "music", music_level)
	cfg.set_value("audio", "sfx", sfx_level)
	cfg.save(SAVE_PATH)
