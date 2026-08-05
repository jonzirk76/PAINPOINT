@tool
extends VBoxContainer

const SessionModel := preload("res://addons/raster_region_polygon/trace_session_model.gd")
const OperationController := preload("res://addons/raster_region_polygon/trace_operation_controller.gd")
const OperationPlan := preload("res://addons/raster_region_polygon/trace_operation_plan.gd")
const LimitMask := preload("res://addons/raster_region_polygon/trace_limit_mask.gd")
const InPlacePartEditController := preload(
	"res://addons/raster_region_polygon/in_place_part_edit_controller.gd"
)
const TRACE_METADATA := &"raster_region_trace"
const PREVIEW_HEIGHT_SETTING := "raster_region_polygon/preview_height"


class RegionPreview:
	extends Control

	signal image_point_selected(point: Vector2i)
	signal zoom_changed(percent: int)
	signal limit_polygon_changed(points: PackedVector2Array)
	signal limit_drawing_finished
	signal edit_vertex_selected(index: int, additive: bool)
	signal edit_box_selected(rect: Rect2, additive: bool)
	signal edit_vertices_moved(image_delta: Vector2)

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
	var vertex_edit_enabled := false
	var edit_vertices := PackedVector2Array()
	var edit_selected := PackedInt32Array()
	var edit_pieces: Array[PackedInt32Array] = []
	var edit_drag_start := Vector2.ZERO
	var edit_drag_end := Vector2.ZERO
	var edit_dragging_box := false
	var edit_dragging_vertices := false
	var edit_additive := false

	func _ready() -> void:
		custom_minimum_size = Vector2(260.0, 400.0)
		size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
		vertex_edit_enabled = false
		selected_point = Vector2i(-1, -1)
		fit_view()
		queue_redraw()

	func set_trace(points: Array[PackedVector2Array], seed: Vector2i) -> void:
		polygons = points
		selected_point = seed
		queue_redraw()

	func set_vertex_edit(
		enabled: bool,
		vertices: PackedVector2Array = PackedVector2Array(),
		selected: PackedInt32Array = PackedInt32Array(),
		pieces: Array[PackedInt32Array] = []
	) -> void:
		vertex_edit_enabled = enabled
		edit_vertices = vertices.duplicate()
		edit_selected = selected.duplicate()
		edit_pieces = pieces.duplicate(true)
		edit_dragging_box = false
		edit_dragging_vertices = false
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
		if vertex_edit_enabled and _handle_vertex_edit_input(event):
			accept_event()
			return
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
				else:
					limit_polygon = LimitMask.simplify_polygon(limit_polygon, 1.5)
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

	func _handle_vertex_edit_input(event: InputEvent) -> bool:
		if event is InputEventMouseMotion:
			if edit_dragging_box or edit_dragging_vertices:
				edit_drag_end = (event as InputEventMouseMotion).position
				queue_redraw()
				return true
			return false
		if not event is InputEventMouseButton:
			return false
		var mouse := event as InputEventMouseButton
		if mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_MIDDLE]:
			return false
		if mouse.button_index != MOUSE_BUTTON_LEFT:
			return false
		if mouse.pressed:
			edit_drag_start = mouse.position
			edit_drag_end = mouse.position
			edit_additive = mouse.shift_pressed
			var hit_index := _find_edit_vertex(mouse.position)
			edit_dragging_vertices = hit_index >= 0 and edit_selected.has(hit_index)
			if hit_index >= 0 and not edit_dragging_vertices:
				edit_vertex_selected.emit(hit_index, edit_additive)
				edit_dragging_vertices = true
			else:
				edit_dragging_box = hit_index < 0
			return true
		if edit_dragging_vertices:
			edit_dragging_vertices = false
			var image_delta := (edit_drag_end - edit_drag_start) / _image_scale()
			if image_delta.length() >= 0.5:
				edit_vertices_moved.emit(image_delta)
			return true
		if edit_dragging_box:
			edit_dragging_box = false
			var image_start := _view_to_image(edit_drag_start)
			var image_end := _view_to_image(edit_drag_end)
			edit_box_selected.emit(
				Rect2(image_start, image_end - image_start).abs(),
				edit_additive
			)
			queue_redraw()
			return true
		return false

	func _find_edit_vertex(view_position: Vector2) -> int:
		for index in edit_vertices.size():
			var vertex_view := image_rect.position + edit_vertices[index] * _image_scale()
			if vertex_view.distance_to(view_position) <= 9.0:
				return index
		return -1

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

		if not vertex_edit_enabled:
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

		if vertex_edit_enabled:
			for piece in edit_pieces:
				if piece.size() < 3:
					continue
				var live_outline := PackedVector2Array()
				for index in piece:
					if index >= 0 and index < edit_vertices.size():
						live_outline.append(
							image_rect.position + edit_vertices[index] * scale_factor
						)
				if live_outline.size() < 3:
					continue
				draw_polyline(live_outline, Color(1.0, 0.55, 0.15), 2.0, true)
				draw_line(
					live_outline[live_outline.size() - 1],
					live_outline[0],
					Color(1.0, 0.55, 0.15),
					2.0,
					true
				)
			for index in edit_vertices.size():
				var edit_point := image_rect.position + edit_vertices[index] * scale_factor
				if edit_dragging_vertices and edit_selected.has(index):
					edit_point += edit_drag_end - edit_drag_start
				var handle_color := (
					Color(1.0, 0.75, 0.15)
					if edit_selected.has(index)
					else Color(0.2, 0.9, 1.0)
				)
				draw_circle(edit_point, 6.0, handle_color)
				draw_circle(edit_point, 3.5, Color(0.08, 0.08, 0.1))
			if edit_dragging_box:
				var selection_rect := Rect2(
					edit_drag_start,
					edit_drag_end - edit_drag_start
				).abs()
				draw_rect(selection_rect, Color(0.2, 0.7, 1.0, 0.14), true)
				draw_rect(selection_rect, Color(0.2, 0.7, 1.0), false, 1.5)

		if selected_point.x >= 0 and not vertex_edit_enabled:
			var marker := (
				image_rect.position
				+ (Vector2(selected_point) + Vector2(0.5, 0.5)) * scale_factor
			)
			draw_circle(marker, 4.0, Color.WHITE)
			draw_circle(marker, 2.0, Color(0.95, 0.25, 0.25))

