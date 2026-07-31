@tool
extends VBoxContainer

const Tracer := preload("res://addons/raster_region_polygon/raster_region_tracer.gd")
const TRACE_METADATA := &"raster_region_trace"

enum DestinationState {
	NEW_ONLY,
	UPDATE_SELECTED,
	REGENERATE_SELECTED,
}


class RegionPreview:
	extends Control

	signal image_point_selected(point: Vector2i)
	signal zoom_changed(percent: int)
	signal limit_polygon_changed(points: PackedVector2Array)
	signal limit_drawing_finished

	const MIN_ZOOM := 1.0
	const MAX_ZOOM := 32.0
	const ZOOM_STEP := 1.25

	var image: Image
	var texture: Texture2D
	var polygons: Array[PackedVector2Array] = []
	var selected_point := Vector2i(-1, -1)
	var image_rect := Rect2()
	var zoom := 1.0
	var view_center := Vector2.ZERO
	var is_panning := false
	var limit_polygon := PackedVector2Array()
	var limit_drawing_enabled := false
	var is_drawing_limit := false

	func _ready() -> void:
		custom_minimum_size = Vector2(260.0, 260.0)
		clip_contents = true
		mouse_default_cursor_shape = Control.CURSOR_CROSS
		resized.connect(queue_redraw)

	func set_source(source_texture: Texture2D, source_image: Image) -> void:
		texture = source_texture
		image = source_image
		polygons.clear()
		limit_polygon.clear()
		limit_drawing_enabled = false
		is_drawing_limit = false
		selected_point = Vector2i(-1, -1)
		fit_view()
		queue_redraw()

	func set_trace(points: Array[PackedVector2Array], seed: Vector2i) -> void:
		polygons = points
		selected_point = seed
		queue_redraw()

	func set_limit_polygon(points: PackedVector2Array) -> void:
		limit_polygon = points.duplicate()
		queue_redraw()

	func set_limit_drawing_enabled(enabled: bool) -> void:
		limit_drawing_enabled = enabled
		is_drawing_limit = false
		if enabled:
			limit_polygon.clear()
			selected_point = Vector2i(-1, -1)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion and is_drawing_limit:
			var draw_motion := event as InputEventMouseMotion
			if image_rect.has_point(draw_motion.position):
				_append_limit_point(_view_to_image(draw_motion.position))
			accept_event()
			return
		if event is InputEventMouseMotion and is_panning:
			var motion_event := event as InputEventMouseMotion
			var scale_factor := _image_scale()
			if scale_factor > 0.0:
				view_center -= motion_event.relative / scale_factor
				_clamp_view_center()
				queue_redraw()
			accept_event()
			return
		if not event is InputEventMouseButton:
			return
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton

		if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = mouse_event.pressed
			mouse_default_cursor_shape = (
				Control.CURSOR_DRAG if is_panning else Control.CURSOR_CROSS
			)
			accept_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(ZOOM_STEP, mouse_event.position)
			accept_event()
			return
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(1.0 / ZOOM_STEP, mouse_event.position)
			accept_event()
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if limit_drawing_enabled:
			if mouse_event.pressed and image_rect.has_point(mouse_event.position):
				is_drawing_limit = true
				limit_polygon.clear()
				_append_limit_point(_view_to_image(mouse_event.position))
			elif not mouse_event.pressed and is_drawing_limit:
				is_drawing_limit = false
				limit_drawing_enabled = false
				if limit_polygon.size() < 3:
					limit_polygon.clear()
				limit_polygon_changed.emit(limit_polygon.duplicate())
				limit_drawing_finished.emit()
				queue_redraw()
			accept_event()
			return
		if not mouse_event.pressed:
			return
		if image == null or not image_rect.has_point(mouse_event.position):
			return

		var image_position := _view_to_image(mouse_event.position)
		var point := Vector2i(
			clampi(int(image_position.x), 0, image.get_width() - 1),
			clampi(int(image_position.y), 0, image.get_height() - 1)
		)
		image_point_selected.emit(point)

	func _view_to_image(view_position: Vector2) -> Vector2:
		return (view_position - image_rect.position) / _image_scale()

	func _append_limit_point(image_position: Vector2) -> void:
		var clamped := Vector2(
			clampf(image_position.x, 0.0, float(image.get_width())),
			clampf(image_position.y, 0.0, float(image.get_height()))
		)
		if (
			limit_polygon.is_empty()
			or limit_polygon[limit_polygon.size() - 1].distance_to(clamped) >= 1.5
		):
			limit_polygon.append(clamped)
			queue_redraw()

	func zoom_in() -> void:
		_zoom_at(ZOOM_STEP, size * 0.5)

	func zoom_out() -> void:
		_zoom_at(1.0 / ZOOM_STEP, size * 0.5)

	func fit_view() -> void:
		zoom = MIN_ZOOM
		view_center = (
			Vector2(image.get_size()) * 0.5 if image != null else Vector2.ZERO
		)
		zoom_changed.emit(roundi(zoom * 100.0))
		queue_redraw()

	func _zoom_at(multiplier: float, focus: Vector2) -> void:
		if image == null:
			return
		var old_scale := _image_scale()
		var image_under_cursor := view_center + (focus - size * 0.5) / old_scale
		zoom = clampf(zoom * multiplier, MIN_ZOOM, MAX_ZOOM)
		var new_scale := _image_scale()
		view_center = image_under_cursor - (focus - size * 0.5) / new_scale
		_clamp_view_center()
		zoom_changed.emit(roundi(zoom * 100.0))
		queue_redraw()

	func _fit_scale() -> float:
		if image == null or image.is_empty():
			return 1.0
		var image_size := Vector2(image.get_size())
		var available := Vector2(maxf(size.x - 12.0, 1.0), maxf(size.y - 12.0, 1.0))
		return minf(available.x / image_size.x, available.y / image_size.y)

	func _image_scale() -> float:
		return _fit_scale() * zoom

	func _clamp_view_center() -> void:
		if image == null:
			return
		var image_size := Vector2(image.get_size())
		var half_visible := size * 0.5 / _image_scale()
		for axis in 2:
			if half_visible[axis] * 2.0 >= image_size[axis]:
				view_center[axis] = image_size[axis] * 0.5
			else:
				view_center[axis] = clampf(
					view_center[axis],
					half_visible[axis],
					image_size[axis] - half_visible[axis]
				)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.11), true)
		if texture == null or image == null:
			image_rect = Rect2()
			return

		var image_size := Vector2(image.get_size())
		var scale_factor := _image_scale()
		var draw_size := image_size * scale_factor
		image_rect = Rect2(size * 0.5 - view_center * scale_factor, draw_size)
		draw_texture_rect(texture, image_rect, false)

		if limit_polygon.size() >= 2:
			var limit_preview := PackedVector2Array()
			for point in limit_polygon:
				limit_preview.append(image_rect.position + point * scale_factor)
			if limit_preview.size() >= 3 and not is_drawing_limit:
				draw_colored_polygon(limit_preview, Color(0.15, 0.55, 1.0, 0.16))
			draw_polyline(limit_preview, Color(0.2, 0.7, 1.0), 2.0, true)
			if not is_drawing_limit:
				draw_line(
					limit_preview[limit_preview.size() - 1],
					limit_preview[0],
					Color(0.2, 0.7, 1.0),
					2.0,
					true
				)

		for polygon in polygons:
			if polygon.size() < 3:
				continue
			var preview_points := PackedVector2Array()
			for point in polygon:
				preview_points.append(image_rect.position + point * scale_factor)
			draw_polyline(preview_points, Color(0.1, 1.0, 0.65), 2.0, true)
			draw_line(
				preview_points[preview_points.size() - 1],
				preview_points[0],
				Color(0.1, 1.0, 0.65),
				2.0,
				true
			)

		if selected_point.x >= 0:
			var marker := (
				image_rect.position
				+ (Vector2(selected_point) + Vector2(0.5, 0.5)) * scale_factor
			)
			draw_circle(marker, 4.0, Color.WHITE)
			draw_circle(marker, 2.0, Color(0.95, 0.25, 0.25))

