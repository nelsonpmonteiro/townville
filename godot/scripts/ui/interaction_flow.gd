extends CanvasLayer
## InteractionFlow — the complete NPC loop for World 1.
##
##   MAP → DIALOGUE → EXERCISE → FEEDBACK → MAP
##
## Exactly ONE screen is visible at a time (set_state hides all, then shows
## one). Player movement is gated in player.gd through Game.is_input_locked().
##
## Exercise modes (from TOWNVILLE-w1-exercise-script.md):
##   basket_in   phase 1  drag N items INTO the basket           (addition)
##   basket_out  phase 2  drag N items OUT of the basket to tray (subtraction)
##   array       phase 3  fill a rows x columns visual matrix     (multiplication)
##   share       phase 4  deal every item into equal groups       (division)
##
## Hints: tier 1 after the 1st wrong answer (text line), tier 2 after the 2nd
## (ghost outline / ghost numeral / icon grid). Wrong answers return to the
## SAME exercise, never to the map.

enum State { MAP, DIALOGUE, EXERCISE, FEEDBACK }

const ITEM_ICONS := {
	"egg": "res://assets/ui/items/egg.png",
	"carrot": "res://assets/ui/items/carrot.png",
	"hay bale": "res://assets/ui/items/hay-bale.png",
	"chick": "res://assets/ui/items/chick.png",
	"bandage": "res://assets/ui/items/bandage.png",
	"tomato": "res://assets/ui/items/tomato.png",
	"nail": "res://assets/ui/items/nail.png",
	"key": "res://assets/ui/items/key.png",
}
const FEEDBACK_SECONDS := 1.8
const TYPE_SPEED := 0.035
const POOL_EXTRA := 3  # draggable pool always has this many more than strictly needed
const POOL_LABELS := {
	"egg": "Nest", "carrot": "Feed Bin", "hay bale": "Field", "chick": "Yard",
	"bandage": "Supply Closet", "tomato": "Vine", "nail": "Shed", "key": "Drawer",
}

var state: State = State.MAP
var world
var npc: Dictionary = {}
var exercise: Dictionary = {}
var wrong_attempts := 0
var last_correct := false
var basket_count := 0
var is_typing := false
var _tween: Tween

# ----- screens -----
var dialogue_screen: Control
var dialogue_name: Label
var dialogue_text: RichTextLabel
var dialogue_portrait: TextureRect
var advance_hint: Label

var exercise_screen: Control
var prompt_label: Label
var hint_label: Label
var basket_row: HBoxContainer      # basket_in/out layout root
var source_title: Label
var source_items: HBoxContainer
var basket_zone: PanelContainer
var basket_items: HBoxContainer
var basket_counter: Label
var tray_zone: PanelContainer
var tray_items: HBoxContainer
var tray_label: Label
var equation_label: Label          # number sentence for subtraction/multiplication/division
var addition_summary: HBoxContainer # visual existing-items + added-items feedback
var addition_existing_items: HFlowContainer
var addition_added_items: HFlowContainer
var done_btn: Button               # basket modes: child submits when finished
var text_row: VBoxContainer        # text layout root
var answer_input: LineEdit
var submit_btn: Button
var icon_grid: GridContainer

# Physical multiplication/division layout, styled inside the existing panel.
var visual_row: VBoxContainer
var visual_source_title: Label
var visual_source_panel: PanelContainer
var visual_source_items: HFlowContainer
var visual_zones: HBoxContainer
var visual_cells: Array = []
var share_zones: Array = []
var share_titles: Array = []
var pop_player: AudioStreamPlayer
var pop_events := 0
var bump_events := 0

var feedback_screen: Control
var result_label: Label
var result_icon: Label
var feedback_addition_summary: HBoxContainer
var feedback_existing_items: HFlowContainer
var feedback_added_items: HFlowContainer

signal phase_completed(npc_id: String, phase: int)
signal world_completed

static func _panel_style(bg: Color, border: Color = Color("#3a2a1a")) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(16)
	return sb

func _ready() -> void:
	layer = 20
	_build_dialogue()
	_build_exercise()
	_build_feedback()
	_build_pop_audio()
	set_state(State.MAP)

# =====================================================================
# State machine
# =====================================================================
func set_state(s: State) -> void:
	dialogue_screen.visible = false
	exercise_screen.visible = false
	feedback_screen.visible = false
	state = s
	match s:
		State.DIALOGUE: dialogue_screen.visible = true
		State.EXERCISE: exercise_screen.visible = true
		State.FEEDBACK: feedback_screen.visible = true
		State.MAP: pass

func is_locked() -> bool:
	return state != State.MAP

func state_name() -> String:
	return ["map", "dialogue", "exercise", "feedback"][state]

