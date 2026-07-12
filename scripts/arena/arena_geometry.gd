extends RefCounted
class_name ArenaGeometry

const SHAPE_RECTANGLE := 0
const SHAPE_DIAMOND := 1
const SHAPE_HEXAGON := 2
const SHAPE_CROSS := 3
const SHAPE_CIRCLE := 4
const EDGE_EPSILON := 0.001


static func build_polygon(arena_bounds: Rect2, arena_shape: int) -> PackedVector2Array:
	var center := arena_bounds.get_center()
	var half := arena_bounds.size * 0.5
	match arena_shape:
		SHAPE_DIAMOND:
			return PackedVector2Array([
				center + Vector2(0.0, -half.y),
				center + Vector2(half.x, 0.0),
				center + Vector2(0.0, half.y),
				center + Vector2(-half.x, 0.0)
			])
		SHAPE_HEXAGON:
			return PackedVector2Array([
				center + Vector2(-half.x * 0.52, -half.y),
				center + Vector2(half.x * 0.52, -half.y),
				center + Vector2(half.x, 0.0),
				center + Vector2(half.x * 0.52, half.y),
				center + Vector2(-half.x * 0.52, half.y),
				center + Vector2(-half.x, 0.0)
			])
		SHAPE_CROSS:
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
		SHAPE_CIRCLE:
			var points := PackedVector2Array()
			var segments := 32
			for index in range(segments):
				var angle: float = TAU * float(index) / float(segments)
				points.append(center + Vector2(cos(angle) * half.x, sin(angle) * half.y))
			return points
	return PackedVector2Array([
		arena_bounds.position,
		arena_bounds.position + Vector2(arena_bounds.size.x, 0.0),
		arena_bounds.position + arena_bounds.size,
		arena_bounds.position + Vector2(0.0, arena_bounds.size.y)
	])


static func contains_point(point: Vector2, arena_bounds: Rect2, arena_shape: int) -> bool:
	return is_point_in_polygon(point, build_polygon(arena_bounds, arena_shape))


static func constrain_point(point: Vector2, arena_bounds: Rect2, arena_shape: int) -> Vector2:
	var polygon := build_polygon(arena_bounds, arena_shape)
	if is_point_in_polygon(point, polygon):
		return point
	return get_closest_point_on_polygon(point, polygon)


static func constrain_point_to_playable(point: Vector2, arena_bounds: Rect2, arena_shape: int, blocker_rects: Array, clearance: float = 0.0) -> Vector2:
	var constrained := constrain_point(point, arena_bounds, arena_shape)
	if _is_clear_of_rects(constrained, blocker_rects, clearance):
		return constrained
	var search_step: float = max(clearance, 16.0)
	var best_point := constrained
	var best_distance := INF
	for radius_index in range(1, 9):
		var radius := search_step * float(radius_index)
		var sample_count := 8 + radius_index * 4
		for sample_index in range(sample_count):
			var angle := TAU * float(sample_index) / float(sample_count)
			var candidate := constrain_point(constrained + Vector2.RIGHT.rotated(angle) * radius, arena_bounds, arena_shape)
			if not _is_clear_of_rects(candidate, blocker_rects, clearance):
				continue
			var distance := candidate.distance_squared_to(point)
			if distance < best_distance:
				best_distance = distance
				best_point = candidate
	if best_distance < INF:
		return best_point
	return constrained


static func is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var count := polygon.size()
	if count < 3:
		return true
	var inside := false
	var previous_index := count - 1
	for index in range(count):
		var start := polygon[index]
		var end := polygon[previous_index]
		if _is_point_on_segment(point, start, end):
			return true
		var crosses_y: bool = (start.y > point.y) != (end.y > point.y)
		if crosses_y:
			var intersect_x: float = ((end.x - start.x) * (point.y - start.y) / (end.y - start.y)) + start.x
			if point.x < intersect_x:
				inside = not inside
		previous_index = index
	return inside


static func get_closest_point_on_polygon(point: Vector2, polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return point
	var closest := polygon[0]
	var closest_distance := INF
	for index in range(polygon.size()):
		var next_index := (index + 1) % polygon.size()
		var candidate := _closest_point_on_segment(point, polygon[index], polygon[next_index])
		var distance := point.distance_squared_to(candidate)
		if distance < closest_distance:
			closest = candidate
			closest_distance = distance
	return closest


static func _closest_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> Vector2:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= EDGE_EPSILON:
		return start
	var t: float = clamp((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return start + segment * t


static func _is_point_on_segment(point: Vector2, start: Vector2, end: Vector2) -> bool:
	var segment := end - start
	var to_point := point - start
	if abs(segment.cross(to_point)) > EDGE_EPSILON:
		return false
	var dot := to_point.dot(segment)
	return dot >= -EDGE_EPSILON and dot <= segment.length_squared() + EDGE_EPSILON


static func _is_clear_of_rects(point: Vector2, rects: Array, clearance: float) -> bool:
	for rect in rects:
		if not (rect is Rect2):
			continue
		var blocker: Rect2 = rect
		if blocker.grow(clearance).has_point(point):
			return false
	return true