var _editor_interface: EditorInterface
var _undo_redo: EditorUndoRedoManager
var _source_sprite: Sprite2D
var _source_image: Image
var _editing_polygon: Polygon2D
var _seed := Vector2i(-1, -1)
var _trace_pieces: Array[PackedVector2Array] = []
var _limit_polygon: PackedVector2Array = PackedVector2Array()
var _baseline_polygon := PackedVector2Array()
var _baseline_polygons: Array[PackedInt32Array] = []
var _baseline_color := Color.TRANSPARENT
var _destination_state := DestinationState.NEW_ONLY

var _preview
var _zoom_label: Label
var _draw_limit_button: Button
var _source_label: Label
var _tolerance_spin: SpinBox
var _epsilon_spin: SpinBox
var _cleanup_radius_spin: SpinBox
var _include_alpha_check: CheckBox
var _polygon_name_edit: LineEdit
var _sample_swatch: ColorRect
var _status_label: Label
var _create_button: Button
var _update_button: Button
var _regeneration_warning: ConfirmationDialog
var _name_conflict_warning: AcceptDialog


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

	var edit_trace_button := Button.new()
	edit_trace_button.text = "Edit Selected Traced Polygon"
	edit_trace_button.pressed.connect(_edit_selected_trace)
	add_child(edit_trace_button)

	_source_label = Label.new()
	_source_label.text = "Source: none"
	_source_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_source_label.tooltip_text = "The Sprite2D currently used as the image and output parent."
	add_child(_source_label)

	_preview = RegionPreview.new()
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.image_point_selected.connect(_on_image_point_selected)
	add_child(_preview)

	var zoom_controls := HBoxContainer.new()
	var zoom_out_button := Button.new()
	zoom_out_button.text = "−"
	zoom_out_button.tooltip_text = "Zoom out (mouse wheel down)."
	zoom_out_button.pressed.connect(_preview.zoom_out)
	zoom_controls.add_child(zoom_out_button)
	var zoom_in_button := Button.new()
	zoom_in_button.text = "+"
	zoom_in_button.tooltip_text = "Zoom in (mouse wheel up)."
	zoom_in_button.pressed.connect(_preview.zoom_in)
	zoom_controls.add_child(zoom_in_button)
	var fit_button := Button.new()
	fit_button.text = "Fit"
	fit_button.tooltip_text = "Fit the complete source image in the preview."
	fit_button.pressed.connect(_preview.fit_view)
	zoom_controls.add_child(fit_button)
	_zoom_label = Label.new()
	_zoom_label.text = "100%"
	_zoom_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	zoom_controls.add_child(_zoom_label)
	_preview.zoom_changed.connect(_on_preview_zoom_changed)
	add_child(zoom_controls)

	var limit_controls := HBoxContainer.new()
	_draw_limit_button = Button.new()
	_draw_limit_button.text = "Draw Fill Limit"
	_draw_limit_button.toggle_mode = true
	_draw_limit_button.tooltip_text = (
		"Left-drag a lasso that constrains where flood fill may travel."
	)
	_draw_limit_button.toggled.connect(_on_draw_limit_toggled)
	limit_controls.add_child(_draw_limit_button)
	var clear_limit_button := Button.new()
	clear_limit_button.text = "Clear Limit"
	clear_limit_button.pressed.connect(_clear_fill_limit)
	limit_controls.add_child(clear_limit_button)
	_preview.limit_polygon_changed.connect(_on_limit_polygon_changed)
	_preview.limit_drawing_finished.connect(_on_limit_drawing_finished)
	add_child(limit_controls)

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

	settings.add_child(_make_label("Cleanup radius"))
	_cleanup_radius_spin = SpinBox.new()
	_cleanup_radius_spin.min_value = 0.0
	_cleanup_radius_spin.max_value = 8.0
	_cleanup_radius_spin.step = 1.0
	_cleanup_radius_spin.value = 0.0
	_cleanup_radius_spin.suffix = " px"
	_cleanup_radius_spin.tooltip_text = (
		"Closes narrow interruptions before tracing. Use small values to bridge "
		+ "hair strands or slivers without erasing intentional detail."
	)
	_cleanup_radius_spin.value_changed.connect(_on_trace_setting_changed)
	settings.add_child(_cleanup_radius_spin)

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

	settings.add_child(_make_label("New node name"))
	_polygon_name_edit = LineEdit.new()
	_polygon_name_edit.text = "TracedRegion"
	_polygon_name_edit.placeholder_text = "TracedRegion"
	_polygon_name_edit.tooltip_text = (
		"Names only a newly created trace. Updating always targets the selected trace."
	)
	settings.add_child(_polygon_name_edit)

	_status_label = Label.new()
	_status_label.text = "Click inside a color region to trace it."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status_label)

	_create_button = Button.new()
	_create_button.text = "Create New Polygon2D"
	_create_button.disabled = true
	_create_button.pressed.connect(_create_new_polygon)
	add_child(_create_button)

	_update_button = Button.new()
	_update_button.text = "Update Selected Polygon2D"
	_update_button.disabled = true
	_update_button.tooltip_text = "Load a generated polygon with Edit Selected Traced Polygon."
	_update_button.pressed.connect(_on_update_selected_pressed)
	add_child(_update_button)

	_regeneration_warning = ConfirmationDialog.new()
	_regeneration_warning.title = "Replace Manual Polygon Edits?"
	_regeneration_warning.dialog_text = (
		"This Polygon2D no longer matches its generated trace. Updating it will "
		+ "replace manual geometry or color edits with regenerated values."
	)
	_regeneration_warning.ok_button_text = "Regenerate Anyway"
	_regeneration_warning.confirmed.connect(_update_selected_polygon)
	add_child(_regeneration_warning)

	_name_conflict_warning = AcceptDialog.new()
	_name_conflict_warning.title = "Node Name Already In Use"
	add_child(_name_conflict_warning)


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

	_editing_polygon = null
	_refresh_update_action()
	_set_source_sprite(sprite)


