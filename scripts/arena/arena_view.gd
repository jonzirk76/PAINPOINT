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
	draw_polyline(_closed_points(polygon), Color(0.52, 0.58, 0.62), 4.0, true)
	var left := arena_bounds.position.x
	var right := arena_bounds.position.x + arena_bounds.size.x
	var top := arena_bounds.position.y
	var bottom := arena_bounds.position.y + arena_bounds.size.y
	var x := left
	while x <= right:
		draw_line(Vector2(x, top), Vector2(x, bottom), Color(0.16, 0.18, 0.2), 1.0)
		x += grid_size
	var y := top
	while y <= bottom:
		draw_line(Vector2(left, y), Vector2(right, y), Color(0.16, 0.18, 0.2), 1.0)
		y += grid_size


func _get_arena_polygon() -> PackedVector2Array:
	var center := arena_bounds.get_center()
	var half := arena_bounds.size * 0.5
	match arena_shape:
		1:
			return PackedVector2Array([
				center + Vector2(0.0, -half.y),
				center + Vector2(half.x, 0.0),
				center + Vector2(0.0, half.y),
				center + Vector2(-half.x, 0.0)
			])
		2:
			return PackedVector2Array([
				center + Vector2(-half.x * 0.52, -half.y),
				center + Vector2(half.x * 0.52, -half.y),
				center + Vector2(half.x, 0.0),
				center + Vector2(half.x * 0.52, half.y),
				center + Vector2(-half.x * 0.52, half.y),
				center + Vector2(-half.x, 0.0)
			])
		3:
			var arm_x := half.x * 0.34
			var arm_y := half.y * 0.34
			return PackedVector2Array([
				center + Vector2(-arm_x, -half.y),
				center + Vector2(arm_x, -half.y),
				center + Vector2(arm_x, -arm_y),
				center + Vector2(half.x, -arm_y),
				center + Vector2(half.x, arm_y),
				center + Vector2(arm_x, arm_y),
				center + Vector2(arm_x, half.y),
				center + Vector2(-arm_x, half.y),
				center + Vector2(-arm_x, arm_y),
				center + Vector2(-half.x, arm_y),
				center + Vector2(-half.x, -arm_y),
				center + Vector2(-arm_x, -arm_y)
			])
	return PackedVector2Array([
		arena_bounds.position,
		arena_bounds.position + Vector2(arena_bounds.size.x, 0.0),
		arena_bounds.position + arena_bounds.size,
		arena_bounds.position + Vector2(0.0, arena_bounds.size.y)
	])


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed
