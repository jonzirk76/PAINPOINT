extends Control
class_name WallOcclusionMask

var wall_rects: Array[Rect2] = []
var canvas_transform: Transform2D = Transform2D.IDENTITY


func configure(rects: Array[Rect2]) -> void:
	wall_rects = rects.duplicate()
	queue_redraw()


func update_canvas_transform(next_transform: Transform2D) -> void:
	if canvas_transform == next_transform:
		return
	canvas_transform = next_transform
	queue_redraw()


func _draw() -> void:
	for rect in wall_rects:
		var points := PackedVector2Array([
			canvas_transform * rect.position,
			canvas_transform * Vector2(rect.end.x, rect.position.y),
			canvas_transform * rect.end,
			canvas_transform * Vector2(rect.position.x, rect.end.y)
		])
		draw_colored_polygon(points, Color.WHITE)