func _edit_selected_trace() -> void:
	var selection := _editor_interface.get_selection().get_selected_nodes()
	if selection.size() != 1 or not selection[0] is Polygon2D:
		_set_error("Select exactly one traced Polygon2D.")
		return

	var polygon := selection[0] as Polygon2D
	if not polygon.has_meta(TRACE_METADATA):
		_set_error("This Polygon2D has no Raster Region trace metadata.")
		return
	if not polygon.get_parent() is Sprite2D:
		_set_error("The traced Polygon2D must remain a child of its source Sprite2D.")
		return

	var metadata: Dictionary = polygon.get_meta(TRACE_METADATA)
	var sprite := polygon.get_parent() as Sprite2D
	if not _set_source_sprite(sprite):
		return

	_editing_polygon = polygon
	var stored_seed: Variant = metadata.get("seed", Vector2i(-1, -1))
	if stored_seed is Vector2i:
		_seed = stored_seed
	elif stored_seed is Vector2:
		_seed = Vector2i(stored_seed)
	else:
		_set_error("The selected polygon has invalid trace seed metadata.")
		return
	_limit_polygon = _read_limit_polygon(metadata.get("limit_polygon", PackedVector2Array()))
	_preview.set_limit_polygon(_limit_polygon)
	_tolerance_spin.value = float(metadata.get("tolerance", 0.08))
	_epsilon_spin.value = float(metadata.get("vertex_error", 1.5))
	_cleanup_radius_spin.value = int(metadata.get("cleanup_radius", 0))
	_include_alpha_check.button_pressed = bool(metadata.get("include_alpha", true))
	_polygon_name_edit.text = "%sCopy" % polygon.name
	_rebuild_trace()
	if not _capture_regenerated_baseline_for(polygon):
		return
	_refresh_update_action()
	if _editing_polygon_differs_from_baseline():
		_status_label.text += " Manual edits detected; use Regenerate Selected to replace them."


