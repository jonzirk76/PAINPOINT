extends RefCounted
class_name RoomInteriorGenerator

const LEVEL_DEFINITION_SCRIPT := preload("res://scripts/resources/level_definition.gd")
const SPAWNER_PLACEMENT_SCRIPT := preload("res://scripts/resources/spawner_placement.gd")
const BASIC_SPAWNER := preload("res://resources/spawners/basic_spawner.tres")
const FAST_SPAWNER := preload("res://resources/spawners/fast_spawner.tres")
const SHOOTER_SPAWNER := preload("res://resources/spawners/shooter_spawner.tres")
const TANK_SPAWNER := preload("res://resources/spawners/tank_spawner.tres")

const GRID_SIZE := 60.0
const MAX_ATTEMPTS := 40
const PLAYER_CLEARANCE := 34.0
const SPAWNER_CLEARANCE := 54.0
const SPAWNER_MIN_DISTANCE := 160.0


func generate(piece, room_id: String, floor_number: int, floor_seed: int, connections: Dictionary):
	var room_kind := String(piece.room_kind)
	var base_level = _make_base_level(piece, room_id, floor_number)
	if room_kind != "combat" and room_kind != "challenge":
		return base_level
	var rng := RandomNumberGenerator.new()
	rng.seed = _compute_room_seed(room_id, floor_number, floor_seed, String(piece.id))
	for attempt in range(MAX_ATTEMPTS):
		var level = _make_base_level(piece, room_id, floor_number)
		var archetype: int = (rng.randi_range(0, 4) + attempt) % 5
		var blockers: Dictionary = _build_obstacles(level, connections, archetype, rng)
		var generated_walls: Array[Rect2] = blockers["walls"]
		var generated_voids: Array[Rect2] = blockers["voids"]
		level.wall_rects = generated_walls
		level.void_rects = generated_voids
		var generated_spawners: Array[Resource] = _build_spawner_placements(level, room_kind, floor_number, rng)
		level.spawner_placements = generated_spawners
		if level.spawner_placements.size() <= 0:
			continue
		level.max_active_enemies = clamp(24 + floor_number * 4 + level.spawner_placements.size() * 2, 30, 52)
		var result: Dictionary = validate_level(level, connections, room_kind)
		if bool(result.get("ok", false)):
			return level
	var fallback = _make_base_level(piece, room_id, floor_number)
	var fallback_rng := RandomNumberGenerator.new()
	fallback_rng.seed = _compute_room_seed(room_id, floor_number, floor_seed, String(piece.id)) + 9091
	_apply_fallback_interior(fallback, room_kind, floor_number, fallback_rng)
	return fallback


