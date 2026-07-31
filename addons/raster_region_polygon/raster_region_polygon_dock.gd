@tool
extends VBoxContainer

const PreviewScript := preload("res://addons/raster_region_polygon/region_preview.gd")

var _editor_interface: EditorInterface
var _undo_redo: EditorUndoRedoManager
var _source_sprite: Sprite2D
var _source_image: Image
var _seed := Vector2i(-1, -1)
var _trace := PackedVector2Array()

var _preview: Control
var _source_label: Label
var _tolerance_spin: SpinBox
var _epsilon_spin: SpinBox
var _include_alpha_check: CheckBox
var _polygon_name_edit: LineEdit
var _sample_swatch: ColorRect
var _status_label: Label
var _create_button: Button


func initialize(
	editor_interface: EditorInterface,
	undo_redo: EditorUndoRedoManager
) -> void:
	_editor_interface = editor_interface
	_undo_redo = undo_redo


func _ready() -> void:
	name = "RasterRegionPolygonDock"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var intro := Label.new()
	intro.text = "Trace a contiguous color region from a Sprite2D texture."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(intro)

	var use_selection_button := Button.new()
	use_selection_button.text = "Use Selected Sprite2D"
	use_selection_button.pressed.connect(_use_selected_sprite)
	add_child(use_selection_button)

	_source_label = Label.new()
	_source_label.text = "Source: none"
	_source_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_source_label.tooltip_text = "The Sprite2D currently used as the image and output parent."
	add_child(_source_label)

	_preview = PreviewScript.new()
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.image_point_selected.connect(_on_image_point_selected)
	add_child(_preview)

	var settings := GridContainer.new()
	settings.columns = 2
	add_child(settings)

	settings.add_child(_make_label("Tolerance"))
	_tolerance_spin = SpinBox.new()
	_tolerance_spin.min_value = 0.0
	_tolerance_spin.max_value = 1.0
	_tolerance_spin.step = 0.01
	_tolerance_spin.value = 0.08
	_tolerance_spin.tooltip_text = "Maximum per-channel difference from the clicked color."
	_tolerance_spin.value_changed.connect(_on_trace_setting_changed)
	settings.add_child(_tolerance_spin)

	settings.add_child(_make_label("Vertex error"))
	_epsilon_spin = SpinBox.new()
	_epsilon_spin.min_value = 0.0
	_epsilon_spin.max_value = 32.0
	_epsilon_spin.step = 0.25
	_epsilon_spin.value = 1.5
	_epsilon_spin.suffix = " px"
	_epsilon_spin.tooltip_text = "Maximum contour simplification error. Lower values keep more vertices."
	_epsilon_spin.value_changed.connect(_on_trace_setting_changed)
	settings.add_child(_epsilon_spin)

	settings.add_child(_make_label("Compare alpha"))
	_include_alpha_check = CheckBox.new()
	_include_alpha_check.button_pressed = true
	_include_alpha_check.tooltip_text = "Include alpha when comparing pixels to the clicked color."
	_include_alpha_check.toggled.connect(_on_trace_setting_changed)
	settings.add_child(_include_alpha_check)

	settings.add_child(_make_label("Sample"))
	_sample_swatch = ColorRect.new()
	_sample_swatch.custom_minimum_size = Vector2(48.0, 22.0)
	_sample_swatch.color = Color.TRANSPARENT
	settings.add_child(_sample_swatch)

	settings.add_child(_make_label("Node name"))
	_polygon_name_edit = LineEdit.new()
	_polygon_name_edit.text = "TracedRegion"
	settings.add_child(_polygon_name_edit)

	_status_label = Label.new()
	_status_label.text = "Click inside a color region to trace it."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	_create_button = Button.new()
	_create_button.text = "Create Polygon2D Child"
	_create_button.disabled = true
	_create_button.pressed.connect(_create_polygon)
	add_child(_create_button)


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _use_selected_sprite() -> void:
	var selection := _editor_interface.get_selection().get_selected_nodes()
	if selection.size() != 1 or not selection[0] is Sprite2D:
		_set_error("Select exactly one Sprite2D in the scene tree.")
		return

	var sprite := selection[0] as Sprite2D
	if sprite.texture == null:
		_set_error("The selected Sprite2D has no texture.")
		return
	if sprite.region_enabled:
		_set_error("Region-enabled Sprite2D textures are not supported in this first version.")
		return

	var image := sprite.texture.get_image()
	if image == null or image.is_empty():
		_set_error("Godot could not read image data from this texture.")
		return

	_source_sprite = sprite
	_source_image = image
	_seed = Vector2i(-1, -1)
	_trace.clear()
	_source_label.text = "Source: %s" % sprite.name
	_source_label.tooltip_text = str(sprite.get_path())
	_sample_swatch.color = Color.TRANSPARENT
	_preview.set_source(sprite.texture, image)
	_create_button.disabled = true
	_status_label.text = "Click inside a color region to trace it."


func _on_image_point_selected(point: Vector2i) -> void:
	_seed = point
	_rebuild_trace()


func _on_trace_setting_changed(_value: Variant) -> void:
	if _seed.x >= 0:
		_rebuild_trace()