var _editor_interface: EditorInterface
var _undo_redo: EditorUndoRedoManager
var _model: RefCounted = SessionModel.new()
var _controller: RefCounted = OperationController.new()
var _part_edit_controller: RefCounted = InPlacePartEditController.new()
var _viewport_edit_tool: RefCounted
var _pending_plan: RefCounted
var _pending_part_edit_plan: RefCounted
var _trace_pieces: Array[PackedVector2Array] = []
var _syncing_controls := false
var _part_preview_sync_elapsed := 0.0

var _preview
var _zoom_label: Label
var _preview_height_spin: SpinBox
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
var _part_edit_status: Label
var _begin_part_edit_button: Button
var _apply_part_edit_button: Button
var _cancel_part_edit_button: Button


func initialize(
	editor_interface: EditorInterface,
	undo_redo: EditorUndoRedoManager,
	viewport_edit_tool: RefCounted
) -> void:
	_editor_interface = editor_interface
	_undo_redo = undo_redo
	_controller.initialize(editor_interface, undo_redo)
	_part_edit_controller.initialize(editor_interface)
	_viewport_edit_tool = viewport_edit_tool


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

	var vertex_edit_controls := HBoxContainer.new()
	var vertex_edit_button := Button.new()
	vertex_edit_button.text = "Edit Vertices"
	vertex_edit_button.tooltip_text = "Box-select and move vertices of a plugin-generated Polygon2D."
	vertex_edit_button.pressed.connect(_begin_vertex_edit)
	vertex_edit_controls.add_child(vertex_edit_button)
	var delete_vertices_button := Button.new()
	delete_vertices_button.text = "Delete Selected"
	delete_vertices_button.tooltip_text = "Delete the selected vertices as one validated undoable edit."
	delete_vertices_button.pressed.connect(_delete_selected_vertices)
	vertex_edit_controls.add_child(delete_vertices_button)
	var stop_vertex_edit_button := Button.new()
	stop_vertex_edit_button.text = "Stop"
	stop_vertex_edit_button.pressed.connect(_stop_vertex_edit)
	vertex_edit_controls.add_child(stop_vertex_edit_button)
	add_child(vertex_edit_controls)

	var part_separator := HSeparator.new()
	add_child(part_separator)
	var part_heading := Label.new()
	part_heading.text = "PackedScene part editing"
	part_heading.tooltip_text = (
		"Edit an instantiated Polygon2D part in assembly context while keeping "
		+ "its governing PackedScene canonical."
	)
	add_child(part_heading)
	_begin_part_edit_button = Button.new()
	_begin_part_edit_button.text = "Edit Selected Part in Place"
	_begin_part_edit_button.tooltip_text = (
		"Open the selected instance's governing scene with a non-persistent, "
		+ "dimmed copy of the surrounding assembly."
	)
	_begin_part_edit_button.pressed.connect(_begin_in_place_part_edit)
	add_child(_begin_part_edit_button)
	var part_actions := HBoxContainer.new()
	_apply_part_edit_button = Button.new()
	_apply_part_edit_button.text = "Apply to Source"
	_apply_part_edit_button.disabled = true
	_apply_part_edit_button.tooltip_text = (
		"Save the governing part scene and return to the assembly."
	)
	_apply_part_edit_button.pressed.connect(_apply_in_place_part_edit)
	part_actions.add_child(_apply_part_edit_button)
	_cancel_part_edit_button = Button.new()
	_cancel_part_edit_button.text = "Cancel"
	_cancel_part_edit_button.disabled = true
	_cancel_part_edit_button.tooltip_text = (
		"Discard this session's source edits and return to the unchanged assembly."
	)
	_cancel_part_edit_button.pressed.connect(_cancel_in_place_part_edit)
	part_actions.add_child(_cancel_part_edit_button)
	add_child(part_actions)
	_part_edit_status = Label.new()
	_part_edit_status.text = "Select a node inside an instantiated 2D part."
	_part_edit_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_part_edit_status.custom_minimum_size.y = 42.0
	add_child(_part_edit_status)

	var trace_separator := HSeparator.new()
	add_child(trace_separator)

	_source_label = Label.new()
	_source_label.text = "Source: none"
	_source_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_source_label.tooltip_text = "The Sprite2D currently used as the image and output parent."
	add_child(_source_label)

	_preview = RegionPreview.new()
	_preview.image_point_selected.connect(_on_image_point_selected)
	_preview.edit_vertex_selected.connect(_on_edit_vertex_selected)
	_preview.edit_box_selected.connect(_on_edit_box_selected)
	_preview.edit_vertices_moved.connect(_on_edit_vertices_moved)
	add_child(_preview)
	var editor_settings := _editor_interface.get_editor_settings()
	if editor_settings.has_setting(PREVIEW_HEIGHT_SETTING):
		_preview.custom_minimum_size.y = clampf(
			float(editor_settings.get_setting(PREVIEW_HEIGHT_SETTING)),
			220.0,
			900.0
		)

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
	_preview_height_spin = SpinBox.new()
	_preview_height_spin.min_value = 220.0
	_preview_height_spin.max_value = 900.0
	_preview_height_spin.step = 20.0
	_preview_height_spin.value = _preview.custom_minimum_size.y
	_preview_height_spin.suffix = " px high"
	_preview_height_spin.tooltip_text = "Adjust and remember the dock preview height."
	_preview_height_spin.value_changed.connect(_on_preview_height_changed)
	zoom_controls.add_child(_preview_height_spin)
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
	_status_label.custom_minimum_size.y = 48.0
	_status_label.max_lines_visible = 3
	_status_label.clip_text = true
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
	_regeneration_warning.confirmed.connect(_apply_pending_regeneration)
	add_child(_regeneration_warning)

	_name_conflict_warning = AcceptDialog.new()
	_name_conflict_warning.title = "Node Name Already In Use"
	add_child(_name_conflict_warning)