func validate_level(level, connections: Dictionary, room_kind: String) -> Dictionary:
	if level == null:
		return {"ok": false, "reason": "missing_level"}
	var blockers: Array[Rect2] = _get_movement_blockers(level)
	var clear_points: Array[Vector2] = [level.arena_bounds.get_center()]
	for direction_key in connections.keys():
		var direction := String(direction_key)
		var approach_rect := _get_door_clear_rect(level.arena_bounds, direction)
		for blocker in blockers:
			if blocker.intersects(approach_rect):
				return {"ok": false, "reason": "blocked_door_approach"}
		clear_points.append(_get_door_entry_position(level.arena_bounds, direction))
	for placement in level.spawner_placements:
		if placement == null or placement.profile == null:
			return {"ok": false, "reason": "bad_spawner"}
		var position: Vector2 = placement.position
		if not _point_is_clear(level, position, blockers, SPAWNER_CLEARANCE):
			return {"ok": false, "reason": "spawner_blocked"}
		clear_points.append(position)
	for first_index in range(level.spawner_placements.size()):
		for second_index in range(first_index + 1, level.spawner_placements.size()):
			var first_position: Vector2 = level.spawner_placements[first_index].position
			var second_position: Vector2 = level.spawner_placements[second_index].position
			if first_position.distance_squared_to(second_position) < SPAWNER_MIN_DISTANCE * SPAWNER_MIN_DISTANCE:
				return {"ok": false, "reason": "spawner_spacing"}
	for point in clear_points:
		if not _point_is_clear(level, point, blockers, PLAYER_CLEARANCE):
			return {"ok": false, "reason": "required_point_blocked"}
	var grid := _build_navigation_grid(level, blockers)
	if grid["open"].is_empty():
		return {"ok": false, "reason": "no_open_cells"}
	var start_cell: Vector2i = _nearest_open_cell(level.arena_bounds.get_center(), grid["open"], level.arena_bounds)
	if not grid["open"].has(_cell_key(start_cell)):
		return {"ok": false, "reason": "spawn_unreachable"}
	var reachable: Dictionary = _flood_fill(start_cell, grid["open"])
	if float(reachable.size()) / float(max(grid["open"].size(), 1)) < 0.55:
		return {"ok": false, "reason": "main_component_small"}
	for point in clear_points:
		var cell := _nearest_open_cell(point, grid["open"], level.arena_bounds)
		if not reachable.has(_cell_key(cell)):
			return {"ok": false, "reason": "required_point_unreachable"}
	if not _has_dodge_pocket(reachable):
		return {"ok": false, "reason": "missing_dodge_pocket"}
	if _has_heavy_spawner(level) and _count_clear_lanes(level, blockers) < 2:
		return {"ok": false, "reason": "heavy_spawner_lanes"}
	var min_count := 5 if room_kind == "challenge" else 4
	if level.spawner_placements.size() < min_count:
		return {"ok": false, "reason": "spawner_budget_low"}
	return {"ok": true, "reason": ""}


func _make_base_level(piece, room_id: String, floor_number: int):
	var level = piece.create_level_definition()
	level.id = room_id
	level.display_name = "%s - %s" % [piece.display_name, room_id.capitalize()]
	level.difficulty_label = "Floor %d %s" % [floor_number, String(piece.room_kind).capitalize()]
	level.use_default_spawners = false
	var empty_positions: Array[Vector2] = []
	var empty_placements: Array[Resource] = []
	var empty_walls: Array[Rect2] = []
	var empty_voids: Array[Rect2] = []
	level.spawner_positions = empty_positions
	level.spawner_placements = empty_placements
	level.wall_rects = empty_walls
	level.void_rects = empty_voids
	return level


func _compute_room_seed(room_id: String, floor_number: int, floor_seed: int, piece_id: String) -> int:
	var seed_text := "%d:%d:%s:%s" % [floor_seed, floor_number, room_id, piece_id]
	return abs(seed_text.hash()) + 1


func _build_obstacles(level, connections: Dictionary, archetype: int, rng: RandomNumberGenerator) -> Dictionary:
	var walls: Array[Rect2] = []
	var voids: Array[Rect2] = []
	var bounds: Rect2 = level.arena_bounds
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	match archetype:
		0:
			_try_add_block(walls, _rect_at(center + Vector2(-half.x * 0.22, -half.y * 0.18), Vector2(3, 1)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(half.x * 0.22, half.y * 0.18), Vector2(3, 1)), level, connections, walls, voids)
			_try_add_block(voids, _rect_at(center + Vector2(0.0, -half.y * 0.36), Vector2(3, 1)), level, connections, walls, voids)
		1:
			_try_add_block(walls, _rect_at(center + Vector2(-half.x * 0.16, -half.y * 0.22), Vector2(1, 4)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(half.x * 0.16, half.y * 0.22), Vector2(1, 4)), level, connections, walls, voids)
			_try_add_block(voids, _rect_at(center + Vector2(-half.x * 0.34, half.y * 0.26), Vector2(2, 2)), level, connections, walls, voids)
		2:
			_try_add_block(walls, _rect_at(center, Vector2(3, 2)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(-half.x * 0.34, 0.0), Vector2(2, 1)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(half.x * 0.34, 0.0), Vector2(2, 1)), level, connections, walls, voids)
			_try_add_block(voids, _rect_at(center + Vector2(0.0, half.y * 0.34), Vector2(2, 1)), level, connections, walls, voids)
		3:
			_try_add_block(walls, _rect_at(center + Vector2(-half.x * 0.28, -half.y * 0.16), Vector2(1, 5)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(half.x * 0.1, half.y * 0.18), Vector2(1, 4)), level, connections, walls, voids)
			_try_add_block(voids, _rect_at(center + Vector2(half.x * 0.36, -half.y * 0.28), Vector2(2, 2)), level, connections, walls, voids)
		_:
			_try_add_block(walls, _rect_at(center + Vector2(-half.x * 0.32, 0.0), Vector2(2, 3)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(half.x * 0.18, -half.y * 0.22), Vector2(3, 1)), level, connections, walls, voids)
			_try_add_block(walls, _rect_at(center + Vector2(half.x * 0.18, half.y * 0.22), Vector2(3, 1)), level, connections, walls, voids)
			_try_add_block(voids, _rect_at(center + Vector2(half.x * 0.36, half.y * 0.28), Vector2(2, 2)), level, connections, walls, voids)
	if rng.randf() < 0.45:
		var side_sign := -1.0 if rng.randi_range(0, 1) == 0 else 1.0
		_try_add_block(voids, _rect_at(center + Vector2(side_sign * half.x * 0.42, -side_sign * half.y * 0.3), Vector2(2, 1)), level, connections, walls, voids)
	return {"walls": walls, "voids": voids}


