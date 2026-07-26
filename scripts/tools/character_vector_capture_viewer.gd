@tool
extends Control
class_name CharacterVectorCaptureViewer

const DEFAULT_CAPTURE := preload("res://resources/characters/blockouts/back_hair_test_vector_capture.tres")
const SOURCE_CENTER := Vector2(64.0, 64.0)
const SOURCE_SIZE := Vector2(128.0, 128.0)
const VIEW_FRONT := "front"
const VIEW_SIDE_LEFT := "side_left"
const VIEW_SIDE_RIGHT := "side_right"
const VIEW_BACK := "back"

## Extracted vector capture to inspect and compose.
@export var capture: Resource = DEFAULT_CAPTURE:
	set(value):
		capture = value
		queue_redraw()

## Directional view to draw from the capture.
@export_enum("front", "side_left", "side_right", "back") var view_direction: String = VIEW_FRONT:
	set(value):
		view_direction = value
		queue_redraw()

## Toggle this on to re-extract polygons from Back Hair Test into the default capture resource.
@export var refresh_capture_now: bool = false:
	set(value):
		refresh_capture_now = false
		if value:
			_refresh_capture()

## Scales the 128x128 source-space preview.
@export_range(1.0, 6.0, 0.1) var preview_scale: float = 3.0:
	set(value):
		preview_scale = value
		queue_redraw()

## Draws the 128x128 source-space frame and center guides.
@export var show_preview_guides: bool = true:
	set(value):
		show_preview_guides = value
		queue_redraw()

## Draws a neutral backdrop behind the captured polygons.
@export var show_backdrop: bool = false:
	set(value):
		show_backdrop = value
		queue_redraw()

## Backdrop color used only when Show Backdrop is enabled.
@export var backdrop_color: Color = Color(0.18, 0.18, 0.18, 1.0):
	set(value):
		backdrop_color = value
		queue_redraw()

## Draws dark outlines around captured polygons.
@export var show_shape_outlines: bool = true:
	set(value):
		show_shape_outlines = value
		queue_redraw()

## Draws control points for each captured polygon.
@export var show_points: bool = false:
	set(value):
		show_points = value
		queue_redraw()

## Draws role names at each polygon center.
@export var show_role_labels: bool = false:
	set(value):
		show_role_labels = value
		queue_redraw()

## Comma-separated roles to draw by themselves. Empty means all roles.
@export var solo_roles: String = "":
	set(value):
		solo_roles = value
		queue_redraw()

## Comma-separated roles to hide from the capture preview.
@export var hidden_roles: String = "":
	set(value):
		hidden_roles = value
		queue_redraw()

## Optional comma-separated role order override. Unlisted roles keep capture layer order after listed roles.
@export var role_draw_order: String = "":
	set(value):
		role_draw_order = value
		queue_redraw()

var _active_role_order: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(560.0, 560.0)


func _draw() -> void:
	var center: Vector2 = size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(280.0, 280.0)
	_draw_backdrop(center)
	var shapes: Array[Resource] = _get_visible_shapes()
	for shape in shapes:
		_draw_shape(shape, center)


func _draw_backdrop(center: Vector2) -> void:
	var canvas_size: Vector2 = SOURCE_SIZE * preview_scale
	var rect: Rect2 = Rect2(center - canvas_size * 0.5, canvas_size)
	if show_backdrop:
		draw_rect(rect.grow(16.0), backdrop_color, true)
	if not show_preview_guides:
		return
	draw_rect(rect, Color(0.35, 0.55, 0.82, 0.34), false, 2.0)
	draw_line(Vector2(rect.position.x, center.y), Vector2(rect.end.x, center.y), Color(0.35, 0.55, 0.82, 0.22), 1.0)
	draw_line(Vector2(center.x, rect.position.y), Vector2(center.x, rect.end.y), Color(0.35, 0.55, 0.82, 0.22), 1.0)


