@tool
extends Control
class_name BlockoutDungeonScalePreview

const DEFAULT_CAPTURE := preload("res://resources/characters/blockouts/back_hair_test_vector_capture.tres")
const DEFAULT_ROOM_PIECE := preload("res://resources/rooms/combat_l_room.tres")
const PLAYER_BODY_TEXTURE := preload("res://art/characters/player_body.svg")
const PLAYER_BODY_BACK_TEXTURE := preload("res://art/characters/player_body_back.svg")
const PLAYER_BODY_SIDE_TEXTURE := preload("res://art/characters/player_body_side.svg")
const SOURCE_CENTER := Vector2(64.0, 64.0)
const SOURCE_SIZE := Vector2(128.0, 128.0)
const VIEW_FRONT := "front"
const VIEW_SIDE_LEFT := "side_left"
const VIEW_SIDE_RIGHT := "side_right"
const VIEW_BACK := "back"

## Extracted blockout capture to preview at in-game scale.
@export var capture: Resource = DEFAULT_CAPTURE:
	set(value):
		capture = value
		queue_redraw()

## Dungeon room piece used as the world-scale backdrop.
@export var room_piece: Resource = DEFAULT_ROOM_PIECE:
	set(value):
		room_piece = value
		queue_redraw()

## Directional character view to draw.
@export_enum("front", "side_left", "side_right", "back") var view_direction: String = VIEW_FRONT:
	set(value):
		view_direction = value
		queue_redraw()

## Toggle this on to re-extract polygons from Back Hair Test before previewing.
@export var refresh_capture_now: bool = false:
	set(value):
		refresh_capture_now = false
		if value:
			_refresh_capture()

## Matches PlayerEntity.body_radius by default.
@export_range(8.0, 42.0, 0.5) var body_radius: float = 17.0:
	set(value):
		body_radius = value
		queue_redraw()

## Matches PlayerEntity visual_radius/body_radius multiplier by default.
@export_range(1.0, 4.0, 0.05) var visual_radius_multiplier: float = 2.35:
	set(value):
		visual_radius_multiplier = value
		queue_redraw()

## Extra blockout-only multiplier for testing target reductions.
@export_range(0.1, 1.5, 0.01) var blockout_scale_multiplier: float = 0.2:
	set(value):
		blockout_scale_multiplier = value
		queue_redraw()

## Character position inside the room in world pixels.
@export var character_world_position: Vector2 = Vector2.ZERO:
	set(value):
		character_world_position = value
		queue_redraw()

## Automatically fits the selected room into the preview control.
@export var auto_fit_room: bool = true:
	set(value):
		auto_fit_room = value
		queue_redraw()

## Manual world-to-preview zoom used when Auto Fit Room is disabled.
@export_range(0.05, 1.5, 0.01) var world_zoom: float = 0.38:
	set(value):
		world_zoom = value
		queue_redraw()

## Manual screen-space pan in pixels.
@export var screen_pan: Vector2 = Vector2.ZERO:
	set(value):
		screen_pan = value
		queue_redraw()

## Draws the current runtime player body SVG under the blockout.
@export var show_current_player_reference: bool = true:
	set(value):
		show_current_player_reference = value
		queue_redraw()

## Draws the current player collision circle.
@export var show_collision_circle: bool = true:
	set(value):
		show_collision_circle = value
		queue_redraw()

## Draws the 80-ish pixel runtime texture frame.
@export var show_runtime_texture_frame: bool = true:
	set(value):
		show_runtime_texture_frame = value
		queue_redraw()

## Draws dungeon spawner markers from the selected room piece.
@export var show_spawners: bool = true:
	set(value):
		show_spawners = value
		queue_redraw()

## Draws text labels and scale readout.
@export var show_labels: bool = true:
	set(value):
		show_labels = value
		queue_redraw()

## Draws individual blockout polygon control points.
@export var show_blockout_points: bool = false:
	set(value):
		show_blockout_points = value
		queue_redraw()

## Alpha applied to the captured blockout polygons.
@export_range(0.15, 1.0, 0.01) var blockout_alpha: float = 0.82:
	set(value):
		blockout_alpha = value
		queue_redraw()

## Comma-separated roles to draw by themselves. Empty means all roles.
@export var solo_roles: String = "":
	set(value):
		solo_roles = value
		queue_redraw()

## Comma-separated roles to hide from the preview.
@export var hidden_roles: String = "":
	set(value):
		hidden_roles = value
		queue_redraw()

var _room_bounds: Rect2 = Rect2(Vector2(-640.0, -360.0), Vector2(1280.0, 720.0))
var _wall_rects: Array[Rect2] = []
var _spawner_positions: Array[Vector2] = []
var _footprint_cells: Array[Vector2i] = []
var _current_zoom: float = 0.38


func _ready() -> void:
	custom_minimum_size = Vector2(860.0, 560.0)


func _draw() -> void:
	_update_room_cache()
	_current_zoom = _get_effective_zoom()
	_draw_room()
	_draw_scale_reference()
	_draw_blockout_character()
	if show_labels:
		_draw_scale_labels()