func _try_add_block(target: Array[Rect2], rect: Rect2, level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2]) -> bool:
	if not _rect_fits_arena(rect, level):
		return false
	if _rect_hits_reserved_zone(rect, level, connections):
		return false
	var blockers: Array[Rect2] = []
	blockers.append_array(walls)
	blockers.append_array(voids)
	for blocker in blockers:
		if blocker.grow(18.0).intersects(rect):
			return false
	target.append(rect)
	return true


func _rect_at(center: Vector2, cells: Vector2) -> Rect2:
	var size := Vector2(float(cells.x) * GRID_SIZE, float(cells.y) * GRID_SIZE)
	var snapped_center := Vector2(round(center.x / GRID_SIZE) * GRID_SIZE, round(center.y / GRID_SIZE) * GRID_SIZE)
	return Rect2(snapped_center - size * 0.5, size)


func _rect_fits_arena(rect: Rect2, level) -> bool:
	var points := [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.position + rect.size,
		rect.position + Vector2(0.0, rect.size.y),
		rect.get_center()
	]
	for point in points:
		if not ArenaGeometry.contains_point(point, level.arena_bounds, int(level.arena_shape)):
			return false
	return true


func _rect_hits_reserved_zone(rect: Rect2, level, connections: Dictionary) -> bool:
	var reserved: Array[Rect2] = [
		Rect2(level.arena_bounds.get_center() - Vector2(180.0, 140.0), Vector2(360.0, 280.0))
	]
	for direction_key in connections.keys():
		reserved.append(_get_door_clear_rect(level.arena_bounds, String(direction_key)))
	for zone in reserved:
		if zone.intersects(rect):
			return true
	return false


func _build_spawner_placements(level, room_kind: String, floor_number: int, rng: RandomNumberGenerator) -> Array[Resource]:
	var profiles: Array[Resource] = _build_spawner_profile_budget(room_kind, floor_number, rng)
	var placements: Array[Resource] = []
	var candidate_points := _build_spawner_candidate_points(level.arena_bounds, rng)
	var blockers: Array[Rect2] = _get_movement_blockers(level)
	for profile in profiles:
		var chosen := Vector2.INF
		for point in candidate_points:
			if _point_is_clear(level, point, blockers, SPAWNER_CLEARANCE) and _has_spawner_spacing(point, placements):
				chosen = point
				break
		if chosen == Vector2.INF:
			var no_placements: Array[Resource] = []
			return no_placements
		var placement = SPAWNER_PLACEMENT_SCRIPT.new()
		placement.position = chosen
		placement.profile = profile
		placement.warmup_seconds = 1.0 + float(placements.size()) * 0.45
		placements.append(placement)
		candidate_points.erase(chosen)
	return placements