func _draw_shape(shape: Resource, center: Vector2) -> void:
	var source_points_value: Variant = shape.get("points")
	if not source_points_value is PackedVector2Array:
		return
	var source_points: PackedVector2Array = source_points_value
	if source_points.size() < 3:
		return
	var shape_view: String = String(shape.get("view_direction"))
	var preview_points: PackedVector2Array = PackedVector2Array()
	for source_point in source_points:
		preview_points.append(_preview_point(center, source_point, shape_view))
	var fill_color := Color.WHITE
	var fill_value: Variant = shape.get("color")
	if fill_value is Color:
		fill_color = fill_value
	draw_colored_polygon(preview_points, fill_color)
	if show_shape_outlines:
		var closed_points: PackedVector2Array = PackedVector2Array(preview_points)
		closed_points.append(preview_points[0])
		draw_polyline(closed_points, Color(0.02, 0.02, 0.025, 0.82), max(1.0, preview_scale * 1.4), true)
	if show_points:
		for point in preview_points:
			draw_circle(point, max(2.0, preview_scale * 0.9), Color(0.0, 0.86, 0.78, 0.95))
	if show_role_labels:
		_draw_role_label(shape, preview_points)


func _draw_role_label(shape: Resource, preview_points: PackedVector2Array) -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var role: String = String(shape.get("role"))
	var bounds: Rect2 = Rect2(preview_points[0], Vector2.ZERO)
	for point in preview_points:
		bounds = bounds.expand(point)
	draw_string(font, bounds.get_center(), role, HORIZONTAL_ALIGNMENT_CENTER, -1.0, 11.0, Color.WHITE)


func _get_visible_shapes() -> Array[Resource]:
	var active_capture: Resource = _get_active_capture()
	if active_capture == null or not active_capture.has_method("get_shapes_for_view"):
		return []
	var source_view: String = VIEW_SIDE_LEFT if view_direction == VIEW_SIDE_RIGHT else view_direction
	var shapes: Array[Resource] = active_capture.get_shapes_for_view(source_view)
	var solo_set: Dictionary = _parse_role_set(solo_roles)
	var hidden_set: Dictionary = _parse_role_set(hidden_roles)
	var results: Array[Resource] = []
	for shape in shapes:
		var role: String = String(shape.get("role"))
		if not solo_set.is_empty() and not solo_set.has(role):
			continue
		if hidden_set.has(role):
			continue
		results.append(shape)
	_active_role_order = _parse_role_order(role_draw_order)
	results.sort_custom(Callable(self, "_sort_shapes"))
	return results


func _get_active_capture() -> Resource:
	if _capture_has_shapes(capture):
		return capture
	if _capture_has_shapes(DEFAULT_CAPTURE):
		return DEFAULT_CAPTURE
	return capture


func _capture_has_shapes(candidate: Resource) -> bool:
	if candidate == null:
		return false
	var shapes_value: Variant = candidate.get("shapes")
	return shapes_value is Array and not shapes_value.is_empty()


func _preview_point(center: Vector2, source_point: Vector2, shape_view: String) -> Vector2:
	var adjusted_point: Vector2 = source_point
	if view_direction == VIEW_SIDE_RIGHT and shape_view == VIEW_SIDE_LEFT:
		adjusted_point.x = SOURCE_SIZE.x - adjusted_point.x
	return center + (adjusted_point - SOURCE_CENTER) * preview_scale


func _sort_shapes(left: Resource, right: Resource) -> bool:
	var left_role: String = String(left.get("role"))
	var right_role: String = String(right.get("role"))
	var left_index: int = int(_active_role_order.get(left_role, 100000))
	var right_index: int = int(_active_role_order.get(right_role, 100000))
	if left_index != right_index:
		return left_index < right_index
	var left_layer: int = int(left.get("layer_order"))
	var right_layer: int = int(right.get("layer_order"))
	if left_layer != right_layer:
		return left_layer < right_layer
	return left_role.naturalnocasecmp_to(right_role) < 0


func _parse_role_set(value: String) -> Dictionary:
	var result: Dictionary = {}
	for raw_role in value.split(",", false):
		var role: String = String(raw_role).strip_edges()
		if not role.is_empty():
			result[role] = true
	return result


func _parse_role_order(value: String) -> Dictionary:
	var result: Dictionary = {}
	var index: int = 0
	for raw_role in value.split(",", false):
		var role: String = String(raw_role).strip_edges()
		if role.is_empty():
			continue
		result[role] = index
		index += 1
	return result


func _refresh_capture() -> void:
	if not Engine.is_editor_hint():
		return
	var runner := CharacterBlockoutExtractionRunner.new()
	capture = runner.extract_default()
	call_deferred("queue_redraw")