func _update_room_cache() -> void:
	_room_bounds = Rect2(Vector2(-640.0, -360.0), Vector2(1280.0, 720.0))
	_wall_rects.clear()
	_spawner_positions.clear()
	_footprint_cells.clear()
	if room_piece == null:
		return
	var bounds_value: Variant = room_piece.get("arena_bounds")
	if bounds_value is Rect2:
		_room_bounds = bounds_value
	var wall_value: Variant = room_piece.get("wall_rects")
	if wall_value is Array:
		for rect in wall_value:
			if rect is Rect2:
				_wall_rects.append(rect)
	var footprint_value: Variant = room_piece.get("footprint_cells")
	if footprint_value is Array:
		for cell in footprint_value:
			if cell is Vector2i:
				_footprint_cells.append(cell)
	var placements_value: Variant = room_piece.get("spawner_placements")
	if placements_value is Array:
		for placement in placements_value:
			if placement is Resource:
				var position_value: Variant = placement.get("position")
				if position_value is Vector2:
					_spawner_positions.append(position_value)
	if _footprint_cells.is_empty():
		_footprint_cells.append(Vector2i.ZERO)


func _get_effective_zoom() -> float:
	if not auto_fit_room:
		return world_zoom
	var available_size: Vector2 = size - Vector2(72.0, 92.0)
	if available_size.x <= 1.0 or available_size.y <= 1.0:
		available_size = Vector2(780.0, 468.0)
	var zoom_x: float = available_size.x / max(_room_bounds.size.x, 1.0)
	var zoom_y: float = available_size.y / max(_room_bounds.size.y, 1.0)
	return min(zoom_x, zoom_y)


func _draw_room() -> void:
	var full_rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(full_rect, Color(0.035, 0.04, 0.048, 1.0), true)
	_draw_rect_world(_room_bounds.grow(180.0), Color(0.015, 0.016, 0.02, 1.0), true)
	for cell in _footprint_cells:
		_draw_rect_world(_cell_rect(cell), Color(0.06, 0.068, 0.075, 1.0), true)
		_draw_cell_grid(_cell_rect(cell))
	for wall in _wall_rects:
		_draw_rect_world(wall, Color(0.16, 0.18, 0.2, 1.0), true)
		_draw_rect_world(wall, Color(0.38, 0.44, 0.5, 0.45), false, 1.5)
	_draw_rect_world(_room_bounds, Color(0.52, 0.58, 0.66, 0.82), false, 3.0)
	if show_spawners:
		for position in _spawner_positions:
			_draw_spawner_marker(position)


func _draw_cell_grid(cell_rect: Rect2) -> void:
	var grid_step := 80.0
	var grid_color := Color(0.12, 0.14, 0.16, 0.52)
	var x := cell_rect.position.x
	while x <= cell_rect.end.x + 0.5:
		draw_line(_world_to_screen(Vector2(x, cell_rect.position.y)), _world_to_screen(Vector2(x, cell_rect.end.y)), grid_color, 1.0)
		x += grid_step
	var y := cell_rect.position.y
	while y <= cell_rect.end.y + 0.5:
		draw_line(_world_to_screen(Vector2(cell_rect.position.x, y)), _world_to_screen(Vector2(cell_rect.end.x, y)), grid_color, 1.0)
		y += grid_step


func _draw_spawner_marker(world_position: Vector2) -> void:
	var center: Vector2 = _world_to_screen(world_position)
	var radius: float = 26.0 * _current_zoom
	draw_circle(center, radius, Color(0.7, 0.22, 0.16, 0.55))
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.55, 0.28, 0.9), 2.0)


func _draw_scale_reference() -> void:
	var center: Vector2 = _world_to_screen(character_world_position)
	var visual_radius: float = _runtime_visual_radius()
	var visual_size: Vector2 = Vector2.ONE * visual_radius * 2.0 * _current_zoom
	var visual_rect := Rect2(center - visual_size * 0.5, visual_size)
	if show_current_player_reference:
		var texture: Texture2D = _get_player_reference_texture()
		if texture != null:
			draw_texture_rect(texture, visual_rect, false, Color(1.0, 1.0, 1.0, 0.34))
	if show_runtime_texture_frame:
		draw_rect(visual_rect, Color(0.36, 0.75, 1.0, 0.82), false, 2.0)
	if show_collision_circle:
		draw_arc(center, body_radius * _current_zoom, 0.0, TAU, 40, Color(1.0, 0.95, 0.32, 0.92), 2.0)


func _draw_blockout_character() -> void:
	var shapes: Array[Resource] = _get_visible_shapes()
	for shape in shapes:
		_draw_blockout_shape(shape)


