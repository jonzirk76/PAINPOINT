@tool
extends RefCounted

var bitmap: BitMap
var bounds := Rect2i()


static func build(
	image_size: Vector2i,
	polygon: PackedVector2Array
) -> RefCounted:
	var result: RefCounted = load(
		"res://addons/raster_region_polygon/trace_limit_mask.gd"
	).new()
	if polygon.size() < 3:
		return result
	result.bounds = _clipped_bounds(image_size, polygon)
	if result.bounds.has_area():
		result.bitmap = _rasterize(image_size, polygon, result.bounds)
	return result


func is_active() -> bool:
	return bitmap != null and bounds.has_area()


func contains(point: Vector2i) -> bool:
	return is_active() and bounds.has_point(point) and bitmap.get_bitv(point)


static func simplify_polygon(
	points: PackedVector2Array,
	tolerance: float = 1.5
) -> PackedVector2Array:
	if points.size() < 5 or tolerance <= 0.0:
		return points.duplicate()
	var split_index := 1
	var greatest_distance := 0.0
	for index in range(1, points.size()):
		var distance := points[0].distance_squared_to(points[index])
		if distance > greatest_distance:
			greatest_distance = distance
			split_index = index
	if split_index <= 1 or split_index >= points.size() - 1:
		return points.duplicate()

	var first_chain := PackedVector2Array()
	for index in range(0, split_index + 1):
		first_chain.append(points[index])
	var second_chain := PackedVector2Array()
	for index in range(split_index, points.size()):
		second_chain.append(points[index])
	second_chain.append(points[0])

	var first_simplified := _simplify_open(first_chain, tolerance)
	var second_simplified := _simplify_open(second_chain, tolerance)
	var simplified := first_simplified
	for index in range(1, second_simplified.size() - 1):
		simplified.append(second_simplified[index])
	return simplified if simplified.size() >= 3 else points.duplicate()


static func _clipped_bounds(
	image_size: Vector2i,
	polygon: PackedVector2Array
) -> Rect2i:
	var minimum := polygon[0]
	var maximum := polygon[0]
	for point in polygon:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	var raw := Rect2i(
		Vector2i(floori(minimum.x), floori(minimum.y)),
		Vector2i(ceili(maximum.x), ceili(maximum.y))
		- Vector2i(floori(minimum.x), floori(minimum.y))
		+ Vector2i.ONE
	)
	return raw.intersection(Rect2i(Vector2i.ZERO, image_size))


static func _rasterize(
	image_size: Vector2i,
	polygon: PackedVector2Array,
	clipped_bounds: Rect2i
) -> BitMap:
	var result := BitMap.new()
	result.create(image_size)
	for y in range(clipped_bounds.position.y, clipped_bounds.end.y):
		var scan_y := float(y) + 0.5
		var intersections: Array[float] = []
		for index in polygon.size():
			var start := polygon[index]
			var finish := polygon[(index + 1) % polygon.size()]
			if (start.y > scan_y) == (finish.y > scan_y):
				continue
			var ratio := (scan_y - start.y) / (finish.y - start.y)
			intersections.append(start.x + ratio * (finish.x - start.x))
		intersections.sort()
		for pair_index in range(0, intersections.size() - 1, 2):
			var first_x := maxi(
				clipped_bounds.position.x,
				ceili(intersections[pair_index] - 0.5)
			)
			var last_x := mini(
				clipped_bounds.end.x - 1,
				floori(intersections[pair_index + 1] - 0.5)
			)
			for x in range(first_x, last_x + 1):
				result.set_bitv(Vector2i(x, y), true)
	return result


static func _simplify_open(
	points: PackedVector2Array,
	tolerance: float
) -> PackedVector2Array:
	if points.size() <= 2:
		return points.duplicate()
	var keep := PackedByteArray()
	keep.resize(points.size())
	keep[0] = 1
	keep[points.size() - 1] = 1
	var spans: Array[Vector2i] = [Vector2i(0, points.size() - 1)]
	var tolerance_squared := tolerance * tolerance
	while not spans.is_empty():
		var span: Vector2i = spans.pop_back()
		var greatest_distance := tolerance_squared
		var greatest_index := -1
		for index in range(span.x + 1, span.y):
			var distance := _segment_distance_squared(
				points[index],
				points[span.x],
				points[span.y]
			)
			if distance > greatest_distance:
				greatest_distance = distance
				greatest_index = index
		if greatest_index >= 0:
			keep[greatest_index] = 1
			spans.append(Vector2i(span.x, greatest_index))
			spans.append(Vector2i(greatest_index, span.y))
	var result := PackedVector2Array()
	for index in points.size():
		if keep[index] != 0:
			result.append(points[index])
	return result


static func _segment_distance_squared(
	point: Vector2,
	start: Vector2,
	finish: Vector2
) -> float:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if is_zero_approx(length_squared):
		return point.distance_squared_to(start)
	var ratio := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_squared_to(start + segment * ratio)
