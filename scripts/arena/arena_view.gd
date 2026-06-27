extends Node2D
class_name ArenaView

@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var grid_size: float = 60.0


func _draw() -> void:
	draw_rect(arena_bounds, Color(0.07, 0.08, 0.09), true)
	draw_rect(arena_bounds, Color(0.52, 0.58, 0.62), false, 3.0)
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