func _set_source_sprite(sprite: Sprite2D) -> bool:
	if sprite.texture == null:
		_set_error("The selected Sprite2D has no texture.")
		return false
	if sprite.region_enabled:
		_set_error("Region-enabled Sprite2D textures are not supported in this first version.")
		return false

	var image := sprite.texture.get_image()
	if image == null or image.is_empty():
		_set_error("Godot could not read image data from this texture.")
		return false

	_source_sprite = sprite
	_source_image = image
	_seed = Vector2i(-1, -1)
	_trace_pieces.clear()
	_limit_polygon.clear()
	_clear_regenerated_baseline()
	_source_label.text = "Source: %s" % sprite.name
	_source_label.tooltip_text = str(sprite.get_path())
	_sample_swatch.color = Color.TRANSPARENT
	_preview.set_source(sprite.texture, image)
	_create_button.disabled = true
	_refresh_update_action()
	_status_label.text = "Click inside a color region to trace it."
	return true


func _on_image_point_selected(point: Vector2i) -> void:
	_seed = point
	_rebuild_trace()


func _on_preview_zoom_changed(percent: int) -> void:
	_zoom_label.text = "%d%%" % percent


func _on_draw_limit_toggled(enabled: bool) -> void:
	_preview.set_limit_drawing_enabled(enabled)
	if enabled:
		_status_label.text = "Left-drag around the area where flood fill may operate."