func _process(delta: float) -> void:
	if not _part_edit_controller.session.active:
		return
	_part_preview_sync_elapsed += delta
	if _part_preview_sync_elapsed < 0.12:
		return
	_part_preview_sync_elapsed = 0.0
	_part_edit_controller.synchronize_preview()


func shutdown_part_editing() -> void:
	_part_edit_controller.abandon_context()


func _begin_in_place_part_edit() -> void:
	var plan: RefCounted = _part_edit_controller.propose_begin()
	if not plan.allowed:
		_set_part_edit_error(plan.reason)
		return
	_pending_part_edit_plan = plan
	_part_edit_status.text = "Opening %s…" % plan.source_path
	_editor_interface.open_scene_from_path(plan.source_path)
	call_deferred("_finish_in_place_part_edit")


func _finish_in_place_part_edit() -> void:
	if _pending_part_edit_plan == null:
		return
	var plan := _pending_part_edit_plan
	_pending_part_edit_plan = null
	var result: Dictionary = _part_edit_controller.finish_begin(plan)
	if not result.valid:
		_set_part_edit_error(result.reason)
		return
	_set_part_edit_active(true)
	_part_edit_status.text = (
		"Editing %s in assembly context.%s Use Godot's normal polygon tools, "
		+ "then Apply or Cancel; do not save the source manually during the session."
	) % [
		plan.instance_name,
		" Existing instance overrides were loaded into this draft."
		if plan.has_instance_overrides
		else "",
	]