func _rebuild_trace() -> void:
	if _source_image == null or _seed.x < 0:
		return

	var sample := _source_image.get_pixelv(_seed)
	_sample_swatch.color = sample
	var mask := _flood_fill_mask(
		_source_image,
		_seed,
		sample,
		float(_tolerance_spin.value),
		_include_alpha_check.button_pressed
	)
	var polygons := mask.opaque_to_polygons(
		Rect2i(Vector2i.ZERO, mask.get_size()),
		float(_epsilon_spin.value)
	)

	_trace = _find_seed_polygon(polygons, Vector2(_seed) + Vector2(0.5, 0.5))
	_preview.set_trace(_trace, _seed)
	_create_button.disabled = _trace.size() < 3
	if _trace.size() < 3:
		_set_error("The selected region did not produce a usable polygon.")
	else:
		_status_label.text = "%d vertices from %d selected pixels." % [
			_trace.size(),
			mask.get_true_bit_count()
		]


func _flood_fill_mask(
	image: Image,
	seed: Vector2i,
	sample: Color,
	tolerance: float,
	include_alpha: bool
) -> BitMap:
	var image_size := image.get_size()
	var mask := BitMap.new()
	mask.create(image_size)
	var visited := PackedByteArray()
	visited.resize(image_size.x * image_size.y)
	var pending: Array[Vector2i] = [seed]
	visited[seed.y * image_size.x + seed.x] = 1

	while not pending.is_empty():
		var point: Vector2i = pending.pop_back()
		var color := image.get_pixelv(point)
		if not _colors_match(color, sample, tolerance, include_alpha):
			continue
		mask.set_bitv(point, true)

		for offset in [
			Vector2i.LEFT,
			Vector2i.RIGHT,
			Vector2i.UP,
			Vector2i.DOWN
		]:
			var neighbor: Vector2i = point + offset
			if (
				neighbor.x < 0
				or neighbor.y < 0
				or neighbor.x >= image_size.x
				or neighbor.y >= image_size.y
			):
				continue
			var index := neighbor.y * image_size.x + neighbor.x
			if visited[index] != 0:
				continue
			visited[index] = 1
			pending.append(neighbor)

	return mask


func _colors_match(
	color: Color,
	sample: Color,
	tolerance: float,
	include_alpha: bool
) -> bool:
	if (
		absf(color.r - sample.r) > tolerance
		or absf(color.g - sample.g) > tolerance
		or absf(color.b - sample.b) > tolerance
	):
		return false
	return not include_alpha or absf(color.a - sample.a) <= tolerance


func _find_seed_polygon(
	polygons: Array[PackedVector2Array],
	seed_point: Vector2
) -> PackedVector2Array:
	for polygon in polygons:
		if Geometry2D.is_point_in_polygon(seed_point, polygon):
			return polygon

	var largest := PackedVector2Array()
	var largest_area := 0.0
	for polygon in polygons:
		var area := absf(_signed_area(polygon))
		if area > largest_area:
			largest_area = area
			largest = polygon
	return largest


func _signed_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index in polygon.size():
		var next_index := (index + 1) % polygon.size()
		area += (
			polygon[index].x * polygon[next_index].y
			- polygon[next_index].x * polygon[index].y
		)
	return area * 0.5


func _create_polygon() -> void:
	if not is_instance_valid(_source_sprite) or _trace.size() < 3:
		_set_error("Choose a source and trace a region first.")
		return
	if not _source_sprite.is_inside_tree():
		_set_error("The source Sprite2D is no longer in the edited scene.")
		return

	var edited_root := _editor_interface.get_edited_scene_root()
	if edited_root == null:
		_set_error("Open an editable scene before creating a polygon.")
		return

	var polygon_node := Polygon2D.new()
	var requested_name := _polygon_name_edit.text.strip_edges()
	polygon_node.name = requested_name if not requested_name.is_empty() else "TracedRegion"
	polygon_node.polygon = _trace_to_sprite_local(_trace, _source_sprite)
	polygon_node.color = _sample_swatch.color

	_undo_redo.create_action("Create raster region Polygon2D")
	_undo_redo.add_do_method(_source_sprite, "add_child", polygon_node, true)
	_undo_redo.add_do_method(polygon_node, "set_owner", edited_root)
	_undo_redo.add_do_method(_editor_interface.get_selection(), "clear")
	_undo_redo.add_do_method(_editor_interface.get_selection(), "add_node", polygon_node)
	_undo_redo.add_undo_method(_source_sprite, "remove_child", polygon_node)
	_undo_redo.add_do_reference(polygon_node)
	_undo_redo.commit_action()
	_status_label.text = "Created %s with %d vertices." % [
		polygon_node.name,
		polygon_node.polygon.size()
	]


func _trace_to_sprite_local(
	image_points: PackedVector2Array,
	sprite: Sprite2D
) -> PackedVector2Array:
	var image_size := Vector2(_source_image.get_size())
	var origin := sprite.offset
	if sprite.centered:
		origin -= image_size * 0.5

	var result := PackedVector2Array()
	for image_point in image_points:
		var point := image_point
		if sprite.flip_h:
			point.x = image_size.x - point.x
		if sprite.flip_v:
			point.y = image_size.y - point.y
		result.append(origin + point)
	return result


func _set_error(message: String) -> void:
	_status_label.text = message
	_create_button.disabled = true