# =====================================================================
# Public entry: player pressed E next to an NPC
# =====================================================================
func start(npc_data: Dictionary) -> void:
	npc = npc_data
	exercise = world.get_current_exercise(npc)
	wrong_attempts = 0
	dialogue_name.text = npc.display_name
	var tex := load(npc.sprite_path) as Texture2D
	dialogue_portrait.texture = tex
	set_state(State.DIALOGUE)
	if exercise.is_empty():
		_show_line("Thanks for all your help! Everything here is counted and sorted.")
	elif world.get_phase(npc.id) == 0:
		_show_line(npc.get("intro", "") + "\n\n" + exercise.setup)
	else:
		_show_line(exercise.setup)

# =====================================================================
# Dialogue
# =====================================================================
func _build_dialogue() -> void:
	dialogue_screen = Control.new()
	dialogue_screen.name = "DialogueScreen"
	dialogue_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dialogue_screen)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_screen.add_child(dim)

	var box := PanelContainer.new()
	box.name = "DialogueBox"
	box.custom_minimum_size = Vector2(640, 0)
	box.anchor_left = 0.5; box.anchor_right = 0.5
	box.anchor_top = 1.0; box.anchor_bottom = 1.0
	box.offset_left = -320; box.offset_right = 320
	box.offset_top = -190; box.offset_bottom = -32
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.add_theme_stylebox_override("panel", _panel_style(Color("#1e1a16f2"), Color("#c9a36b")))
	box.gui_input.connect(_on_dialogue_input)
	dialogue_screen.add_child(box)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	box.add_child(h)

	dialogue_portrait = TextureRect.new()
	dialogue_portrait.custom_minimum_size = Vector2(100, 100)
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	h.add_child(dialogue_portrait)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)

	dialogue_name = Label.new()
	dialogue_name.add_theme_font_size_override("font_size", 20)
	dialogue_name.add_theme_color_override("font_color", Color("#fff2a8"))
	v.add_child(dialogue_name)

	dialogue_text = RichTextLabel.new()
	dialogue_text.bbcode_enabled = false
	dialogue_text.fit_content = true
	dialogue_text.scroll_active = false
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_font_size_override("normal_font_size", 22)
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(dialogue_text)

	advance_hint = Label.new()
	advance_hint.text = "E / click to continue"
	advance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	advance_hint.add_theme_color_override("font_color", Color("#a0c0ff"))
	v.add_child(advance_hint)

func _show_line(text: String) -> void:
	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0
	is_typing = true
	advance_hint.visible = false
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.tween_property(dialogue_text, "visible_ratio", 1.0, max(0.2, text.length() * TYPE_SPEED))
	_tween.finished.connect(func():
		is_typing = false
		advance_hint.visible = true)

func _on_dialogue_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		advance_dialogue()

func cancel_dialogue() -> void:
	if state != State.DIALOGUE:
		return
	if _tween:
		_tween.kill()
	is_typing = false
	set_state(State.MAP)

func advance_dialogue() -> void:
	if state != State.DIALOGUE:
		return
	if is_typing:
		if _tween: _tween.kill()
		dialogue_text.visible_ratio = 1.0
		is_typing = false
		advance_hint.visible = true
		return
	if exercise.is_empty():
		set_state(State.MAP)
		return
	_open_exercise()