func _apply_in_place_part_edit() -> void:
	var result: Dictionary = _part_edit_controller.apply_to_source()
	if not result.valid:
		_set_part_edit_error(result.reason)
		return
	_set_part_edit_active(false)
	_part_edit_status.text = "Saved %s; synchronizing assembly instances…" % result.source_path
	call_deferred("_finalize_in_place_part_apply", result)


func _finalize_in_place_part_apply(result: Dictionary) -> void:
	var finalized: Dictionary = _part_edit_controller.finalize_layout_after_apply(result)
	if not finalized.valid:
		_set_part_edit_error(finalized.reason)
		return
	_part_edit_status.text = (
		"Applied changes to %s and cleared redundant assembly overrides."
		% result.source_path
	)
	call_deferred("_restore_part_instance_selection", result.instance_path)


func _cancel_in_place_part_edit() -> void:
	var result: Dictionary = _part_edit_controller.cancel()
	if not result.valid:
		_set_part_edit_error(result.reason)
		return
	_set_part_edit_active(false)
	_part_edit_status.text = "Canceled the part edit; the source and assembly were not changed."
	call_deferred("_restore_part_instance_selection", result.instance_path)


func _restore_part_instance_selection(instance_path: NodePath) -> void:
	var root := _editor_interface.get_edited_scene_root()
	if root == null:
		return
	var instance := root.get_node_or_null(instance_path)
	if instance == null:
		return
	var selection := _editor_interface.get_selection()
	selection.clear()
	selection.add_node(instance)
	_editor_interface.edit_node(instance)


func _set_part_edit_active(enabled: bool) -> void:
	_begin_part_edit_button.disabled = enabled
	_apply_part_edit_button.disabled = not enabled
	_cancel_part_edit_button.disabled = not enabled
	_part_preview_sync_elapsed = 0.0


func _set_part_edit_error(message: String) -> void:
	_part_edit_status.text = message


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	return label


func _begin_vertex_edit() -> void:
	var selection := _editor_interface.get_selection().get_selected_nodes()
	if selection.size() != 1 or not selection[0] is Polygon2D:
		show_vertex_edit_status("Select exactly one plugin-generated Polygon2D.")
		return
	var polygon := selection[0] as Polygon2D
	if not polygon.get_parent() is Sprite2D:
		show_vertex_edit_status("The generated polygon must remain under its source Sprite2D.")
		return
	var source := polygon.get_parent() as Sprite2D
	if _model.draft.source_sprite != source and not _set_source_sprite(source):
		return
	if _viewport_edit_tool.begin(polygon):
		_refresh_vertex_preview()
		show_vertex_edit_status(
			"Vertex Edit mode: drag a box or selected handles inside the dock preview."
		)


func _delete_selected_vertices() -> void:
	if _viewport_edit_tool.delete_selected():
		_refresh_vertex_preview()


func _stop_vertex_edit() -> void:
	_viewport_edit_tool.end()
	_preview.set_vertex_edit(false)


func _on_edit_vertex_selected(index: int, additive: bool) -> void:
	_viewport_edit_tool.select_vertex(index, additive)
	_refresh_vertex_preview()


func _on_edit_box_selected(rect: Rect2, additive: bool) -> void:
	if _model.draft.source_image == null:
		return
	_viewport_edit_tool.select_image_rect(
		rect,
		_model.draft.source_image.get_size(),
		additive
	)
	_refresh_vertex_preview()


