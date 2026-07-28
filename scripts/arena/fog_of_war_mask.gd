extends Control
class_name FogOfWarMask

var fog_rects: Array[Rect2] = []
var canvas_transform: Transform2D = Transform2D.IDENTITY
var _fog_polygons: Array[PackedVector2Array] = []


func configure(rects: Array[Rect2]) -> void:
	fog_rects = rects.duplicate()
	_fog_polygons = _build_fog_polygons(fog_rects)
	set_meta("raw_rect_count", fog_rects.size())
	set_meta("union_polygon_count", _fog_polygons.size())
	set_meta("exact_duplicate_rect_count", _count_exact_duplicate_rects(fog_rects))
	queue_redraw()


func update_canvas_transform(next_transform: Transform2D) -> void:
	if canvas_transform == next_transform:
		return
	canvas_transform = next_transform
	queue_redraw()


func _draw() -> void:
	for polygon in _fog_polygons:
		var transformed_polygon := PackedVector2Array()
		for point in polygon:
			transformed_polygon.append(canvas_transform * point)
		draw_colored_polygon(transformed_polygon, Color.BLACK)


func _build_fog_polygons(rects: Array[Rect2]) -> Array[PackedVector2Array]:
	var regions: Array[PackedVector2Array] = []
	for rect in rects:
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		var grown_rect: Rect2 = rect.grow(4.0)
		var pending := PackedVector2Array([
			grown_rect.position,
			Vector2(grown_rect.end.x, grown_rect.position.y),
			grown_rect.end,
			Vector2(grown_rect.position.x, grown_rect.end.y)
		])
		var region_index: int = 0
		while region_index < regions.size():
			var merged: Array[PackedVector2Array] = Geometry2D.merge_polygons(
				regions[region_index],
				pending
			)
			if merged.size() == 1:
				pending = merged[0]
				regions.remove_at(region_index)
				region_index = 0
				continue
			region_index += 1
		regions.append(pending)
	return regions


func _count_exact_duplicate_rects(rects: Array[Rect2]) -> int:
	var seen: Dictionary = {}
	var duplicate_count: int = 0
	for rect in rects:
		var key := "%s:%s:%s:%s" % [
			rect.position.x,
			rect.position.y,
			rect.size.x,
			rect.size.y
		]
		if seen.has(key):
			duplicate_count += 1
		else:
			seen[key] = true
	return duplicate_count