# =====================================================================
# Exercise
# =====================================================================
func _build_exercise() -> void:
	exercise_screen = Control.new()
	exercise_screen.name = "ExerciseScreen"
	exercise_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	exercise_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(exercise_screen)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exercise_screen.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -380; panel.offset_right = 380
	panel.offset_top = -230; panel.offset_bottom = 230
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#1e1a16f2"), Color("#c9a36b")))
	exercise_screen.add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	prompt_label = Label.new()
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 20)
	prompt_label.custom_minimum_size = Vector2(720, 0)
	v.add_child(prompt_label)

	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", Color("#a0c0ff"))
	hint_label.add_theme_font_size_override("font_size", 16)
	hint_label.visible = false
	v.add_child(hint_label)

	# ---- basket layout ----
	basket_row = HBoxContainer.new()
	basket_row.alignment = BoxContainer.ALIGNMENT_CENTER
	basket_row.add_theme_constant_override("separation", 24)
	basket_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(basket_row)

	var src_box := VBoxContainer.new()
	src_box.alignment = BoxContainer.ALIGNMENT_CENTER
	basket_row.add_child(src_box)
	var src_title := Label.new()
	src_title.name = "SourceTitle"
	src_title.text = "New items"
	src_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	src_box.add_child(src_title)
	source_title = src_title
	var src_panel := PanelContainer.new()
	src_panel.custom_minimum_size = Vector2(230, 140)
	src_panel.add_theme_stylebox_override("panel", _panel_style(Color("#2a3a22"), Color("#5c7a4a")))
	src_box.add_child(src_panel)
	source_items = HBoxContainer.new()
	source_items.name = "SourceItems"
	source_items.alignment = BoxContainer.ALIGNMENT_CENTER
	src_panel.add_child(source_items)

	basket_zone = _make_drop_zone("BasketDropZone", Color("#6b4a2b"))
	basket_row.add_child(basket_zone)
	var bz_v := basket_zone.get_child(0) as VBoxContainer
	basket_counter = bz_v.get_node("Title") as Label
	basket_items = bz_v.get_node("Items") as HBoxContainer

	tray_zone = _make_drop_zone("TrayDropZone", Color("#3b5a6b"))
	basket_row.add_child(tray_zone)
	var tz_v := tray_zone.get_child(0) as VBoxContainer
	tray_label = tz_v.get_node("Title") as Label
	tray_items = tz_v.get_node("Items") as HBoxContainer

	equation_label = Label.new()
	equation_label.name = "EquationLabel"
	equation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equation_label.add_theme_font_size_override("font_size", 18)
	equation_label.add_theme_color_override("font_color", Color("#ffd75a"))
	equation_label.custom_minimum_size = Vector2(720, 0)
	equation_label.visible = false
	v.add_child(equation_label)

	addition_summary = HBoxContainer.new()
	addition_summary.name = "AdditionVisualSummary"
	addition_summary.alignment = BoxContainer.ALIGNMENT_CENTER
	addition_summary.add_theme_constant_override("separation", 14)
	addition_summary.visible = false
	v.add_child(addition_summary)

	var existing_group := VBoxContainer.new()
	existing_group.alignment = BoxContainer.ALIGNMENT_CENTER
	addition_summary.add_child(existing_group)
	var existing_title := Label.new()
	existing_title.text = "Already in the basket"
	existing_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	existing_title.add_theme_font_size_override("font_size", 15)
	existing_group.add_child(existing_title)
	var existing_panel := PanelContainer.new()
	existing_panel.custom_minimum_size = Vector2(260, 58)
	existing_panel.add_theme_stylebox_override("panel", _panel_style(Color("#6b4a2b"), Color("#a77a4b")))
	existing_group.add_child(existing_panel)
	addition_existing_items = HFlowContainer.new()
	addition_existing_items.alignment = FlowContainer.ALIGNMENT_CENTER
	addition_existing_items.add_theme_constant_override("h_separation", 4)
	existing_panel.add_child(addition_existing_items)

	var plus := Label.new()
	plus.text = "+"
	plus.add_theme_font_size_override("font_size", 32)
	plus.add_theme_color_override("font_color", Color("#ffd75a"))
	addition_summary.add_child(plus)

	var added_group := VBoxContainer.new()
	added_group.alignment = BoxContainer.ALIGNMENT_CENTER
	addition_summary.add_child(added_group)
	var added_title := Label.new()
	added_title.text = "Added now"
	added_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	added_title.add_theme_font_size_override("font_size", 15)
	added_group.add_child(added_title)
	var added_panel := PanelContainer.new()
	added_panel.custom_minimum_size = Vector2(260, 58)
	added_panel.add_theme_stylebox_override("panel", _panel_style(Color("#2a3a22"), Color("#5c7a4a")))
	added_group.add_child(added_panel)
	addition_added_items = HFlowContainer.new()
	addition_added_items.alignment = FlowContainer.ALIGNMENT_CENTER
	addition_added_items.add_theme_constant_override("h_separation", 4)
	added_panel.add_child(addition_added_items)

	done_btn = Button.new()
	done_btn.name = "DoneButton"
	done_btn.text = "Done!"
	done_btn.custom_minimum_size = Vector2(140, 42)
	done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done_btn.add_theme_font_size_override("font_size", 18)
	done_btn.pressed.connect(_on_done)
	v.add_child(done_btn)

	# ---- text layout ----
	text_row = VBoxContainer.new()
	text_row.alignment = BoxContainer.ALIGNMENT_CENTER
	text_row.add_theme_constant_override("separation", 10)
	text_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(text_row)

	icon_grid = GridContainer.new()
	icon_grid.name = "IconGrid"
	icon_grid.add_theme_constant_override("h_separation", 6)
	icon_grid.add_theme_constant_override("v_separation", 6)
	icon_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_grid.visible = false
	text_row.add_child(icon_grid)

	var input_h := HBoxContainer.new()
	input_h.alignment = BoxContainer.ALIGNMENT_CENTER
	input_h.add_theme_constant_override("separation", 8)
	text_row.add_child(input_h)
	answer_input = LineEdit.new()
	answer_input.name = "AnswerInput"
	answer_input.placeholder_text = "Type a number"
	answer_input.custom_minimum_size = Vector2(180, 40)
	answer_input.max_length = 3
	answer_input.add_theme_font_size_override("font_size", 20)
	answer_input.text_changed.connect(_digits_only)
	answer_input.text_submitted.connect(func(_t): _on_submit())
	input_h.add_child(answer_input)
	submit_btn = Button.new()
	submit_btn.name = "SubmitButton"
	submit_btn.text = "Submit"
	submit_btn.custom_minimum_size = Vector2(100, 40)
	submit_btn.pressed.connect(_on_submit)
	input_h.add_child(submit_btn)

	# ---- visual multiplication/division layout ----
	visual_row = VBoxContainer.new()
	visual_row.name = "VisualMathRow"
	visual_row.alignment = BoxContainer.ALIGNMENT_CENTER
	visual_row.add_theme_constant_override("separation", 8)
	visual_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(visual_row)

	visual_source_title = Label.new()
	visual_source_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visual_source_title.add_theme_font_size_override("font_size", 16)
	visual_row.add_child(visual_source_title)

	visual_source_panel = PanelContainer.new()
	visual_source_panel.custom_minimum_size = Vector2(700, 64)
	visual_source_panel.add_theme_stylebox_override("panel", _panel_style(Color("#2a3a22"), Color("#5c7a4a")))
	visual_row.add_child(visual_source_panel)
	visual_source_items = HFlowContainer.new()
	visual_source_items.name = "VisualSourceItems"
	visual_source_items.alignment = FlowContainer.ALIGNMENT_CENTER
	visual_source_items.add_theme_constant_override("h_separation", 4)
	visual_source_items.add_theme_constant_override("v_separation", 4)
	visual_source_panel.add_child(visual_source_items)

	visual_zones = HBoxContainer.new()
	visual_zones.name = "VisualZones"
	visual_zones.alignment = BoxContainer.ALIGNMENT_CENTER
	visual_zones.add_theme_constant_override("separation", 8)
	visual_row.add_child(visual_zones)

