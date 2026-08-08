extends Resource
class_name RoomSpatialDomain

const POSITION_EPSILON_SQUARED := 0.25

var room_id: String = ""
var arena_bounds: Rect2 = Rect2()
var arena_shape: int = ArenaGeometry.SHAPE_RECTANGLE
var grid_origin: Vector2 = Vector2.ZERO
var grid_cell_size: float = 40.0
var playable_regions: Array[Rect2] = []
var static_blockers: Array[Rect2] = []
var transition_regions: Array[Rect2] = []
var layout_spawn_reservations: Array[Rect2] = []
var reachable_cells: Array[Vector2i] = []
var _reachable_lookup: Dictionary = {}


func initialize(
	new_room_id: String,
	new_arena_bounds: Rect2,
	new_arena_shape: int,
	new_playable_regions: Array[Rect2],
	new_static_blockers: Array[Rect2],
	new_transition_regions: Array[Rect2],
	new_layout_spawn_reservations: Array[Rect2],
	new_reachable_cells: Array[Vector2i] = [],
	new_grid_cell_size: float = 40.0
) -> void:
	room_id = new_room_id
	arena_bounds = new_arena_bounds
	arena_shape = new_arena_shape
	grid_origin = new_arena_bounds.position
	grid_cell_size = max(new_grid_cell_size, 1.0)
	playable_regions = new_playable_regions.duplicate()
	static_blockers = new_static_blockers.duplicate()
	transition_regions = new_transition_regions.duplicate()
	layout_spawn_reservations = new_layout_spawn_reservations.duplicate()
	reachable_cells = new_reachable_cells.duplicate()
	_rebuild_reachable_lookup()


func contains_spawn_position(position: Vector2, clearance: float, runtime_blockers: Array[Rect2] = []) -> bool:
	var blockers := _get_spawn_blockers(runtime_blockers)
	return _contains_position(position, clearance, blockers)


func contains_walkable_position(position: Vector2, clearance: float, runtime_blockers: Array[Rect2] = []) -> bool:
	return _contains_position(position, clearance, _get_walkable_blockers(runtime_blockers))


func constrain_spawn_position(position: Vector2, clearance: float, runtime_blockers: Array[Rect2] = []) -> Vector2:
	return _constrain_position(position, clearance, _get_spawn_blockers(runtime_blockers))


func constrain_walkable_position(position: Vector2, clearance: float, runtime_blockers: Array[Rect2] = []) -> Vector2:
	return _constrain_position(position, clearance, _get_walkable_blockers(runtime_blockers))


func _contains_position(position: Vector2, clearance: float, blockers: Array[Rect2]) -> bool:
	if not _position_uses_reachable_floor(position):
		return false
	for blocker in blockers:
		if blocker.grow(clearance).has_point(position):
			return false
	var constrained := ArenaGeometry.constrain_point_to_playable_regions(
		position,
		arena_bounds,
		arena_shape,
		playable_regions,
		blockers,
		clearance
	)
	return constrained.distance_squared_to(position) <= POSITION_EPSILON_SQUARED


func _constrain_position(position: Vector2, clearance: float, blockers: Array[Rect2]) -> Vector2:
	var constrained := ArenaGeometry.constrain_point_to_playable_regions(
		position,
		arena_bounds,
		arena_shape,
		playable_regions,
		blockers,
		clearance
	)
	if _contains_position(constrained, clearance, blockers):
		return constrained
	var best_position := constrained
	var best_distance := INF
	for cell in reachable_cells:
		var candidate := grid_origin + (Vector2(cell) + Vector2(0.5, 0.5)) * grid_cell_size
		candidate = ArenaGeometry.constrain_point_to_playable_regions(
			candidate,
			arena_bounds,
			arena_shape,
			playable_regions,
			blockers,
			clearance
		)
		if not _contains_position(candidate, clearance, blockers):
			continue
		var distance := candidate.distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best_position = candidate
	return best_position


func translated(offset: Vector2) -> RoomSpatialDomain:
	var result := RoomSpatialDomain.new()
	result.initialize(
		room_id,
		Rect2(arena_bounds.position + offset, arena_bounds.size),
		arena_shape,
		_translate_rects(playable_regions, offset),
		_translate_rects(static_blockers, offset),
		_translate_rects(transition_regions, offset),
		_translate_rects(layout_spawn_reservations, offset),
		reachable_cells,
		grid_cell_size
	)
	return result


func get_transition_regions() -> Array[Rect2]:
	return transition_regions.duplicate()


func get_playable_regions() -> Array[Rect2]:
	return playable_regions.duplicate()


func get_reachable_cells() -> Array[Vector2i]:
	return reachable_cells.duplicate()


func _position_uses_reachable_floor(position: Vector2) -> bool:
	if _reachable_lookup.is_empty():
		return true
	return _reachable_lookup.has(_get_grid_cell(position))


func _get_grid_cell(position: Vector2) -> Vector2i:
	var local_position := position - grid_origin
	return Vector2i(
		floori(local_position.x / grid_cell_size),
		floori(local_position.y / grid_cell_size)
	)


func _get_spawn_blockers(runtime_blockers: Array[Rect2]) -> Array[Rect2]:
	var blockers := _get_walkable_blockers(runtime_blockers)
	blockers.append_array(transition_regions)
	return blockers


func _get_walkable_blockers(runtime_blockers: Array[Rect2]) -> Array[Rect2]:
	var blockers: Array[Rect2] = []
	blockers.append_array(static_blockers)
	blockers.append_array(layout_spawn_reservations)
	blockers.append_array(runtime_blockers)
	return blockers


func _rebuild_reachable_lookup() -> void:
	_reachable_lookup.clear()
	for cell in reachable_cells:
		_reachable_lookup[cell] = true


func _translate_rects(rects: Array[Rect2], offset: Vector2) -> Array[Rect2]:
	var translated_rects: Array[Rect2] = []
	for rect in rects:
		translated_rects.append(Rect2(rect.position + offset, rect.size))
	return translated_rects
