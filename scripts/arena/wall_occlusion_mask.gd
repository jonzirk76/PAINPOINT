extends Control
class_name WallOcclusionMask

const MASK_SEAM_OVERLAP: float = 1.0

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
		var seam_safe_rect: Rect2 = rect.grow(MASK_SEAM_OVERLAP)
		var points := PackedVector2Array([
			canvas_transform * seam_safe_rect.position,
			canvas_transform * Vector2(seam_safe_rect.end.x, seam_safe_rect.position.y),
			canvas_transform * seam_safe_rect.end,
			canvas_transform * Vector2(seam_safe_rect.position.x, seam_safe_rect.end.y)
		])
		draw_colored_polygon(points, Color.WHITE)