func _on_limit_polygon_changed(points: PackedVector2Array) -> void:
	_limit_polygon = points
	if _seed.x >= 0:
		_rebuild_trace()
	elif not _limit_polygon.is_empty():
		_status_label.text = "Fill limit set. Click inside it to select a color region."


func _on_limit_drawing_finished() -> void:
	_draw_limit_button.set_pressed_no_signal(false)


func _clear_fill_limit() -> void:
	_limit_polygon.clear()
	_preview.set_limit_polygon(_limit_polygon)
	_draw_limit_button.set_pressed_no_signal(false)
	_preview.set_limit_drawing_enabled(false)
	if _seed.x >= 0:
		_rebuild_trace()
	else:
		_status_label.text = "Fill limit cleared. Click inside a color region to trace it."


func _on_trace_setting_changed(_value: Variant) -> void:
	if _seed.x >= 0:
		_rebuild_trace()


func _rebuild_trace() -> void:
	if _source_image == null or _seed.x < 0:
		return

	var result: Dictionary = Tracer.trace_region(
		_source_image,
		_seed,
		float(_tolerance_spin.value),
		float(_epsilon_spin.value),
		_include_alpha_check.button_pressed,
		int(_cleanup_radius_spin.value),
		_limit_polygon
	)

	if not result.get("ok", false):
		_trace_pieces.clear()
		_preview.set_trace(_trace_pieces, _seed)
		_set_error(str(result.get("error", "Trace failed.")))
		return

	_trace_pieces = result["pieces"]
	_sample_swatch.color = result["sample"]
	_preview.set_trace(_trace_pieces, _seed)
	_create_button.disabled = _trace_pieces.is_empty()
	_refresh_update_action()
	_status_label.text = "%d vertices in %d piece(s) from %d selected pixels.%s%s" % [
		int(result["vertex_count"]),
		int(result["piece_count"]),
		int(result["selected_pixel_count"]),
		" Contour repair used." if result["used_contour_repair"] else "",
		(
			" Cleanup changed the mask by %+d pixels."
			% int(result["cleanup_pixel_delta"])
			if int(result["cleanup_radius"]) > 0
			else ""
		),
	]


func _create_new_polygon() -> void:
	if not is_instance_valid(_source_sprite) or _trace_pieces.is_empty():
		_set_error("Choose a source and trace a region first.")
		return
	if not _source_sprite.is_inside_tree():
		_set_error("The source Sprite2D is no longer in the edited scene.")
		return

	var edited_root := _editor_interface.get_edited_scene_root()
	if edited_root == null:
		_set_error("Open an editable scene before creating a polygon.")
		return

	var requested_name := _polygon_name_edit.text.strip_edges()
	if requested_name.is_empty():
		requested_name = "TracedRegion"
	var named_node := _find_source_child_named(StringName(requested_name))
	if named_node != null:
		_show_name_conflict_warning(requested_name, named_node.has_meta(TRACE_METADATA))
		return

	var polygon_node := Polygon2D.new()
	polygon_node.name = requested_name
	var polygon_data: Dictionary = Tracer.build_polygon_data(
		_trace_pieces,
		_source_image.get_size(),
		_source_sprite.offset,
		_source_sprite.centered,
		_source_sprite.flip_h,
		_source_sprite.flip_v
	)
	polygon_node.polygon = polygon_data["vertices"]
	polygon_node.polygons = polygon_data["polygons"]
	polygon_node.color = _sample_swatch.color
	polygon_node.set_meta(TRACE_METADATA, _make_trace_metadata())

	_undo_redo.create_action("Create raster region Polygon2D")
	_undo_redo.add_do_method(_source_sprite, "add_child", polygon_node, true)
	_undo_redo.add_do_method(polygon_node, "set_owner", edited_root)
	_undo_redo.add_do_method(_editor_interface.get_selection(), "clear")
	_undo_redo.add_do_method(_editor_interface.get_selection(), "add_node", polygon_node)
	_undo_redo.add_undo_method(_source_sprite, "remove_child", polygon_node)
	_undo_redo.add_do_reference(polygon_node)
	_undo_redo.commit_action()
	_editing_polygon = polygon_node
	_capture_regenerated_baseline_for(polygon_node)
	_polygon_name_edit.text = "%sCopy" % polygon_node.name
	_refresh_update_action()
	_status_label.text = "Created %s with %d vertices." % [
		polygon_node.name,
		polygon_node.polygon.size()
	]


