extends PanelContainer
class_name DebugSandboxPanel

signal generation_requested(floor_number: int, run_seed: int)
signal freeze_changed(enabled: bool)
signal invincibility_changed(enabled: bool)
signal max_charge_changed(enabled: bool)
signal max_overdrive_changed(enabled: bool)
signal overdrive_effect_changed(effect_id: String, enabled: bool)
signal permanent_stat_changed(stat_id: String, enabled: bool)

const OVERDRIVE_OPTIONS := {
	"spread_shot": "Spread",
	"piercing_shot": "Piercing",
	"chain_lightning": "Lightning",
	"fire_burst": "Fire",
	"water_swell": "Water"
}
const STAT_OPTIONS := {
	"faster_reflexes": "Fire Rate",
	"runner_legs": "Move Speed",
	"heavy_tears": "Damage",
	"fat_tears": "Projectile Size",
	"overdrive_capacity": "OD Capacity"
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
	custom_minimum_size = Vector2(360.0, 0.0)
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
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	add_child(root)
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
		_add_id_toggle(overdrive_grid, String(OVERDRIVE_OPTIONS[effect_id]), String(effect_id), overdrive_effect_changed)
	_add_heading(root, "Permanent Stats")
	var stat_grid := GridContainer.new()
	stat_grid.columns = 2
	root.add_child(stat_grid)
	for stat_id in STAT_OPTIONS:
		_add_id_toggle(stat_grid, String(STAT_OPTIONS[stat_id]), String(stat_id), permanent_stat_changed)
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


func _add_id_toggle(parent: Control, text: String, id: String, target_signal: Signal) -> void:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.toggled.connect(func(value: bool) -> void: target_signal.emit(id, value))
	parent.add_child(toggle)


func _on_generate_pressed() -> void:
	var parsed_seed: int = int(_seed_edit.text)
	if parsed_seed <= 0:
		parsed_seed = 1
		_seed_edit.text = "1"
	generation_requested.emit(max(roundi(_floor_spin.value), 1), parsed_seed)