func _draw_blockout_shape(shape: Resource) -> void:
	var points_value: Variant = shape.get("points")
	if not points_value is PackedVector2Array:
		return
	var source_points: PackedVector2Array = points_value
	if source_points.size() < 3:
		return
	var shape_view: String = String(shape.get("view_direction"))
	var screen_points := PackedVector2Array()
	for source_point in source_points:
		screen_points.append(_source_to_screen(source_point, shape_view))
	var color := Color.WHITE
	var color_value: Variant = shape.get("color")
	if color_value is Color:
		color = color_value
	color.a *= blockout_alpha
	draw_colored_polygon(screen_points, color)
	var closed_points := PackedVector2Array(screen_points)
	closed_points.append(screen_points[0])
	draw_polyline(closed_points, Color(0.015, 0.015, 0.02, 0.9), max(1.0, _current_zoom * 3.0), true)
	if show_blockout_points:
		for point in screen_points:
			draw_circle(point, max(2.0, _current_zoom * 4.0), Color(0.0, 0.86, 0.78, 0.95))


func _draw_scale_labels() -> void:
	var font: Font = get_theme_default_font()
	if font == null:
		return
	var source_bounds: Rect2 = _get_blockout_source_bounds()
	var source_scale: float = _source_to_world_scale()
	var world_size: Vector2 = source_bounds.size * source_scale
	var visual_diameter: float = _runtime_visual_radius() * 2.0
	var lines := PackedStringArray([
		"Room: %s   zoom %.2f" % [_get_room_label(), _current_zoom],
		"Current player art frame: %.1f x %.1f world px   collision radius %.1f" % [visual_diameter, visual_diameter, body_radius],
		"Blockout bounds: %.1f x %.1f source units -> %.1f x %.1f world px" % [source_bounds.size.x, source_bounds.size.y, world_size.x, world_size.y],
		"Blockout scale multiplier: %.2f" % blockout_scale_multiplier
	])
	var position := Vector2(18.0, 24.0)
	for line in lines:
		draw_string(font, position, line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14.0, Color(0.88, 0.92, 0.96, 0.95))
		position.y += 18.0


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


func _get_blockout_source_bounds() -> Rect2:
	var shapes: Array[Resource] = _get_visible_shapes()
	var has_point := false
	var bounds := Rect2()
	for shape in shapes:
		var points_value: Variant = shape.get("points")
		if not points_value is PackedVector2Array:
			continue
		for source_point in points_value:
			var adjusted_point: Vector2 = _adjust_source_point_for_view(source_point, String(shape.get("view_direction")))
			if not has_point:
				bounds = Rect2(adjusted_point, Vector2.ZERO)
				has_point = true
			else:
				bounds = bounds.expand(adjusted_point)
	return bounds if has_point else Rect2(SOURCE_CENTER, Vector2.ZERO)


func _source_to_screen(source_point: Vector2, shape_view: String) -> Vector2:
	var adjusted_point: Vector2 = _adjust_source_point_for_view(source_point, shape_view)
	var local_world: Vector2 = (adjusted_point - SOURCE_CENTER) * _source_to_world_scale()
	return _world_to_screen(character_world_position + local_world)


func _adjust_source_point_for_view(source_point: Vector2, shape_view: String) -> Vector2:
	if view_direction == VIEW_SIDE_RIGHT and shape_view == VIEW_SIDE_LEFT:
		return Vector2(SOURCE_SIZE.x - source_point.x, source_point.y)
	return source_point


func _source_to_world_scale() -> float:
	return (_runtime_visual_radius() * 2.0 / SOURCE_SIZE.x) * blockout_scale_multiplier


func _runtime_visual_radius() -> float:
	return body_radius * visual_radius_multiplier


func _world_to_screen(world_point: Vector2) -> Vector2:
	var room_center: Vector2 = _room_bounds.get_center()
	return size * 0.5 + screen_pan + (world_point - room_center) * _current_zoom


func _draw_rect_world(rect: Rect2, color: Color, filled: bool, width: float = 1.0) -> void:
	var screen_rect := Rect2(_world_to_screen(rect.position), rect.size * _current_zoom)
	if filled:
		draw_rect(screen_rect, color, true)
	else:
		draw_rect(screen_rect, color, false, width)


func _cell_rect(cell: Vector2i) -> Rect2:
	var cell_size := Vector2(1280.0, 720.0)
	return Rect2(_room_bounds.position + Vector2(float(cell.x) * cell_size.x, float(cell.y) * cell_size.y), cell_size)


func _get_player_reference_texture() -> Texture2D:
	match view_direction:
		VIEW_BACK:
			return PLAYER_BODY_BACK_TEXTURE
		VIEW_SIDE_LEFT, VIEW_SIDE_RIGHT:
			return PLAYER_BODY_SIDE_TEXTURE
	return PLAYER_BODY_TEXTURE


func _get_room_label() -> String:
	if room_piece == null:
		return "none"
	var id_value: Variant = room_piece.get("id")
	if id_value != null:
		return String(id_value)
	return room_piece.resource_path.get_file().get_basename()


func _parse_role_set(value: String) -> Dictionary:
	var result: Dictionary = {}
	for raw_role in value.split(",", false):
		var role: String = String(raw_role).strip_edges()
		if not role.is_empty():
			result[role] = true
	return result


func _refresh_capture() -> void:
	if not Engine.is_editor_hint():
		return
	var runner := CharacterBlockoutExtractionRunner.new()
	capture = runner.extract_default()
	call_deferred("queue_redraw")