func _build_spawner_profile_budget(room_kind: String, floor_number: int, rng: RandomNumberGenerator) -> Array[Resource]:
	var budget: int = (16 + floor_number * 4) if room_kind == "challenge" else (12 + floor_number * 3)
	var min_count := 5 if room_kind == "challenge" else 4
	var max_count := 7 if room_kind == "challenge" else 6
	var profiles: Array[Resource] = []
	var options := _get_spawner_options(floor_number)
	while profiles.size() < min_count and budget >= 3:
		var option: Dictionary = options[(profiles.size() + rng.randi_range(0, options.size() - 1)) % options.size()]
		if int(option["cost"]) > budget:
			option = options[options.size() - 1]
		profiles.append(option["profile"])
		budget -= int(option["cost"])
	while profiles.size() < max_count:
		var selected: Dictionary = {}
		for attempt in range(options.size()):
			var option: Dictionary = options[(rng.randi_range(0, options.size() - 1) + attempt) % options.size()]
			if int(option["cost"]) <= budget:
				selected = option
				break
		if selected.is_empty():
			break
		profiles.append(selected["profile"])
		budget -= int(selected["cost"])
	return profiles


func _get_spawner_options(floor_number: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if floor_number >= 4:
		options.append({"profile": TANK_SPAWNER, "cost": 7})
	if floor_number >= 3:
		options.append({"profile": SHOOTER_SPAWNER, "cost": 5})
	if floor_number >= 2:
		options.append({"profile": FAST_SPAWNER, "cost": 4})
	options.append({"profile": BASIC_SPAWNER, "cost": 3})
	return options


func _build_spawner_candidate_points(bounds: Rect2, rng: RandomNumberGenerator) -> Array[Vector2]:
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	var points: Array[Vector2] = [
		center + Vector2(-half.x * 0.34, -half.y * 0.24),
		center + Vector2(half.x * 0.34, half.y * 0.24),
		center + Vector2(half.x * 0.34, -half.y * 0.24),
		center + Vector2(-half.x * 0.34, half.y * 0.24),
		center + Vector2(-half.x * 0.18, 0.0),
		center + Vector2(half.x * 0.18, 0.0),
		center + Vector2(0.0, -half.y * 0.28),
		center + Vector2(0.0, half.y * 0.28),
		center + Vector2(-half.x * 0.42, 0.0),
		center + Vector2(half.x * 0.42, 0.0)
	]
	for index in range(points.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := points[index]
		points[index] = points[swap_index]
		points[swap_index] = value
	return points


func _has_spawner_spacing(point: Vector2, placements: Array) -> bool:
	for placement in placements:
		if point.distance_squared_to(placement.position) < SPAWNER_MIN_DISTANCE * SPAWNER_MIN_DISTANCE:
			return false
	return true


func _apply_fallback_interior(level, room_kind: String, floor_number: int, rng: RandomNumberGenerator) -> void:
	var bounds: Rect2 = level.arena_bounds
	var center := bounds.get_center()
	var fallback_walls: Array[Rect2] = [
		_rect_at(center + Vector2(-bounds.size.x * 0.18, -bounds.size.y * 0.16), Vector2(2, 1)),
		_rect_at(center + Vector2(bounds.size.x * 0.18, bounds.size.y * 0.16), Vector2(2, 1))
	]
	var fallback_voids: Array[Rect2] = []
	level.wall_rects = fallback_walls
	level.void_rects = fallback_voids
	var min_count := 5 if room_kind == "challenge" else 4
	var profiles := _build_spawner_profile_budget(room_kind, floor_number, rng)
	while profiles.size() > min_count:
		profiles.pop_back()
	var fallback_placements: Array[Resource] = []
	level.spawner_placements = fallback_placements
	var points := _build_fallback_spawner_points(bounds, 7)
	var selected_points := _select_fallback_spawner_points(level, points, min_count)
	if selected_points.size() < min_count:
		var no_walls: Array[Rect2] = []
		level.wall_rects = no_walls
		selected_points = _select_fallback_spawner_points(level, points, min_count)
	for index in range(min_count):
		var placement = SPAWNER_PLACEMENT_SCRIPT.new()
		placement.position = selected_points[index] if index < selected_points.size() else level.arena_bounds.get_center()
		placement.profile = profiles[index] if index < profiles.size() else BASIC_SPAWNER
		placement.warmup_seconds = 1.0 + float(index) * 0.45
		level.spawner_placements.append(placement)
	level.max_active_enemies = clamp(24 + floor_number * 4 + level.spawner_placements.size() * 2, 30, 52)


func _build_fallback_spawner_points(bounds: Rect2, count: int) -> Array[Vector2]:
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	var points: Array[Vector2] = [
		center + Vector2(-half.x * 0.34, -half.y * 0.24),
		center + Vector2(half.x * 0.34, -half.y * 0.24),
		center + Vector2(-half.x * 0.34, half.y * 0.24),
		center + Vector2(half.x * 0.34, half.y * 0.24),
		center + Vector2(0.0, -half.y * 0.28),
		center + Vector2(0.0, half.y * 0.28),
		center + Vector2(-half.x * 0.42, 0.0)
	]
	return points.slice(0, count)


func _select_fallback_spawner_points(level, points: Array[Vector2], count: int) -> Array[Vector2]:
	var selected: Array[Vector2] = []
	var blockers: Array[Rect2] = _get_movement_blockers(level)
	for point in points:
		if not _point_is_clear(level, point, blockers, SPAWNER_CLEARANCE):
			continue
		if not _point_has_spacing(point, selected):
			continue
		selected.append(point)
		if selected.size() >= count:
			break
	return selected


func _point_has_spacing(point: Vector2, selected_points: Array[Vector2]) -> bool:
	for selected in selected_points:
		if point.distance_squared_to(selected) < SPAWNER_MIN_DISTANCE * SPAWNER_MIN_DISTANCE:
			return false
	return true


func _get_movement_blockers(level) -> Array[Rect2]:
	var blockers: Array[Rect2] = []
	blockers.append_array(level.wall_rects)
	blockers.append_array(level.void_rects)
	return blockers


func _point_is_clear(level, point: Vector2, blockers: Array[Rect2], clearance: float) -> bool:
	if not ArenaGeometry.contains_point(point, level.arena_bounds, int(level.arena_shape)):
		return false
	for blocker in blockers:
		if blocker.grow(clearance).has_point(point):
			return false
	return true


func _get_door_entry_position(bounds: Rect2, direction: String) -> Vector2:
	var margin := 96.0
	match direction:
		"north":
			return Vector2(bounds.get_center().x, bounds.position.y + margin)
		"south":
			return Vector2(bounds.get_center().x, bounds.position.y + bounds.size.y - margin)
		"east":
			return Vector2(bounds.position.x + bounds.size.x - margin, bounds.get_center().y)
		"west":
			return Vector2(bounds.position.x + margin, bounds.get_center().y)
	return bounds.get_center()


func _get_door_clear_rect(bounds: Rect2, direction: String) -> Rect2:
	var center := bounds.get_center()
	match direction:
		"north":
			return Rect2(Vector2(center.x - 150.0, bounds.position.y), Vector2(300.0, 210.0))
		"south":
			return Rect2(Vector2(center.x - 150.0, bounds.position.y + bounds.size.y - 210.0), Vector2(300.0, 210.0))
		"east":
			return Rect2(Vector2(bounds.position.x + bounds.size.x - 210.0, center.y - 150.0), Vector2(210.0, 300.0))
		"west":
			return Rect2(Vector2(bounds.position.x, center.y - 150.0), Vector2(210.0, 300.0))
	return Rect2(center - Vector2(150.0, 150.0), Vector2(300.0, 300.0))


func _build_navigation_grid(level, blockers: Array[Rect2]) -> Dictionary:
	var open: Dictionary = {}
	var cols: int = max(int(floor(level.arena_bounds.size.x / GRID_SIZE)), 1)
	var rows: int = max(int(floor(level.arena_bounds.size.y / GRID_SIZE)), 1)
	for x in range(cols):
		for y in range(rows):
			var cell := Vector2i(x, y)
			var center := _cell_center(level.arena_bounds, cell)
			if _point_is_clear(level, center, blockers, PLAYER_CLEARANCE):
				open[_cell_key(cell)] = cell
	return {"open": open, "cols": cols, "rows": rows}


func _cell_center(bounds: Rect2, cell: Vector2i) -> Vector2:
	return bounds.position + Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5) * GRID_SIZE


func _nearest_open_cell(point: Vector2, open: Dictionary, bounds: Rect2) -> Vector2i:
	var best := Vector2i(-9999, -9999)
	var best_distance := INF
	for key in open.keys():
		var cell: Vector2i = open[key]
		var center := _cell_center(bounds, cell)
		var distance := center.distance_squared_to(point)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best


func _flood_fill(start_cell: Vector2i, open: Dictionary) -> Dictionary:
	var reachable: Dictionary = {}
	var start_key := _cell_key(start_cell)
	if not open.has(start_key):
		return reachable
	var queue: Array[Vector2i] = [start_cell]
	reachable[start_key] = start_cell
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for offset in offsets:
			var next_cell: Vector2i = cell + offset
			var key := _cell_key(next_cell)
			if not open.has(key) or reachable.has(key):
				continue
			reachable[key] = next_cell
			queue.append(next_cell)
	return reachable


func _has_dodge_pocket(reachable: Dictionary) -> bool:
	for key in reachable.keys():
		var origin: Vector2i = reachable[key]
		if _rect_cells_reachable(origin, Vector2i(6, 4), reachable) or _rect_cells_reachable(origin, Vector2i(4, 6), reachable):
			return true
	return false


func _rect_cells_reachable(origin: Vector2i, size: Vector2i, reachable: Dictionary) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			if not reachable.has(_cell_key(origin + Vector2i(x, y))):
				return false
	return true


func _has_heavy_spawner(level) -> bool:
	for placement in level.spawner_placements:
		if placement.profile == SHOOTER_SPAWNER or placement.profile == TANK_SPAWNER:
			return true
	return false


func _count_clear_lanes(level, blockers: Array[Rect2]) -> int:
	var center: Vector2 = level.arena_bounds.get_center()
	var half: Vector2 = level.arena_bounds.size * 0.5
	var targets := [
		center + Vector2(half.x * 0.42, 0.0),
		center + Vector2(-half.x * 0.42, 0.0),
		center + Vector2(0.0, half.y * 0.42),
		center + Vector2(0.0, -half.y * 0.42)
	]
	var count := 0
	for target in targets:
		if not _segment_hits_blocker(center, target, blockers, 28.0):
			count += 1
	return count


func _segment_hits_blocker(from_position: Vector2, to_position: Vector2, blockers: Array[Rect2], margin: float) -> bool:
	for blocker in blockers:
		if _segment_intersects_rect(from_position, to_position, blocker.grow(margin)):
			return true
	return false


func _segment_intersects_rect(from_position: Vector2, to_position: Vector2, rect: Rect2) -> bool:
	if rect.has_point(from_position) or rect.has_point(to_position):
		return true
	var top_left := rect.position
	var top_right := rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right := rect.position + rect.size
	var bottom_left := rect.position + Vector2(0.0, rect.size.y)
	if _segments_intersect(from_position, to_position, top_left, top_right):
		return true
	if _segments_intersect(from_position, to_position, top_right, bottom_right):
		return true
	if _segments_intersect(from_position, to_position, bottom_right, bottom_left):
		return true
	if _segments_intersect(from_position, to_position, bottom_left, top_left):
		return true
	return false


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var r := b - a
	var s := d - c
	var denominator := r.cross(s)
	var c_to_a := c - a
	if abs(denominator) <= 0.001:
		if abs(c_to_a.cross(r)) > 0.001:
			return false
		var use_x: bool = abs(r.x) >= abs(r.y)
		var a0: float = a.x if use_x else a.y
		var b0: float = b.x if use_x else b.y
		var c0: float = c.x if use_x else c.y
		var d0: float = d.x if use_x else d.y
		return max(min(a0, b0), min(c0, d0)) <= min(max(a0, b0), max(c0, d0))
	var t := c_to_a.cross(s) / denominator
	var u := c_to_a.cross(r) / denominator
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
