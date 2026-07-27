extends Control
class_name FogOfWarMask

var fog_rects: Array[Rect2] = []
var canvas_transform: Transform2D = Transform2D.IDENTITY
var boundary_segments: Array[PackedVector2Array] = []
var boundary_color: Color = Color(0.72, 0.78, 0.82)
var boundary_width: float = 2.0
var _fog_polygons: Array[PackedVector2Array] = []


func configure(
	rects: Array[Rect2],
	next_boundary_segments: Array[PackedVector2Array] = [],
	next_boundary_color: Color = Color(0.72, 0.78, 0.82),
	next_boundary_width: float = 2.0
) -> void:
	fog_rects = rects.duplicate()
	boundary_segments = next_boundary_segments.duplicate()
	boundary_color = next_boundary_color
	boundary_width = next_boundary_width
	_fog_polygons = _build_fog_polygons(fog_rects)
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
	for segment in boundary_segments:
		if segment.size() < 2:
			continue
		_draw_dotted_horizontal(segment[0], segment[1])


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


func _draw_dotted_horizontal(start: Vector2, end: Vector2) -> void:
	var left: float = min(start.x, end.x)
	var right: float = max(start.x, end.x)
	var y: float = start.y
	var dash_length: float = 5.0
	var gap_length: float = 4.0
	var x: float = left
	var dotted_color := Color(
		boundary_color.r,
		boundary_color.g,
		boundary_color.b,
		boundary_color.a * 0.58
	)
	while x < right:
		var dash_end: float = min(x + dash_length, right)
		var dash_start_point := Vector2(x, y)
		var dash_end_point := Vector2(dash_end, y)
		if _point_is_in_fog((dash_start_point + dash_end_point) * 0.5):
			draw_line(
				canvas_transform * dash_start_point,
				canvas_transform * dash_end_point,
				dotted_color,
				max(boundary_width * 0.72, 1.0)
			)
		x += dash_length + gap_length


func _point_is_in_fog(point: Vector2) -> bool:
	for rect in fog_rects:
		if rect.grow(4.0).has_point(point):
			return true
	return false
