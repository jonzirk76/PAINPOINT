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
	return constrain_point_to_playable_regions(point, arena_bounds, arena_shape, [], blocker_rects, clearance)


static func constrain_point_to_playable_regions(point: Vector2, arena_bounds: Rect2, arena_shape: int, playable_rects: Array, blocker_rects: Array, clearance: float = 0.0) -> Vector2:
	var constrained: Vector2 = _constrain_point_to_regions(point, arena_bounds, arena_shape, playable_rects, clearance)
	if _is_clear_of_rects(constrained, blocker_rects, clearance):
		return constrained
	var search_step: float = max(clearance, 16.0)
	var best_point: Vector2 = constrained
	var best_distance: float = INF
	for radius_index in range(1, 9):
		var radius: float = search_step * float(radius_index)
		var sample_count: int = 8 + radius_index * 4
		for sample_index in range(sample_count):
			var angle: float = TAU * float(sample_index) / float(sample_count)
			var candidate: Vector2 = _constrain_point_to_regions(constrained + Vector2.RIGHT.rotated(angle) * radius, arena_bounds, arena_shape, playable_rects, clearance)
			if not _is_clear_of_rects(candidate, blocker_rects, clearance):
				continue
			var distance: float = candidate.distance_squared_to(point)
			if distance < best_distance:
				best_distance = distance
				best_point = candidate
	if best_distance < INF:
		return best_point
	return constrained


static func get_footprint_cell_rects(arena_bounds: Rect2, cells: Array) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if cells.is_empty():
		return rects
	var min_cell: Vector2i = cells[0]
	var max_cell: Vector2i = cells[0]
	for cell in cells:
		if not (cell is Vector2i):
			continue
		min_cell.x = min(min_cell.x, cell.x)
		min_cell.y = min(min_cell.y, cell.y)
		max_cell.x = max(max_cell.x, cell.x)
		max_cell.y = max(max_cell.y, cell.y)
	var grid_size: Vector2 = Vector2(max(max_cell.x - min_cell.x + 1, 1), max(max_cell.y - min_cell.y + 1, 1))
	var cell_size: Vector2 = Vector2(arena_bounds.size.x / grid_size.x, arena_bounds.size.y / grid_size.y)
	for cell in cells:
		if not (cell is Vector2i):
			continue
		var offset: Vector2 = Vector2(float(cell.x - min_cell.x), float(cell.y - min_cell.y)) * cell_size
		rects.append(Rect2(arena_bounds.position + offset, cell_size))
	return rects


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


static func _constrain_point_to_regions(point: Vector2, arena_bounds: Rect2, arena_shape: int, playable_rects: Array, clearance: float) -> Vector2:
	if playable_rects.is_empty():
		return constrain_point(point, arena_bounds, arena_shape)
	if _is_clear_in_rect_union(point, playable_rects, clearance):
		return point
	var constrained: Vector2 = point if _is_point_in_rect_union(point, playable_rects) else _closest_point_in_rect_union(point, playable_rects)
	return _push_point_clear_of_rect_union(constrained, playable_rects, clearance)


static func _is_clear_in_rect_union(point: Vector2, rects: Array, clearance: float) -> bool:
	if not _is_point_in_rect_union(point, rects):
		return false
	var radius: float = max(clearance, 0.0)
	if radius <= EDGE_EPSILON:
		return true
	if _has_single_rect_clearance(point, rects, radius):
		return true
	for index in range(8):
		var sample_point: Vector2 = point + Vector2.RIGHT.rotated(TAU * float(index) / 8.0) * radius
		if not _is_point_in_rect_union(sample_point, rects):
			return false
	return true


static func _is_point_in_rect_union(point: Vector2, rects: Array) -> bool:
	for rect in rects:
		if not (rect is Rect2):
			continue
		if _rect_has_point_inclusive(rect, point):
			return true
	return false


static func _has_single_rect_clearance(point: Vector2, rects: Array, clearance: float) -> bool:
	for rect in rects:
		if not (rect is Rect2):
			continue
		var inset_rect: Rect2 = _inset_rect(rect, clearance)
		if _rect_has_point_inclusive(inset_rect, point):
			return true
	return false


static func _push_point_clear_of_rect_union(point: Vector2, rects: Array, clearance: float) -> Vector2:
	var current: Vector2 = point
	var radius: float = max(clearance, 0.0)
	for _iteration in range(6):
		if _is_clear_in_rect_union(current, rects, radius):
			return current
		var correction: Vector2 = Vector2.ZERO
		var correction_count: int = 0
		if not _is_point_in_rect_union(current, rects):
			correction += _closest_point_in_rect_union(current, rects) - current
			correction_count += 1
		if radius > EDGE_EPSILON:
			for index in range(8):
				var sample_point: Vector2 = current + Vector2.RIGHT.rotated(TAU * float(index) / 8.0) * radius
				if _is_point_in_rect_union(sample_point, rects):
					continue
				correction += _closest_point_in_rect_union(sample_point, rects) - sample_point
				correction_count += 1
		if correction_count <= 0:
			return current
		var step: Vector2 = correction / float(correction_count)
		if step.length_squared() <= 0.001:
			return current
		current += step.limit_length(max(radius * 0.65, 4.0))
		if not _is_point_in_rect_union(current, rects):
			current = _closest_point_in_rect_union(current, rects)
	return current


static func _closest_point_in_rect_union(point: Vector2, rects: Array) -> Vector2:
	var closest: Vector2 = point
	var closest_distance: float = INF
	for rect in rects:
		if not (rect is Rect2):
			continue
		var candidate: Vector2 = _closest_point_on_rect(point, rect)
		var distance: float = candidate.distance_squared_to(point)
		if distance < closest_distance:
			closest_distance = distance
			closest = candidate
	return closest


static func _rect_has_point_inclusive(rect: Rect2, point: Vector2) -> bool:
	var end: Vector2 = rect.position + rect.size
	return point.x >= rect.position.x - EDGE_EPSILON and point.x <= end.x + EDGE_EPSILON and point.y >= rect.position.y - EDGE_EPSILON and point.y <= end.y + EDGE_EPSILON


static func _inset_rect(rect: Rect2, inset: float) -> Rect2:
	var safe_inset: float = min(max(inset, 0.0), min(rect.size.x, rect.size.y) * 0.45)
	return Rect2(rect.position + Vector2(safe_inset, safe_inset), Vector2(max(rect.size.x - safe_inset * 2.0, 1.0), max(rect.size.y - safe_inset * 2.0, 1.0)))


static func _closest_point_on_rect(point: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clamp(point.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(point.y, rect.position.y, rect.position.y + rect.size.y)
	)
