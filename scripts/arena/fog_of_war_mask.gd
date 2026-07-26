extends Control
class_name FogOfWarMask

var fog_rects: Array[Rect2] = []
var canvas_transform: Transform2D = Transform2D.IDENTITY


func configure(rects: Array[Rect2]) -> void:
	fog_rects = rects.duplicate()
	queue_redraw()


func update_canvas_transform(next_transform: Transform2D) -> void:
	if canvas_transform == next_transform:
		return
	canvas_transform = next_transform
	queue_redraw()


func _draw() -> void:
	for rect in fog_rects:
		var grown_rect := rect.grow(4.0)
		var points := PackedVector2Array([
			canvas_transform * grown_rect.position,
			canvas_transform * Vector2(grown_rect.end.x, grown_rect.position.y),
			canvas_transform * grown_rect.end,
			canvas_transform * Vector2(grown_rect.position.x, grown_rect.end.y)
		])
		draw_colored_polygon(points, Color.BLACK)
