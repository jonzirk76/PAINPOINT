extends Control

const TWIST_SCENE := preload("res://scenes/characters/neutral_polygon_base/neutral_polygon_twist_8_way.tscn")
const DIRECTION_NAMES := ["S", "SW", "W", "NW", "N", "NE", "E", "SE"]
const REST_COLUMN_COUNT := 1
const AIM_COLUMN_COUNT := 8
const FORESHORTENING_STEP := 0.05

## [Description] Display scale used by each frozen humanoid combination in the matrix.
@export_range(0.1, 0.5, 0.01) var figure_scale: float = 0.28
## [Description] Width reserved for each rest or aim combination cell.
@export_range(120.0, 260.0, 5.0) var cell_width: float = 175.0
## [Description] Height reserved for each hips-direction row.
@export_range(110.0, 240.0, 5.0) var cell_height: float = 150.0

@onready var matrix_canvas: Control = $MatrixScroll/MatrixCanvas
@onready var build_status: Label = $Header/BuildStatus

var _poses: Array[Node2D] = []
var _seam_enabled: bool = true
var _foreshortening: float = 0.65


func _ready() -> void:
	_build_matrix()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	elif event.keycode == KEY_T:
		_seam_enabled = not _seam_enabled
		for pose in _poses:
			pose.set("torso_hip_seam_enabled", _seam_enabled)
		_update_build_status()
	elif event.keycode == KEY_BRACKETLEFT:
		_set_foreshortening(_foreshortening - FORESHORTENING_STEP)
	elif event.keycode == KEY_BRACKETRIGHT:
		_set_foreshortening(_foreshortening + FORESHORTENING_STEP)


func _build_matrix() -> void:
	_poses.clear()
	for child in matrix_canvas.get_children():
		child.queue_free()
	var row_label_width := 100.0
	var header_height := 44.0
	var column_count := REST_COLUMN_COUNT + AIM_COLUMN_COUNT
	matrix_canvas.custom_minimum_size = Vector2(
		row_label_width + column_count * cell_width + 20.0,
		header_height + DIRECTION_NAMES.size() * cell_height + 20.0
	)
	_add_column_header("REST", 0, row_label_width)
	for aim_direction in AIM_COLUMN_COUNT:
		_add_column_header("AIM %s" % DIRECTION_NAMES[aim_direction], aim_direction + 1, row_label_width)
	for hips_direction in DIRECTION_NAMES.size():
		_add_row(hips_direction, row_label_width, header_height, column_count)
	_update_build_status()


func _add_column_header(text: String, column: int, row_label_width: float) -> void:
	var label := _make_label(text, 13, Color(0.7, 0.9, 1.0))
	label.position = Vector2(row_label_width + column * cell_width, 8.0)
	label.size = Vector2(cell_width, 26.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	matrix_canvas.add_child(label)


func _add_row(hips_direction: int, row_label_width: float, header_height: float, column_count: int) -> void:
	var row_top := header_height + hips_direction * cell_height
	var row_label := _make_label("HIPS\n%s" % DIRECTION_NAMES[hips_direction], 14, Color(0.78, 0.82, 0.9))
	row_label.position = Vector2(8.0, row_top + cell_height * 0.36)
	row_label.size = Vector2(row_label_width - 16.0, 52.0)
	row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	matrix_canvas.add_child(row_label)
	for column in column_count:
		var aim_direction := column - REST_COLUMN_COUNT
		_add_pose_cell(hips_direction, aim_direction, column, row_label_width, row_top)


func _add_pose_cell(
	hips_direction: int,
	aim_direction: int,
	column: int,
	row_label_width: float,
	row_top: float
) -> void:
	var cell_left := row_label_width + column * cell_width
	var backdrop := ColorRect.new()
	backdrop.position = Vector2(cell_left + 2.0, row_top + 2.0)
	backdrop.size = Vector2(cell_width - 4.0, cell_height - 4.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.color = Color(0.075, 0.083, 0.097, 1.0) if (column + hips_direction) % 2 == 0 else Color(0.09, 0.1, 0.115, 1.0)
	matrix_canvas.add_child(backdrop)

	var pose := TWIST_SCENE.instantiate() as Node2D
	pose.position = Vector2(cell_left + cell_width * 0.5, row_top + cell_height - 17.0)
	pose.scale = Vector2.ONE * figure_scale
	matrix_canvas.add_child(pose)
	_poses.append(pose)
	var has_active_aim := aim_direction >= 0
	var desired_direction := aim_direction if has_active_aim else hips_direction
	var aim_vector := _direction_vector(aim_direction) if has_active_aim else Vector2.ZERO
	pose.call("set_pose", hips_direction, desired_direction, false, aim_vector)
	pose.call("set_foreshortening", _foreshortening)
	var resolved: PackedInt32Array = pose.call("get_pose_directions")
	pose.process_mode = Node.PROCESS_MODE_DISABLED

	var chain_label := _make_label(_format_chain(resolved), 11, Color(0.83, 0.85, 0.9))
	chain_label.position = Vector2(cell_left + 4.0, row_top + 5.0)
	chain_label.size = Vector2(cell_width - 8.0, 20.0)
	chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	matrix_canvas.add_child(chain_label)


func _update_build_status() -> void:
	build_status.text = "%d frames  •  SEAM %s  •  SHORT %d%%" % [
		_poses.size(),
		"ON" if _seam_enabled else "OFF",
		roundi(_foreshortening * 100.0),
	]


func _set_foreshortening(value: float) -> void:
	_foreshortening = clampf(value, 0.4, 1.0)
	for pose in _poses:
		pose.call("set_foreshortening", _foreshortening)
	_update_build_status()


func _direction_vector(direction: int) -> Vector2:
	return Vector2.DOWN.rotated(float(direction) * PI * 0.25)


func _format_chain(directions: PackedInt32Array) -> String:
	if directions.size() < 4:
		return "unresolved"
	return "%s · %s · %s · %s" % [
		DIRECTION_NAMES[wrapi(directions[0], 0, 8)],
		DIRECTION_NAMES[wrapi(directions[1], 0, 8)],
		DIRECTION_NAMES[wrapi(directions[2], 0, 8)],
		DIRECTION_NAMES[wrapi(directions[3], 0, 8)],
	]


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