func _make_drop_zone(zone_name: String, tint: Color) -> PanelContainer:
	var zone := PanelContainer.new()
	zone.name = zone_name
	zone.custom_minimum_size = Vector2(230, 170)
	zone.add_theme_stylebox_override("panel", _panel_style(tint, tint.lightened(0.35)))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	zone.add_child(v)
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	v.add_child(title)
	var items := HBoxContainer.new()
	items.name = "Items"
	items.alignment = BoxContainer.ALIGNMENT_CENTER
	items.custom_minimum_size = Vector2(0, 100)
	v.add_child(items)
	var ghost := Label.new()
	ghost.name = "Ghost"
	ghost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ghost.add_theme_font_size_override("font_size", 40)
	ghost.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	ghost.visible = false
	v.add_child(ghost)
	# The zone itself accepts drops; the script below is attached at runtime.
	zone.set_script(DropZoneScript)
	zone.flow = self
	return zone

func _make_array_cell(index: int) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.name = "ArrayCell_%d" % index
	cell.custom_minimum_size = Vector2(48, 48)
	cell.add_theme_stylebox_override("panel", _panel_style(Color("#6b4a2b"), Color("#c9a36b")))
	var center := CenterContainer.new()
	center.name = "Items"
	cell.add_child(center)
	cell.set_script(DropZoneScript)
	cell.flow = self
	return cell

func _make_share_zone(index: int) -> PanelContainer:
	var zone := PanelContainer.new()
	zone.name = "ShareZone_%d" % index
	zone.custom_minimum_size = Vector2(125, 125)
	zone.add_theme_stylebox_override("panel", _panel_style(Color("#6b4a2b"), Color("#a77a4b")))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	zone.add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	column.add_child(title)
	var items := HFlowContainer.new()
	items.name = "Items"
	items.alignment = FlowContainer.ALIGNMENT_CENTER
	items.custom_minimum_size = Vector2(95, 70)
	items.add_theme_constant_override("h_separation", 2)
	items.add_theme_constant_override("v_separation", 2)
	column.add_child(items)
	zone.set_meta("items", items)
	zone.set_script(DropZoneScript)
	zone.flow = self
	share_titles.append(title)
	return zone

func _clear_visual() -> void:
	_clear(visual_source_items)
	_clear(visual_zones)
	visual_cells.clear()
	share_zones.clear()
	share_titles.clear()

