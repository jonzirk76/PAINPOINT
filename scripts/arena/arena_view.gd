extends Node2D
class_name ArenaView

@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var grid_size: float = 60.0
@export var arena_shape: int = 0


func configure(level_definition) -> void:
	if level_definition == null:
		return
	arena_bounds = level_definition.arena_bounds
	arena_shape = int(level_definition.arena_shape)
	queue_redraw()


func _draw() -> void:
	var polygon := _get_arena_polygon()
	draw_colored_polygon(polygon, Color(0.07, 0.08, 0.09))
	_draw_clipped_grid(polygon)
	draw_polyline(_closed_points(polygon), Color(0.52, 0.58, 0.62), 4.0, true)


func _draw_clipped_grid(polygon: PackedVector2Array) -> void:
	var left := arena_bounds.position.x
	var right := arena_bounds.position.x + arena_bounds.size.x
	var top := arena_bounds.position.y
	var bottom := arena_bounds.position.y + arena_bounds.size.y
	var grid_color := Color(0.16, 0.18, 0.2)
	var x := left
	while x <= right:
		_draw_clipped_vertical_line(x, polygon, grid_color)
		x += grid_size
	var y := top
	while y <= bottom:
		_draw_clipped_horizontal_line(y, polygon, grid_color)
		y += grid_size


func _get_arena_polygon() -> PackedVector2Array:
	return ArenaGeometry.build_polygon(arena_bounds, arena_shape)


func _draw_clipped_vertical_line(x: float, polygon: PackedVector2Array, color: Color) -> void:
	var intersections: Array[float] = []
	for index in range(polygon.size()):
		var start := polygon[index]
		var end := polygon[(index + 1) % polygon.size()]
		if abs(end.x - start.x) <= 0.001:
			continue
		if x < min(start.x, end.x) or x > max(start.x, end.x):
			continue
		var t: float = clamp((x - start.x) / (end.x - start.x), 0.0, 1.0)
		intersections.append(lerp(start.y, end.y, t))
	_draw_intersection_segments(intersections, true, x, color)


func _draw_clipped_horizontal_line(y: float, polygon: PackedVector2Array, color: Color) -> void:
	var intersections: Array[float] = []
	for index in range(polygon.size()):
		var start := polygon[index]
		var end := polygon[(index + 1) % polygon.size()]
		if abs(end.y - start.y) <= 0.001:
			continue
		if y < min(start.y, end.y) or y > max(start.y, end.y):
			continue
		var t: float = clamp((y - start.y) / (end.y - start.y), 0.0, 1.0)
		intersections.append(lerp(start.x, end.x, t))
	_draw_intersection_segments(intersections, false, y, color)


func _draw_intersection_segments(intersections: Array[float], vertical: bool, fixed_axis: float, color: Color) -> void:
	var values := _dedupe_sorted_values(intersections)
	if values.size() < 2:
		return
	for index in range(values.size() - 1):
		var start_value: float = values[index]
		var end_value: float = values[index + 1]
		var midpoint_value := (start_value + end_value) * 0.5
		var midpoint := Vector2(fixed_axis, midpoint_value) if vertical else Vector2(midpoint_value, fixed_axis)
		if not ArenaGeometry.is_point_in_polygon(midpoint, _get_arena_polygon()):
			continue
		var start_point := Vector2(fixed_axis, start_value) if vertical else Vector2(start_value, fixed_axis)
		var end_point := Vector2(fixed_axis, end_value) if vertical else Vector2(end_value, fixed_axis)
		draw_line(start_point, end_point, color, 1.0)


func _dedupe_sorted_values(values: Array[float]) -> Array[float]:
	values.sort()
	var deduped: Array[float] = []
	for value in values:
		if deduped.is_empty() or abs(value - deduped[deduped.size() - 1]) > 0.5:
			deduped.append(value)
	return deduped


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed
