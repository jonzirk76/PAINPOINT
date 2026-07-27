extends Control
class_name WallOcclusionMask

const MASK_UNION_OVERLAP: float = 0.5

var wall_rects: Array[Rect2] = []
var canvas_transform: Transform2D = Transform2D.IDENTITY
var _mask_polygons: Array[PackedVector2Array] = []


func configure(rects: Array[Rect2]) -> void:
	wall_rects = rects.duplicate()
	_mask_polygons = _build_mask_polygons(wall_rects)
	queue_redraw()


func update_canvas_transform(next_transform: Transform2D) -> void:
	if canvas_transform == next_transform:
		return
	canvas_transform = next_transform
	queue_redraw()


func _draw() -> void:
	for polygon in _mask_polygons:
		var transformed_polygon: PackedVector2Array = PackedVector2Array()
		transformed_polygon.resize(polygon.size())
		for index in range(polygon.size()):
			transformed_polygon[index] = canvas_transform * polygon[index]
		draw_colored_polygon(transformed_polygon, Color.WHITE)


func _build_mask_polygons(rects: Array[Rect2]) -> Array[PackedVector2Array]:
	var regions: Array[PackedVector2Array] = []
	for rect in rects:
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var pending: PackedVector2Array = _rect_to_polygon(rect.grow(MASK_UNION_OVERLAP))
		var region_index: int = 0
		while region_index < regions.size():
			var merged: Array[PackedVector2Array] = Geometry2D.merge_polygons(regions[region_index], pending)
			if merged.size() == 1:
				pending = merged[0]
				regions.remove_at(region_index)
				region_index = 0
				continue
			region_index += 1
		regions.append(pending)
	return regions


func _rect_to_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y)
	])