func _open_array(icon: String) -> void:
	var dimensions: Array = exercise.get("grid", [1, 1])
	var rows: int = int(dimensions[0])
	var columns: int = int(dimensions[1])
	visual_source_title.visible = true
	visual_source_panel.visible = true
	visual_source_title.text = "%s to place: %d" % [POOL_LABELS.get(npc.item, "Items"), rows * columns]
	for i in rows * columns:
		visual_source_items.add_child(_make_item(icon, true, 32))
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	visual_zones.add_child(grid)
	for i in rows * columns:
		var cell := _make_array_cell(i)
		visual_cells.append(cell)
		grid.add_child(cell)

func _open_share(icon: String) -> void:
	var groups: int = int(exercise.get("groups", 1))
	var per_group: int = int(exercise.get("answer", 0))
	var total: int = groups * per_group
	visual_source_title.visible = true
	visual_source_panel.visible = true
	visual_source_title.text = "To share: %d" % total
	for i in total:
		visual_source_items.add_child(_make_item(icon, true, 32))
	for i in groups:
		var zone := _make_share_zone(i)
		share_zones.append(zone)
		visual_zones.add_child(zone)
	_update_share_status(false)

func _open_exercise() -> void:
	set_state(State.EXERCISE)
	prompt_label.text = exercise.setup
	hint_label.visible = false
	hint_label.text = ""
	equation_label.visible = false
	equation_label.text = ""
	addition_summary.visible = false
	_clear(addition_existing_items)
	_clear(addition_added_items)
	_clear(basket_items); _clear(source_items); _clear(tray_items); _clear(icon_grid)
	_clear_visual()
	icon_grid.visible = false
	(basket_zone.get_child(0).get_node("Ghost") as Label).visible = false
	basket_count = 0
	var mode: String = exercise.mode
	basket_row.visible = mode in ["basket_in", "basket_out"]
	done_btn.visible = mode != "text"
	text_row.visible = mode == "text"
	visual_row.visible = mode in ["array", "share"]
	var icon: String = ITEM_ICONS.get(npc.item, "")
	match mode:
		"basket_in":
			tray_zone.visible = false
			source_items.get_parent().get_parent().visible = true
			for i in exercise.a:
				basket_items.add_child(_make_item(icon, false))
			basket_count = exercise.a
			# Pool always has more draggable items than strictly needed (b) so
			# the child must recognize the target, not just clear the screen.
			var pool_size: int = int(exercise.b) + POOL_EXTRA
			for i in pool_size:
				source_items.add_child(_make_item(icon, true))
			_update_basket_counter()
		"basket_out":
			tray_zone.visible = true
			source_items.get_parent().get_parent().visible = false
			for i in exercise.start:
				basket_items.add_child(_make_item(icon, true))
			basket_count = exercise.start
			_update_basket_counter()
		"text":
			answer_input.text = ""
			answer_input.editable = true
			submit_btn.disabled = false
			answer_input.grab_focus()
		"array":
			_open_array(icon)
		"share":
			_open_share(icon)

func _update_basket_counter() -> void:
	var target: int = int(exercise.get("answer", basket_count))
	basket_counter.text = "%s: %d/%d" % [npc.get("container", "Basket").capitalize(), basket_count, target]
	var mode: String = exercise.get("mode", "")
	if mode == "basket_in":
		# Source (Nest) counts DOWN as items leave it — half the operation
		# was previously invisible once dragged.
		source_title.text = "%s: %d" % [POOL_LABELS.get(npc.item, "Supply"), source_items.get_child_count()]
	elif mode == "basket_out":
		# Removal tray counts UP toward the amount that's meant to leave,
		# instead of items just vanishing with nothing tracking where they went.
		var removed: int = int(exercise.get("start", basket_count)) - basket_count
		var remove_target: int = int(exercise.get("remove", removed))
		tray_label.text = "%s: %d/%d" % [exercise.get("tray", "Out"), removed, remove_target]
	if basket_count == target:
		_show_equation()

func _show_equation() -> void:
	var mode: String = exercise.get("mode", "")
	if mode == "basket_in":
		_show_addition_summary(int(exercise.a), int(exercise.b))
		return
	var words := ""
	var symbols := ""
	if mode == "basket_out":
		var start: int = int(exercise.start)
		var removed: int = int(exercise.get("remove", start - int(exercise.answer)))
		words = "%s had %d %s.\n%s gave %d away." % [npc.display_name, start, _item_plural(), npc.display_name, removed]
		symbols = "%d - %d = %d" % [start, removed, int(exercise.answer)]
	if symbols.is_empty():
		return
	equation_label.text = words + "\n" + symbols
	equation_label.visible = true