func _on_update_selected_pressed() -> void:
	if (
		not is_instance_valid(_editing_polygon)
		or not _editing_polygon.is_inside_tree()
	):
		_set_error("Load a generated polygon before updating it.")
		return
	var previous_state := _destination_state
	_refresh_update_action()
	if (
		_destination_state == DestinationState.REGENERATE_SELECTED
		and previous_state != DestinationState.REGENERATE_SELECTED
	):
		_status_label.text = (
			"Manual edits were detected. Review and press Regenerate Selected to replace them."
		)
		return
	if _destination_state == DestinationState.REGENERATE_SELECTED:
		_regeneration_warning.popup_centered()
		return
	_update_selected_polygon()


func _update_selected_polygon() -> void:
	if (
		not is_instance_valid(_editing_polygon)
		or not _editing_polygon.is_inside_tree()
	):
		_destination_state = DestinationState.NEW_ONLY
		_set_error("The polygon being edited no longer exists.")
		return

	var polygon_data: Dictionary = Tracer.build_polygon_data(
		_trace_pieces,
		_source_image.get_size(),
		_source_sprite.offset,
		_source_sprite.centered,
		_source_sprite.flip_h,
		_source_sprite.flip_v
	)
	var new_polygon: PackedVector2Array = polygon_data["vertices"]
	var new_polygons: Array[PackedInt32Array] = polygon_data["polygons"]
	var old_polygon := _editing_polygon.polygon
	var old_polygons := _editing_polygon.polygons
	var old_color := _editing_polygon.color
	var old_metadata: Variant = _editing_polygon.get_meta(
		TRACE_METADATA,
		{}
	)
	var new_metadata := _make_trace_metadata()

	_undo_redo.create_action("Update raster region Polygon2D")
	_undo_redo.add_do_property(_editing_polygon, "polygon", new_polygon)
	_undo_redo.add_do_property(_editing_polygon, "polygons", new_polygons)
	_undo_redo.add_do_property(_editing_polygon, "color", _sample_swatch.color)
	_undo_redo.add_do_method(
		_editing_polygon,
		"set_meta",
		TRACE_METADATA,
		new_metadata
	)
	_undo_redo.add_undo_property(_editing_polygon, "polygon", old_polygon)
	_undo_redo.add_undo_property(_editing_polygon, "polygons", old_polygons)
	_undo_redo.add_undo_property(_editing_polygon, "color", old_color)
	_undo_redo.add_undo_method(
		_editing_polygon,
		"set_meta",
		TRACE_METADATA,
		old_metadata
	)
	_undo_redo.commit_action()
	_capture_regenerated_baseline_for(_editing_polygon)
	_refresh_update_action()
	_status_label.text = "Updated %s with %d vertices." % [
		_editing_polygon.name,
		new_polygon.size()
	]