func _on_edit_vertices_moved(image_delta: Vector2) -> void:
	if _viewport_edit_tool.move_selected_image_delta(image_delta):
		_refresh_vertex_preview()


func _refresh_vertex_preview() -> void:
	if _model.draft.source_image == null or not _viewport_edit_tool.active:
		_preview.set_vertex_edit(false)
		return
	_preview.set_vertex_edit(
		true,
		_viewport_edit_tool.get_image_vertices(_model.draft.source_image.get_size()),
		_viewport_edit_tool.get_selected_indices(),
		_viewport_edit_tool.get_polygon_pieces()
	)


func show_vertex_edit_status(message: String) -> void:
	if is_instance_valid(_status_label):
		_status_label.text = message
	if is_instance_valid(_preview) and _viewport_edit_tool != null:
		_refresh_vertex_preview()


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

	var sprite := polygon.get_parent() as Sprite2D
	if not _set_source_sprite(sprite):
		return
	var snapshot: Dictionary = _model.load_target(polygon)
	if _model.destination_state == SessionModel.DestinationState.STALE_SELECTED:
		_set_error(str(snapshot.get("reason", "The selected trace is stale.")))
		return
	if not _model.recipe.is_ready():
		_set_error("The selected polygon has invalid trace seed metadata.")
		return
	_render_recipe_controls()
	_polygon_name_edit.text = "%sCopy" % polygon.name
	_rebuild_trace()
	_refresh_update_action()
	if _model.destination_state == SessionModel.DestinationState.REGENERATE_SELECTED:
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

	_model.use_source(sprite, image)
	_trace_pieces.clear()
	_source_label.text = "Source: %s" % sprite.name
	_source_label.tooltip_text = str(sprite.get_path())
	_sample_swatch.color = Color.TRANSPARENT
	_preview.set_source(sprite.texture, image)
	_create_button.disabled = true
	_refresh_update_action()
	_status_label.text = "Click inside a color region to trace it."
	return true


func _on_image_point_selected(point: Vector2i) -> void:
	_model.recipe.seed = point
	_rebuild_trace()


func _on_preview_zoom_changed(percent: int) -> void:
	_zoom_label.text = "%d%%" % percent


func _on_preview_height_changed(height: float) -> void:
	_preview.custom_minimum_size.y = height
	_editor_interface.get_editor_settings().set_setting(PREVIEW_HEIGHT_SETTING, height)


func _on_draw_limit_toggled(enabled: bool) -> void:
	_preview.set_limit_drawing_enabled(enabled)
	if enabled:
		_status_label.text = "Left-drag around the area where flood fill may operate."


func _on_limit_polygon_changed(points: PackedVector2Array) -> void:
	_model.recipe.limit_polygon = points
	if _model.recipe.is_ready():
		_rebuild_trace()
	elif not _model.recipe.limit_polygon.is_empty():
		_status_label.text = "Fill limit set. Click inside it to select a color region."


func _on_limit_drawing_finished() -> void:
	_draw_limit_button.set_pressed_no_signal(false)


func _clear_fill_limit() -> void:
	_model.recipe.limit_polygon.clear()
	_preview.set_limit_polygon(_model.recipe.limit_polygon)
	_draw_limit_button.set_pressed_no_signal(false)
	_preview.set_limit_drawing_enabled(false)
	if _model.recipe.is_ready():
		_rebuild_trace()
	else:
		_status_label.text = "Fill limit cleared. Click inside a color region to trace it."


func _on_trace_setting_changed(_value: Variant) -> void:
	if _syncing_controls:
		return
	_write_controls_to_recipe()
	if _model.recipe.is_ready():
		_rebuild_trace()