func _show_addition_summary(existing: int, added: int) -> void:
	_clear(addition_existing_items)
	_clear(addition_added_items)
	var icon: String = ITEM_ICONS.get(npc.item, "")
	for i in existing:
		addition_existing_items.add_child(_make_item(icon, false, 32))
	for i in added:
		addition_added_items.add_child(_make_item(icon, false, 32))
	equation_label.visible = false
	addition_summary.visible = true

func _item_plural() -> String:
	var item: String = npc.get("item", "items")
	return item if item.ends_with("s") else item + "s"

func _make_item(icon_path: String, draggable: bool, item_size: int = 40) -> Control:
	var item := TextureRect.new()
	item.texture = load(icon_path) as Texture2D
	item.custom_minimum_size = Vector2(item_size, item_size)
	item.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.mouse_filter = Control.MOUSE_FILTER_STOP if draggable else Control.MOUSE_FILTER_IGNORE
	if draggable:
		item.set_script(DragItemScript)
	return item

# Called by drop zones (native Godot DnD) and by the JS test bridge.
func drop_into(zone_name: String, source: Control) -> void:
	if state != State.EXERCISE:
		return
	var mode: String = exercise.mode
	if mode == "array" and zone_name.begins_with("ArrayCell_"):
		var index := int(zone_name.trim_prefix("ArrayCell_"))
		if index < 0 or index >= visual_cells.size() or source.get_parent() != visual_source_items:
			return
		var cell: PanelContainer = visual_cells[index]
		var target: Control = cell.get_child(0)
		if target.get_child_count() > 0:
			return
		source.reparent(target)
		source.mouse_filter = Control.MOUSE_FILTER_IGNORE
		source.set_script(null)
		_emit_placement_feedback(cell, visual_cells.size() - visual_source_items.get_child_count())
		visual_source_title.text = "%s to place: %d" % [POOL_LABELS.get(npc.item, "Items"), visual_source_items.get_child_count()]
		if visual_source_items.get_child_count() == 0:
			visual_source_title.visible = false
			visual_source_panel.visible = false
			var dimensions: Array = exercise.get("grid", [1, 1])
			var rows := int(dimensions[0])
			var columns := int(dimensions[1])
			equation_label.text = "%d groups of %d = %d\n%d x %d = %d, and %d x %d = %d too" % [rows, columns, int(exercise.answer), rows, columns, int(exercise.answer), columns, rows, int(exercise.answer)]
			equation_label.visible = true
		return
	if mode == "share" and zone_name.begins_with("ShareZone_"):
		var index := int(zone_name.trim_prefix("ShareZone_"))
		if index < 0 or index >= share_zones.size():
			return
		var zone: PanelContainer = share_zones[index]
		var target: Control = zone.get_meta("items") as Control
		if source == null or source.get_parent() == target:
			return
		if source.get_parent() != visual_source_items and not _is_share_items_container(source.get_parent()):
			return
		source.reparent(target)
		hint_label.visible = false
		_emit_placement_feedback(zone, target.get_child_count())
		_update_share_status(false)
		return
	if mode == "basket_in" and zone_name == "BasketDropZone" and source.get_parent() == source_items:
		source.get_parent().remove_child(source)
		source.mouse_filter = Control.MOUSE_FILTER_IGNORE
		source.set_script(null)
		basket_items.add_child(source)
		basket_count += 1
		_update_basket_counter()
		if basket_count > int(exercise.answer):
			_resolve(false)
	elif mode == "basket_out" and zone_name == "TrayDropZone" and source.get_parent() == basket_items:
		source.get_parent().remove_child(source)
		source.mouse_filter = Control.MOUSE_FILTER_IGNORE
		source.set_script(null)
		tray_items.add_child(source)
		basket_count -= 1
		_update_basket_counter()
		if basket_count < int(exercise.answer):
			_resolve(false)

func _is_share_items_container(node: Node) -> bool:
	for zone in share_zones:
		if zone.get_meta("items") == node:
			return true
	return false

func _update_share_status(highlight_imbalance: bool) -> bool:
	var expected: int = int(exercise.get("answer", 0))
	var balanced := visual_source_items.get_child_count() == 0
	visual_source_title.text = "To share: %d" % visual_source_items.get_child_count()
	for i in share_zones.size():
		var items: Control = share_zones[i].get_meta("items") as Control
		var count := items.get_child_count()
		var wrong := count != expected
		balanced = balanced and not wrong
		share_titles[i].text = "Group %d: %d%s" % [i + 1, count, " ?" if highlight_imbalance and wrong else ""]
		share_titles[i].add_theme_color_override("font_color", Color("#ffb0a5") if highlight_imbalance and wrong else Color("#f5e9cf"))
	if balanced:
		visual_source_title.visible = false
		visual_source_panel.visible = false
		var groups := share_zones.size()
		var total := groups * expected
		equation_label.text = "%d items shared equally\n%d / %d = %d each" % [total, total, groups, expected]
		equation_label.visible = true
	else:
		equation_label.visible = false
	return balanced