func _capture_regenerated_baseline_for(polygon: Polygon2D) -> bool:
	if (
		not is_instance_valid(polygon)
		or not is_instance_valid(_source_sprite)
		or not polygon.has_meta(TRACE_METADATA)
	):
		_clear_regenerated_baseline()
		return false
	var metadata: Dictionary = polygon.get_meta(TRACE_METADATA)
	var baseline_seed: Vector2i = metadata.get("seed", Vector2i(-1, -1))
	var baseline_result: Dictionary = Tracer.trace_region(
		_source_image,
		baseline_seed,
		float(metadata.get("tolerance", 0.08)),
		float(metadata.get("vertex_error", 1.5)),
		bool(metadata.get("include_alpha", true)),
		int(metadata.get("cleanup_radius", 0)),
		_read_limit_polygon(metadata.get("limit_polygon", PackedVector2Array()))
	)
	if not baseline_result.get("ok", false):
		_clear_regenerated_baseline()
		_set_error(
			"Could not reconstruct %s for edit detection: %s" % [
				polygon.name,
				str(baseline_result.get("error", "trace failed")),
			]
		)
		return false
	var polygon_data: Dictionary = Tracer.build_polygon_data(
		baseline_result["pieces"],
		_source_image.get_size(),
		_source_sprite.offset,
		_source_sprite.centered,
		_source_sprite.flip_h,
		_source_sprite.flip_v
	)
	_baseline_polygon = polygon_data["vertices"]
	_baseline_polygons = polygon_data["polygons"]
	_baseline_color = baseline_result["sample"]
	return true


func _find_source_child_named(requested_name: StringName) -> Node:
	for child in _source_sprite.get_children():
		if child.name == requested_name:
			return child
	return null


func _show_name_conflict_warning(
	requested_name: String,
	is_generated: bool
) -> void:
	if is_generated:
		_name_conflict_warning.dialog_text = (
			"A generated polygon named '%s' already exists under %s. Create New "
			+ "never overwrites nodes. Load that polygon explicitly and use Update "
			+ "Selected, or choose another name."
		) % [requested_name, _source_sprite.name]
	else:
		_name_conflict_warning.dialog_text = (
			"A node named '%s' already exists under %s, but it was not generated "
			+ "by Raster Region Polygon. Choose another name; the existing node "
			+ "will not be changed."
		) % [requested_name, _source_sprite.name]
	_name_conflict_warning.popup_centered()


func _refresh_update_action() -> void:
	if not is_instance_valid(_update_button):
		return
	if (
		not is_instance_valid(_editing_polygon)
		or not _editing_polygon.is_inside_tree()
	):
		_update_button.text = "Update Selected Polygon2D"
		_update_button.tooltip_text = (
			"Load a generated polygon with Edit Selected Traced Polygon."
		)
		_update_button.disabled = true
		return
	var manually_edited := _editing_polygon_differs_from_baseline()
	_destination_state = (
		DestinationState.REGENERATE_SELECTED
		if manually_edited
		else DestinationState.UPDATE_SELECTED
	)
	_update_button.text = (
		"Regenerate Selected Polygon2D"
		if manually_edited
		else "Update Selected Polygon2D"
	)
	_update_button.tooltip_text = (
		"Destructive: replaces manual geometry or color edits after confirmation."
		if manually_edited
		else "Updates only %s; the new-node name is ignored." % _editing_polygon.name
	)
	_update_button.disabled = _trace_pieces.is_empty()


func _clear_regenerated_baseline() -> void:
	_baseline_polygon.clear()
	_baseline_polygons.clear()
	_baseline_color = Color.TRANSPARENT


func _read_limit_polygon(value: Variant) -> PackedVector2Array:
	if value is PackedVector2Array:
		return value
	var points := PackedVector2Array()
	if value is Array:
		for point in value:
			if point is Vector2:
				points.append(point)
	return points


func _editing_polygon_differs_from_baseline() -> bool:
	if not is_instance_valid(_editing_polygon) or _baseline_polygon.is_empty():
		return false
	if not _packed_vector_arrays_match(
		_editing_polygon.polygon,
		_baseline_polygon
	):
		return true
	if _editing_polygon.polygons != _baseline_polygons:
		return true
	return not _editing_polygon.color.is_equal_approx(_baseline_color)


func _packed_vector_arrays_match(
	left: PackedVector2Array,
	right: PackedVector2Array
) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if not left[index].is_equal_approx(right[index]):
			return false
	return true


func _make_trace_metadata() -> Dictionary:
	return {
		"version": 3,
		"seed": _seed,
		"tolerance": float(_tolerance_spin.value),
		"vertex_error": float(_epsilon_spin.value),
		"include_alpha": _include_alpha_check.button_pressed,
		"cleanup_radius": int(_cleanup_radius_spin.value),
		"limit_polygon": _limit_polygon,
	}


func _set_error(message: String) -> void:
	_status_label.text = message
	_create_button.disabled = true
	_update_button.disabled = true
