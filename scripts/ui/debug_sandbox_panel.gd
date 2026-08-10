extends PanelContainer
class_name DebugSandboxPanel

signal generation_requested(floor_number: int, run_seed: int)
signal commissar_test_requested
signal freeze_changed(enabled: bool)
signal invincibility_changed(enabled: bool)
signal max_charge_changed(enabled: bool)
signal max_overdrive_changed(enabled: bool)
signal overdrive_effect_changed(effect_id: String, stacks: int)
signal permanent_stat_changed(stat_id: String, stacks: int)

const OVERDRIVE_OPTIONS := {
	"spread_shot": "Spread",
	"piercing_shot": "Piercing",
	"chain_lightning": "Lightning",
	"fire_burst": "Fire",
	"water_swell": "Water"
}
const STAT_OPTIONS := {
	"faster_reflexes": {"label": "Fire Rate", "max": 16},
	"runner_legs": {"label": "Move Speed", "max": 16},
	"heavy_tears": {"label": "Damage", "max": 14},
	"fat_tears": {"label": "Projectile Size", "max": 14},
	"overdrive_capacity": {"label": "OD Capacity", "max": 12}
}

var _floor_spin: SpinBox
var _seed_edit: LineEdit
var _status_label: Label
var _freeze_toggle: CheckButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2(18.0, 82.0)
	var available_height: float = max(get_viewport_rect().size.y - position.y - 18.0, 320.0)
	custom_minimum_size = Vector2(400.0, min(available_height, 620.0))
	_build_ui()


func toggle_visible() -> void:
	visible = not visible
	if visible and _floor_spin != null:
		_floor_spin.grab_focus()


func set_generation_values(floor_number: int, run_seed: int) -> void:
	if _floor_spin != null:
		_floor_spin.value = max(floor_number, 1)
	if _seed_edit != null:
		_seed_edit.text = str(max(run_seed, 1))


func set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func set_freeze_enabled(value: bool) -> void:
	if _freeze_toggle != null:
		_freeze_toggle.set_pressed_no_signal(value)


func _build_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)
	var title := Label.new()
	title.text = "DEVELOPER SANDBOX  [F3]"
	title.add_theme_font_size_override("font_size", 18)
	root.add_child(title)

	var generation_row := HBoxContainer.new()
	root.add_child(generation_row)
	_floor_spin = SpinBox.new()
	_floor_spin.min_value = 1
	_floor_spin.max_value = 99
	_floor_spin.value = 1
	_floor_spin.prefix = "Floor "
	_floor_spin.custom_minimum_size.x = 112.0
	generation_row.add_child(_floor_spin)
	_seed_edit = LineEdit.new()
	_seed_edit.placeholder_text = "Run seed"
	_seed_edit.text = "1"
	_seed_edit.custom_minimum_size.x = 132.0
	generation_row.add_child(_seed_edit)
	var generate_button := Button.new()
	generate_button.text = "Generate"
	generate_button.pressed.connect(_on_generate_pressed)
	generation_row.add_child(generate_button)
	var commissar_test_button := Button.new()
	commissar_test_button.text = "Load Commissar Test"
	commissar_test_button.tooltip_text = "Builds the tier-one Commissar and repair-corps encounter on its dedicated generated floor."
	commissar_test_button.pressed.connect(func() -> void: commissar_test_requested.emit())
	root.add_child(commissar_test_button)

	_freeze_toggle = _add_toggle(root, "Freeze world (player moves)", freeze_changed)
	_add_toggle(root, "Player invincible", invincibility_changed)
	_add_toggle(root, "Charge shot always max", max_charge_changed)
	_add_toggle(root, "Overdrive ammo always max", max_overdrive_changed)
	root.add_child(HSeparator.new())
	_add_heading(root, "Overdrive Effects")
	var overdrive_grid := GridContainer.new()
	overdrive_grid.columns = 2
	root.add_child(overdrive_grid)
	for effect_id in OVERDRIVE_OPTIONS:
		_add_stack_control(overdrive_grid, String(OVERDRIVE_OPTIONS[effect_id]), String(effect_id), 99, overdrive_effect_changed)
	_add_heading(root, "Permanent Stats")
	var stat_grid := GridContainer.new()
	stat_grid.columns = 2
	root.add_child(stat_grid)
	for stat_id in STAT_OPTIONS:
		var option: Dictionary = STAT_OPTIONS[stat_id]
		_add_stack_control(stat_grid, String(option["label"]), String(stat_id), int(option["max"]), permanent_stat_changed)
	_status_label = Label.new()
	_status_label.text = "Sandbox inactive"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)


func _add_heading(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	parent.add_child(label)


func _add_toggle(parent: Control, text: String, target_signal: Signal) -> CheckButton:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.toggled.connect(func(value: bool) -> void: target_signal.emit(value))
	parent.add_child(toggle)
	return toggle


func _add_stack_control(parent: Control, text: String, id: String, maximum: int, target_signal: Signal) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)
	var stacks := SpinBox.new()
	stacks.min_value = 0
	stacks.max_value = max(maximum, 1)
	stacks.step = 1
	stacks.value = 0
	stacks.allow_greater = false
	stacks.custom_minimum_size.x = 92.0
	stacks.value_changed.connect(func(value: float) -> void: target_signal.emit(id, max(roundi(value), 0)))
	parent.add_child(stacks)


func _on_generate_pressed() -> void:
	var parsed_seed: int = int(_seed_edit.text)
	if parsed_seed <= 0:
		parsed_seed = 1
		_seed_edit.text = "1"
	generation_requested.emit(max(roundi(_floor_spin.value), 1), parsed_seed)