func _emit_placement_feedback(zone: Control, count: int) -> void:
	pop_events += 1
	bump_events += 1
	if pop_player:
		pop_player.play()
	var number := Label.new()
	number.text = str(count)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.z_index = 20
	number.add_theme_font_size_override("font_size", 20)
	number.add_theme_color_override("font_color", Color("#ffd75a"))
	var starts_above := zone.name.begins_with("ShareZone_")
	number.position = Vector2(zone.size.x * 0.5 - 6, -20 if starts_above else 4)
	zone.add_child(number)
	var tween := number.create_tween().set_parallel(true)
	tween.tween_property(number, "position:y", -42.0 if starts_above else -18.0, 0.45)
	tween.tween_property(number, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(number.queue_free)

## The child presses Done when the physical quantity looks right.
func _on_done() -> void:
	if state != State.EXERCISE or exercise.mode == "text":
		return
	if exercise.mode == "array":
		if visual_source_items.get_child_count() > 0:
			hint_label.text = "Keep filling the rows. Every space needs one item."
			hint_label.visible = true
			return
		_resolve(true)
		return
	if exercise.mode == "share":
		if not _update_share_status(true):
			wrong_attempts += 1
			hint_label.text = "Not equal yet. Move items until every group has the same amount."
			hint_label.visible = true
			return
		_resolve(true)
		return
	_resolve(basket_count == int(exercise.answer))

func _digits_only(t: String) -> void:
	var clean := ""
	for c in t:
		if c >= "0" and c <= "9":
			clean += c
	if clean != t:
		answer_input.text = clean
		answer_input.caret_column = clean.length()

func _on_submit() -> void:
	if state != State.EXERCISE or exercise.mode != "text":
		return
	var t := answer_input.text.strip_edges()
	if t.is_empty():
		return
	_resolve(int(t) == int(exercise.answer))

func _build_pop_audio() -> void:
	pop_player = AudioStreamPlayer.new()
	pop_player.name = "PlacementPop"
	add_child(pop_player)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.stereo = false
	var samples := int(wav.mix_rate * 0.075)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var fade := 1.0 - float(i) / float(samples)
		var frequency := 520.0 + 360.0 * float(i) / float(samples)
		var value := int(sin(TAU * frequency * float(i) / float(wav.mix_rate)) * 7000.0 * fade)
		data.encode_s16(i * 2, value)
	wav.data = data
	pop_player.stream = wav

# =====================================================================
# Feedback
# =====================================================================
func _build_feedback() -> void:
	feedback_screen = Control.new()
	feedback_screen.name = "FeedbackScreen"
	feedback_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(feedback_screen)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_screen.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -300; panel.offset_right = 300
	panel.offset_top = -90; panel.offset_bottom = 90
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#1e1a16f2"), Color("#c9a36b")))
	feedback_screen.add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	result_icon = Label.new()
	result_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_icon.add_theme_font_size_override("font_size", 40)
	v.add_child(result_icon)
	result_label = Label.new()
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	result_label.custom_minimum_size = Vector2(560, 0)
	v.add_child(result_label)

	feedback_addition_summary = HBoxContainer.new()
	feedback_addition_summary.alignment = BoxContainer.ALIGNMENT_CENTER
	feedback_addition_summary.add_theme_constant_override("separation", 12)
	feedback_addition_summary.visible = false
	v.add_child(feedback_addition_summary)
	var existing_group := VBoxContainer.new()
	feedback_addition_summary.add_child(existing_group)
	var existing_title := Label.new()
	existing_title.text = "Already in the basket"
	existing_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	existing_group.add_child(existing_title)
	feedback_existing_items = HFlowContainer.new()
	feedback_existing_items.custom_minimum_size = Vector2(220, 34)
	feedback_existing_items.alignment = FlowContainer.ALIGNMENT_CENTER
	existing_group.add_child(feedback_existing_items)
	var plus := Label.new()
	plus.text = "+"
	plus.add_theme_font_size_override("font_size", 28)
	plus.add_theme_color_override("font_color", Color("#ffd75a"))
	feedback_addition_summary.add_child(plus)
	var added_group := VBoxContainer.new()
	feedback_addition_summary.add_child(added_group)
	var added_title := Label.new()
	added_title.text = "Added now"
	added_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	added_group.add_child(added_title)
	feedback_added_items = HFlowContainer.new()
	feedback_added_items.custom_minimum_size = Vector2(220, 34)
	feedback_added_items.alignment = FlowContainer.ALIGNMENT_CENTER
	added_group.add_child(feedback_added_items)

func _resolve(correct: bool) -> void:
	last_correct = correct
	set_state(State.FEEDBACK)
	feedback_addition_summary.visible = false
	_clear(feedback_existing_items)
	_clear(feedback_added_items)
	if correct:
		result_icon.text = "OK"
		result_icon.add_theme_color_override("font_color", Color("#ffd75a"))
		if exercise.get("mode", "") == "basket_in":
			result_label.text = "Great! You combined both groups."
			var icon: String = ITEM_ICONS.get(npc.item, "")
			for i in int(exercise.a):
				feedback_existing_items.add_child(_make_item(icon, false, 28))
			for i in int(exercise.b):
				feedback_added_items.add_child(_make_item(icon, false, 28))
			feedback_addition_summary.visible = true
		else:
			result_label.text = exercise.success
	else:
		wrong_attempts += 1
		result_icon.text = "X"
		result_icon.add_theme_color_override("font_color", Color("#ff7f7f"))
		result_label.text = "Not quite - let's try again!"
	await get_tree().create_timer(FEEDBACK_SECONDS).timeout
	if state != State.FEEDBACK:
		return
	if correct:
		var done_phase: int = exercise.phase
		world.advance_phase(npc.id)
		phase_completed.emit(npc.id, done_phase)
		if exercise.get("final", false):
			world_completed.emit()
		set_state(State.MAP)
	else:
		_open_exercise()
		_apply_hints()

func _apply_hints() -> void:
	if wrong_attempts >= 1:
		hint_label.text = "Hint: " + exercise.get("hint1", "")
		hint_label.visible = true
	if wrong_attempts >= 2:
		match exercise.mode:
			"basket_in":
				var ghost := basket_zone.get_child(0).get_node("Ghost") as Label
				ghost.text = "O ".repeat(exercise.answer).strip_edges()
				ghost.add_theme_font_size_override("font_size", 22)
				ghost.visible = true
			"basket_out":
				var ghost := basket_zone.get_child(0).get_node("Ghost") as Label
				ghost.text = str(exercise.answer)
				ghost.add_theme_font_size_override("font_size", 40)
				ghost.visible = true
			"text":
				var g: Array = exercise.get("grid", [1, 1])
				icon_grid.columns = int(g[1])
				var icon: String = ITEM_ICONS.get(npc.item, "")
				for i in int(g[0]) * int(g[1]):
					icon_grid.add_child(_make_item(icon, false))
				icon_grid.visible = true

func _clear(c: Node) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()

# =====================================================================
# Test / bridge helpers
# =====================================================================
func debug_state() -> Dictionary:
	return {
		"state": state_name(),
		"npc": npc.get("id", ""),
		"phase": exercise.get("phase", 0),
		"mode": exercise.get("mode", ""),
		"basket_count": basket_count,
		"target": int(exercise.get("answer", basket_count)),
		"source_left": source_items.get_child_count() if source_items else 0,
		"visual_source_left": visual_source_items.get_child_count() if visual_source_items else 0,
		"visual_cells": visual_cells.size(),
		"share_groups": share_zones.size(),
		"tray_count": tray_items.get_child_count() if tray_items else 0,
		"wrong_attempts": wrong_attempts,
		"hint_visible": hint_label.visible if hint_label else false,
		"hint_text": hint_label.text if hint_label else "",
		"ghost_visible": (basket_zone.get_child(0).get_node("Ghost") as Label).visible if basket_zone else false,
		"icon_grid_visible": icon_grid.visible if icon_grid else false,
		"icon_grid_count": icon_grid.get_child_count() if icon_grid else 0,
		"dialogue_text": dialogue_text.text if dialogue_text else "",
		"is_typing": is_typing,
		"result_text": result_label.text if result_label else "",
		"last_correct": last_correct,
	}

## Programmatic drag for tests: moves one draggable from its source area into
## the target zone exactly as a real drop would.
func debug_drag_one(target_zone: String) -> bool:
	var mode: String = exercise.get("mode", "")
	var from: Control
	if mode in ["array", "share"]:
		from = visual_source_items
	else:
		from = source_items if mode == "basket_in" else basket_items
	for ch in from.get_children():
		if ch.get_script() == DragItemScript:
			drop_into(target_zone, ch)
			return true
	return false

func debug_submit(text: String) -> void:
	answer_input.text = text
	_on_submit()

func debug_done() -> void:
	_on_done()

# =====================================================================
# Native drag-and-drop scripts (attached at runtime)
# =====================================================================
const DragItemScript := preload("res://scripts/ui/drag_item.gd")
const DropZoneScript := preload("res://scripts/ui/drop_zone.gd")