func _rebuild_trace() -> void:
	if _model.draft.source_image == null or not _model.recipe.is_ready():
		return
	_write_controls_to_recipe()
	var result: Dictionary = _model.rebuild()

	if not result.get("ok", false):
		_trace_pieces.clear()
		_preview.set_trace(_trace_pieces, _model.recipe.seed)
		_set_error(str(result.get("error", "Trace failed.")))
		return

	_trace_pieces = result["pieces"]
	_sample_swatch.color = result["sample"]
	_preview.set_trace(_trace_pieces, _model.recipe.seed)
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
	_write_controls_to_recipe()
	var plan: RefCounted = _controller.propose_create(
		_model,
		_polygon_name_edit.text
	)
	if not plan.allowed:
		_show_plan_rejection(plan)
		return
	var polygon_node: Polygon2D = _controller.apply_create(_model, plan)
	if polygon_node == null:
		_set_error("The create plan could not be applied to the current scene.")
		return
	_polygon_name_edit.text = "%sCopy" % polygon_node.name
	_refresh_update_action()
	_status_label.text = "Created %s with %d vertices." % [
		polygon_node.name,
		polygon_node.polygon.size()
	]


func _on_update_selected_pressed() -> void:
	_write_controls_to_recipe()
	var previous_state: int = _model.destination_state
	var plan: RefCounted = _controller.propose_update(_model)
	_refresh_update_action()
	if not plan.allowed:
		_show_plan_rejection(plan)
		return
	if (
		plan.kind == OperationPlan.Kind.REGENERATE
		and previous_state != SessionModel.DestinationState.REGENERATE_SELECTED
	):
		_status_label.text = (
			"Manual edits were detected. Review and press Regenerate Selected to replace them."
		)
		return
	if plan.requires_confirmation:
		_pending_plan = plan
		_regeneration_warning.popup_centered()
		return
	_apply_update_plan(plan)


func _apply_pending_regeneration() -> void:
	if _pending_plan == null:
		return
	var plan := _pending_plan
	_pending_plan = null
	_apply_update_plan(plan)


func _apply_update_plan(plan: RefCounted) -> void:
	if not _controller.apply_update(_model, plan):
		_set_error("The scene changed before the operation could be applied. Synchronize and try again.")
		_refresh_update_action()
		return
	_refresh_update_action()
	_status_label.text = "%s %s with %d vertices." % [
		"Regenerated" if plan.kind == OperationPlan.Kind.REGENERATE else "Updated",
		_model.target.name,
		int(_model.draft.result.get("vertex_count", 0)),
	]


func _show_plan_rejection(plan: RefCounted) -> void:
	_name_conflict_warning.title = "Operation Rejected"
	_name_conflict_warning.dialog_text = plan.reason
	_name_conflict_warning.popup_centered()


func _refresh_update_action() -> void:
	if not is_instance_valid(_update_button):
		return
	_model.synchronize()
	if _model.destination_state in [
		SessionModel.DestinationState.NEW_ONLY,
		SessionModel.DestinationState.STALE_SELECTED,
	]:
		_update_button.text = "Update Selected Polygon2D"
		_update_button.tooltip_text = (
			str(_model.target_snapshot.get(
				"reason",
				"Load a generated polygon with Edit Selected Traced Polygon."
			))
		)
		_update_button.disabled = true
		return
	var manually_edited: bool = (
		_model.destination_state == SessionModel.DestinationState.REGENERATE_SELECTED
	)
	_update_button.text = (
		"Regenerate Selected Polygon2D"
		if manually_edited
		else "Update Selected Polygon2D"
	)
	_update_button.tooltip_text = (
		"Destructive: replaces manual geometry or color edits after confirmation."
		if manually_edited
		else "Updates only %s; the new-node name is ignored." % _model.target.name
	)
	_update_button.disabled = _trace_pieces.is_empty()


func _render_recipe_controls() -> void:
	_syncing_controls = true
	_tolerance_spin.value = _model.recipe.tolerance
	_epsilon_spin.value = _model.recipe.vertex_error
	_cleanup_radius_spin.value = _model.recipe.cleanup_radius
	_include_alpha_check.button_pressed = _model.recipe.include_alpha
	_preview.set_limit_polygon(_model.recipe.limit_polygon)
	_syncing_controls = false


func _write_controls_to_recipe() -> void:
	_model.recipe.tolerance = float(_tolerance_spin.value)
	_model.recipe.vertex_error = float(_epsilon_spin.value)
	_model.recipe.cleanup_radius = int(_cleanup_radius_spin.value)
	_model.recipe.include_alpha = _include_alpha_check.button_pressed


func _set_error(message: String) -> void:
	_status_label.text = message
	_create_button.disabled = true
	_update_button.disabled = true
