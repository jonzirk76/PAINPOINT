extends RefCounted
class_name RoomInteriorGenerator

const LEVEL_DEFINITION_SCRIPT := preload("res://scripts/resources/level_definition.gd")
const SPAWNER_PLACEMENT_SCRIPT := preload("res://scripts/resources/spawner_placement.gd")
const DESTRUCTIBLE_PROP_PLACEMENT_SCRIPT := preload("res://scripts/resources/destructible_prop_placement.gd")
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const BASIC_SPAWNER := preload("res://resources/spawners/basic_spawner.tres")
const FAST_SPAWNER := preload("res://resources/spawners/fast_spawner.tres")
const SHOOTER_SPAWNER := preload("res://resources/spawners/shooter_spawner.tres")
const TANK_SPAWNER := preload("res://resources/spawners/tank_spawner.tres")

const GRID_SIZE: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
const MAX_ATTEMPTS := 40
const PLAYER_CLEARANCE := 34.0
const SPAWNER_CLEARANCE := 54.0
const SPAWNER_MIN_DISTANCE := 160.0
const OBSTACLE_PADDING := 12.0


func generate(piece, room_id: String, floor_number: int, floor_seed: int, connections: Dictionary, connection_edges: Dictionary = {}):
	var room_kind := String(piece.room_kind)
	var effective_connection_edges := _get_effective_connection_edges(piece.footprint_cells, connections, connection_edges)
	var base_level = _make_base_level(piece, room_id, floor_number, effective_connection_edges)
	if room_kind != "combat" and room_kind != "challenge" and room_kind != "boss":
		return base_level
	var rng := RandomNumberGenerator.new()
	rng.seed = _compute_room_seed(room_id, floor_number, floor_seed, String(piece.id))
	if room_kind == "boss":
		for attempt in range(MAX_ATTEMPTS):
			var level = _make_base_level(piece, room_id, floor_number, effective_connection_edges)
			var shell_wall_tiles: Array[Rect2] = _get_level_wall_tiles(level)
			var blockers: Dictionary = _build_boss_obstacles(level, connections, rng, floor_number, attempt)
			var boss_wall_tiles: Array[Rect2] = shell_wall_tiles.duplicate()
			boss_wall_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(blockers["walls"]))
			_apply_wall_tiles(level, boss_wall_tiles)
			_apply_void_rects(level, blockers["voids"])
			level.max_active_enemies = 1
			var result: Dictionary = validate_level(level, connections, room_kind)
			if bool(result.get("ok", false)):
				return level
		var fallback_boss = _make_base_level(piece, room_id, floor_number, effective_connection_edges)
		_apply_fallback_boss_interior(fallback_boss)
		return fallback_boss
	for attempt in range(MAX_ATTEMPTS):
		var level = _make_base_level(piece, room_id, floor_number, effective_connection_edges)
		var shell_wall_tiles: Array[Rect2] = _get_level_wall_tiles(level)
		var archetype: int = (rng.randi_range(0, 4) + attempt) % 5
		var blockers: Dictionary = _build_obstacles(level, connections, archetype, rng, room_kind, floor_number)
		var generated_wall_tiles: Array[Rect2] = shell_wall_tiles.duplicate()
		generated_wall_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(blockers["walls"]))
		var generated_voids: Array[Rect2] = blockers["voids"]
		_apply_wall_tiles(level, generated_wall_tiles)
		_apply_void_rects(level, generated_voids)
		var generated_spawners: Array[Resource] = _build_spawner_placements(level, room_kind, floor_number, rng)
		level.spawner_placements = generated_spawners
		if level.spawner_placements.size() <= 0:
			continue
		level.destructible_prop_placements = _build_destructible_prop_placements(level, connections, room_kind, floor_number, rng)
		level.max_active_enemies = _get_room_active_enemy_budget(level, room_kind, floor_number)
		var result: Dictionary = validate_level(level, connections, room_kind)
		if bool(result.get("ok", false)):
			return level
	var fallback = _make_base_level(piece, room_id, floor_number, effective_connection_edges)
	var fallback_rng := RandomNumberGenerator.new()
	fallback_rng.seed = _compute_room_seed(room_id, floor_number, floor_seed, String(piece.id)) + 9091
	_apply_fallback_interior(fallback, room_kind, floor_number, fallback_rng)
	return fallback


func validate_level(level, connections: Dictionary, room_kind: String) -> Dictionary:
	if level == null:
		return {"ok": false, "reason": "missing_level"}
	var blockers: Array[Rect2] = _get_movement_blockers(level)
	var clear_points: Array[Vector2] = [_get_room_spawn_position(level)]
	if room_kind == "boss":
		if level.boss_profile == null:
			return {"ok": false, "reason": "missing_boss_profile"}
		if connections.size() != 1:
			return {"ok": false, "reason": "boss_entrance_count"}
		if level.arena_bounds.size.x < 1200.0 or level.arena_bounds.size.y < 760.0:
			return {"ok": false, "reason": "boss_arena_small"}
		clear_points.append(level.boss_spawn_position)
	for direction_key in connections.keys():
		var direction := String(direction_key)
		var opening_rect := _get_connection_opening_rect(level, direction)
		var approach_rect := _get_connection_clear_rect(level, direction)
		for blocker in blockers:
			if opening_rect.size != Vector2.ZERO and blocker.intersects(opening_rect):
				return {"ok": false, "reason": "blocked_door_opening"}
			if blocker.intersects(approach_rect):
				return {"ok": false, "reason": "blocked_door_approach"}
		clear_points.append(_get_connection_entry_position(level, direction))
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
	var start_cell: Vector2i = _nearest_open_cell(_get_room_spawn_position(level), grid["open"], level.arena_bounds)
	if not grid["open"].has(_cell_key(start_cell)):
		return {"ok": false, "reason": "spawn_unreachable"}
	var reachable: Dictionary = _flood_fill(start_cell, grid["open"])
	var has_dodge_pocket := _has_dodge_pocket(reachable)
	if float(reachable.size()) / float(max(grid["open"].size(), 1)) < _get_main_component_threshold(reachable):
		return {"ok": false, "reason": "main_component_small"}
	for point in clear_points:
		var cell := _nearest_open_cell(point, grid["open"], level.arena_bounds)
		if not reachable.has(_cell_key(cell)):
			return {"ok": false, "reason": "required_point_unreachable"}
	if not has_dodge_pocket:
		return {"ok": false, "reason": "missing_dodge_pocket"}
	if room_kind == "boss":
		if not _point_is_clear(level, level.boss_spawn_position, blockers, _get_boss_clearance(level)):
			return {"ok": false, "reason": "boss_spawn_blocked"}
		if level.get_spawner_count() != 0:
			return {"ok": false, "reason": "boss_spawner_budget"}
		return {"ok": true, "reason": ""}
	if _has_heavy_spawner(level) and _count_clear_lanes(level, blockers) < 2:
		return {"ok": false, "reason": "heavy_spawner_lanes"}
	var min_count := _get_spawner_count_bounds(level, room_kind).x
	if level.spawner_placements.size() < min_count:
		return {"ok": false, "reason": "spawner_budget_low"}
	return {"ok": true, "reason": ""}


func _make_base_level(piece, room_id: String, floor_number: int, connection_edges: Dictionary = {}):
	var level = piece.create_level_definition()
	level.id = room_id
	level.display_name = "%s - %s" % [piece.display_name, room_id.capitalize()]
	level.difficulty_label = "Floor %d %s" % [floor_number, String(piece.room_kind).capitalize()]
	level.floor_number = max(floor_number, 1)
	if String(piece.room_kind) == "boss":
		level.boss_spawn_position = ROOM_GEOMETRY_BUILDER.get_spawn_position(piece.footprint_cells)
	level.use_default_spawners = false
	var empty_positions: Array[Vector2] = []
	var empty_placements: Array[Resource] = []
	var empty_props: Array[Resource] = []
	var shell_wall_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(piece.footprint_cells, connection_edges)
	var empty_voids: Array[Rect2] = []
	level.spawner_positions = empty_positions
	level.spawner_placements = empty_placements
	level.destructible_prop_placements = empty_props
	_apply_wall_tiles(level, shell_wall_tiles)
	_apply_void_rects(level, empty_voids)
	level.set_meta("footprint_cells", piece.footprint_cells.duplicate())
	level.set_meta("connection_edges", connection_edges.duplicate())
	return level


func _get_effective_connection_edges(cells: Array[Vector2i], connections: Dictionary, connection_edges: Dictionary) -> Dictionary:
	if not connection_edges.is_empty():
		return connection_edges
	var inferred := {}
	for direction_key in connections.keys():
		var direction := String(direction_key)
		var source_cell := _pick_default_connection_cell(cells, direction)
		inferred[direction] = {
			"source_cell": source_cell,
			"target_cell": Vector2i.ZERO
		}
	return inferred


func _pick_default_connection_cell(cells: Array[Vector2i], direction: String) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var min_cell := ROOM_GEOMETRY_BUILDER.get_min_cell(cells)
	var max_cell := ROOM_GEOMETRY_BUILDER.get_max_cell(cells)
	var candidates: Array[Vector2i] = []
	for cell in cells:
		match direction:
			"north":
				if cell.y == min_cell.y:
					candidates.append(cell)
			"south":
				if cell.y == max_cell.y:
					candidates.append(cell)
			"east":
				if cell.x == max_cell.x:
					candidates.append(cell)
			"west":
				if cell.x == min_cell.x:
					candidates.append(cell)
	if candidates.is_empty():
		return cells[0]
	var best := candidates[0]
	var center := Vector2(float(min_cell.x + max_cell.x) * 0.5, float(min_cell.y + max_cell.y) * 0.5)
	var best_distance := INF
	for cell in candidates:
		var distance := Vector2(float(cell.x), float(cell.y)).distance_squared_to(center)
		if distance < best_distance:
			best = cell
			best_distance = distance
	return best


func _compute_room_seed(room_id: String, floor_number: int, floor_seed: int, piece_id: String) -> int:
	var seed_text := "%d:%d:%s:%s" % [floor_seed, floor_number, room_id, piece_id]
	return abs(seed_text.hash()) + 1


func _build_boss_obstacles(level, connections: Dictionary, rng: RandomNumberGenerator, floor_number: int, attempt: int) -> Dictionary:
	var walls: Array[Rect2] = []
	var voids: Array[Rect2] = []
	var bounds: Rect2 = level.arena_bounds
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	var wall_pair_budget: int = clamp(2 + int(floor_number / 2) + int(attempt % 2), 2, 5)
	var void_pair_budget: int = clamp(1 + int(floor_number / 3), 1, 4)
	_try_add_symmetric_rect_pair(walls, level, connections, walls, voids, center, Vector2(half.x * 0.32, half.y * 0.24), Vector2(1, 2))
	_try_add_symmetric_rect_pair(walls, level, connections, walls, voids, center, Vector2(half.x * 0.32, -half.y * 0.24), Vector2(1, 2))
	var wall_attempts := 0
	while walls.size() < wall_pair_budget * 2 and wall_attempts < 22:
		wall_attempts += 1
		var offset := Vector2(
			rng.randf_range(half.x * 0.18, half.x * 0.48),
			rng.randf_range(-half.y * 0.34, half.y * 0.34)
		)
		if rng.randf() < 0.5:
			offset.y = -offset.y
		var cells := Vector2(rng.randi_range(1, 2), rng.randi_range(1, 2))
		if rng.randf() < 0.35:
			cells = Vector2(2, 1)
		_try_add_symmetric_rect_pair(walls, level, connections, walls, voids, center, offset, cells)
	var void_attempts := 0
	while voids.size() < void_pair_budget * 2 and void_attempts < 18:
		void_attempts += 1
		var offset := Vector2(
			rng.randf_range(half.x * 0.16, half.x * 0.42),
			rng.randf_range(half.y * 0.16, half.y * 0.34)
		)
		if rng.randf() < 0.5:
			offset.y = -offset.y
		var cells := Vector2(rng.randi_range(2, 3), rng.randi_range(1, 2))
		_try_add_symmetric_rect_pair(voids, level, connections, walls, voids, center, offset, cells)
	return {"walls": walls, "voids": voids}


func _try_add_symmetric_rect_pair(target: Array[Rect2], level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2], center: Vector2, offset: Vector2, cells: Vector2) -> bool:
	var first := _rect_at(center + offset, cells)
	var second := _rect_at(center - offset, cells)
	if first == second:
		return false
	var pair: Array[Rect2] = [first, second]
	for index in range(pair.size()):
		var rect := pair[index]
		if not _rect_can_join_obstacles(rect, level, connections, walls, voids):
			return false
		for other_index in range(index):
			if pair[other_index].grow(OBSTACLE_PADDING).intersects(rect):
				return false
	for rect in pair:
		target.append(rect)
	return true


func _rect_can_join_obstacles(rect: Rect2, level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2]) -> bool:
	if not _rect_fits_arena(rect, level):
		return false
	if _rect_hits_reserved_zone(rect, level, connections):
		return false
	var blockers: Array[Rect2] = []
	blockers.append_array(walls)
	blockers.append_array(voids)
	for blocker in blockers:
		if blocker.grow(OBSTACLE_PADDING).intersects(rect):
			return false
	return true


func _build_obstacles(level, connections: Dictionary, archetype: int, rng: RandomNumberGenerator, room_kind: String, floor_number: int) -> Dictionary:
	var walls: Array[Rect2] = []
	var voids: Array[Rect2] = []
	var grid_size := _get_obstacle_grid_size(level.arena_bounds)
	var total_cells: int = max(grid_size.x * grid_size.y, 1)
	var total_budget: int = clamp(int(round(float(total_cells) * 0.055)) + 6 + int(floor_number / 2), 13, 40)
	if room_kind == "challenge":
		total_budget += 4
	match archetype:
		0:
			total_budget -= 3
		1:
			total_budget += 1
		2:
			total_budget += 2
		3:
			total_budget += 4
		_:
			total_budget += 2
	total_budget = clamp(total_budget, 11, 46)
	var wall_budget: int = clamp(int(round(float(total_budget) * rng.randf_range(0.55, 0.68))), 6, total_budget - 4)
	var void_budget: int = max(total_budget - wall_budget, 3)
	if archetype == 3 or rng.randf() < 0.82:
		var boundary_budget: int = min(wall_budget, rng.randi_range(4, max(5, int(wall_budget * 0.62))))
		wall_budget -= _try_add_obstacle_shape(walls, level, connections, walls, voids, grid_size, boundary_budget, true, "mass", rng)
	var wall_attempts := 0
	while wall_budget > 0 and wall_attempts < 24:
		wall_attempts += 1
		var near_boundary := rng.randf() < 0.34
		var shape_kind := "snake"
		if near_boundary and rng.randf() < 0.58:
			shape_kind = "mass"
		elif rng.randf() < 0.24:
			shape_kind = "seed"
		var target_cells: int = min(wall_budget, rng.randi_range(3, 7))
		var added := _try_add_obstacle_shape(walls, level, connections, walls, voids, grid_size, target_cells, near_boundary, shape_kind, rng)
		if added <= 0:
			continue
		wall_budget -= added
	var void_attempts := 0
	while void_budget > 0 and void_attempts < 22:
		void_attempts += 1
		var near_boundary := rng.randf() < 0.34
		var shape_kind := "seed"
		if near_boundary or (not walls.is_empty() and rng.randf() < 0.22):
			shape_kind = "snake"
		elif rng.randf() < 0.36:
			shape_kind = "mass"
		var target_cells: int = min(void_budget, rng.randi_range(3, 8))
		var added := _try_add_obstacle_shape(voids, level, connections, walls, voids, grid_size, target_cells, near_boundary, shape_kind, rng)
		if added <= 0:
			continue
		void_budget -= added
	return {"walls": walls, "voids": voids}


func _try_add_obstacle_shape(target: Array[Rect2], level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2], grid_size: Vector2i, target_cells: int, near_boundary: bool, shape_kind: String, rng: RandomNumberGenerator) -> int:
	for attempt in range(14):
		var cells: Array[Vector2i] = []
		match shape_kind:
			"snake":
				cells = _build_snake_obstacle_cells(level, connections, walls, voids, grid_size, target_cells, near_boundary, rng)
			"seed":
				cells = _build_seed_obstacle_cells(level, connections, walls, voids, grid_size, target_cells, near_boundary, rng)
			_:
				cells = _build_mass_obstacle_cells(level, connections, walls, voids, grid_size, target_cells, near_boundary, rng)
		if cells.is_empty():
			continue
		for cell in cells:
			target.append(_cell_rect(level.arena_bounds, cell))
		return cells.size()
	return 0


func _build_snake_obstacle_cells(level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2], grid_size: Vector2i, target_cells: int, near_boundary: bool, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var used: Dictionary = {}
	var current := _pick_obstacle_start_cell(grid_size, near_boundary, rng)
	var direction := _random_cardinal_direction(rng)
	for step in range(max(target_cells * 10, 20)):
		if _cell_can_join_obstacle(current, level, connections, walls, voids, used, grid_size):
			cells.append(current)
			used[_cell_key(current)] = true
			if cells.size() >= target_cells:
				return cells
		var directions := _get_snake_direction_order(direction, rng)
		var moved := false
		for next_direction in directions:
			var next_cell: Vector2i = current + next_direction
			if _cell_can_join_obstacle(next_cell, level, connections, walls, voids, used, grid_size):
				current = next_cell
				direction = next_direction
				moved = true
				break
		if not moved:
			current = _pick_obstacle_start_cell(grid_size, near_boundary, rng)
			direction = _random_cardinal_direction(rng)
	return cells


func _build_seed_obstacle_cells(level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2], grid_size: Vector2i, target_cells: int, near_boundary: bool, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var used: Dictionary = {}
	var entrance := _pick_obstacle_start_cell(grid_size, near_boundary, rng)
	var outward := _get_seed_outward_direction(entrance, grid_size, rng)
	used[_cell_key(entrance)] = true
	var frontier: Array[Vector2i] = [entrance + outward]
	for step in range(max(target_cells * 16, 28)):
		if frontier.is_empty():
			if cells.is_empty():
				entrance = _pick_obstacle_start_cell(grid_size, near_boundary, rng)
				outward = _get_seed_outward_direction(entrance, grid_size, rng)
				used.clear()
				used[_cell_key(entrance)] = true
				frontier.append(entrance + outward)
				continue
			var anchor: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
			frontier.append(anchor + _random_cardinal_direction(rng))
		var candidate_index := rng.randi_range(0, frontier.size() - 1)
		var candidate: Vector2i = frontier[candidate_index]
		frontier.remove_at(candidate_index)
		if used.has(_cell_key(candidate)):
			continue
		if not _cell_can_join_obstacle(candidate, level, connections, walls, voids, used, grid_size):
			used[_cell_key(candidate)] = true
			continue
		cells.append(candidate)
		used[_cell_key(candidate)] = true
		if cells.size() >= target_cells:
			return cells
		for next_direction in _get_seed_expansion_directions(outward, rng):
			var next_cell := candidate + next_direction
			if used.has(_cell_key(next_cell)):
				continue
			frontier.append(next_cell)
	return cells


func _build_mass_obstacle_cells(level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2], grid_size: Vector2i, target_cells: int, near_boundary: bool, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var used: Dictionary = {}
	var origin := _pick_obstacle_start_cell(grid_size, near_boundary, rng)
	var width := rng.randi_range(2, 4)
	var height := rng.randi_range(2, 3)
	if near_boundary:
		if origin.x <= 2 or origin.x >= grid_size.x - 3:
			width = rng.randi_range(1, 2)
			height = rng.randi_range(3, 5)
		else:
			width = rng.randi_range(3, 5)
			height = rng.randi_range(1, 2)
	var top_left := origin - Vector2i(int(width / 2), int(height / 2))
	for x in range(width):
		for y in range(height):
			if cells.size() >= target_cells:
				break
			var cell := top_left + Vector2i(x, y)
			if not _cell_can_join_obstacle(cell, level, connections, walls, voids, used, grid_size):
				continue
			cells.append(cell)
			used[_cell_key(cell)] = true
	for nub_attempt in range(8):
		if cells.size() >= target_cells or cells.is_empty():
			break
		var anchor: Vector2i = cells[rng.randi_range(0, cells.size() - 1)]
		var candidate: Vector2i = anchor + _random_cardinal_direction(rng)
		if not _cell_can_join_obstacle(candidate, level, connections, walls, voids, used, grid_size):
			continue
		cells.append(candidate)
		used[_cell_key(candidate)] = true
	return cells


func _cell_can_join_obstacle(cell: Vector2i, level, connections: Dictionary, walls: Array[Rect2], voids: Array[Rect2], used: Dictionary, grid_size: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= grid_size.x or cell.y >= grid_size.y:
		return false
	if used.has(_cell_key(cell)):
		return false
	var rect := _cell_rect(level.arena_bounds, cell)
	if not _rect_fits_arena(rect, level):
		return false
	if _rect_hits_reserved_zone(rect, level, connections):
		return false
	var blockers: Array[Rect2] = []
	blockers.append_array(walls)
	blockers.append_array(voids)
	for blocker in blockers:
		if blocker.grow(OBSTACLE_PADDING).intersects(rect):
			return false
	return true


func _pick_obstacle_start_cell(grid_size: Vector2i, near_boundary: bool, rng: RandomNumberGenerator) -> Vector2i:
	if grid_size.x <= 4 or grid_size.y <= 4:
		return Vector2i(rng.randi_range(0, max(grid_size.x - 1, 0)), rng.randi_range(0, max(grid_size.y - 1, 0)))
	if near_boundary:
		var side := rng.randi_range(0, 3)
		match side:
			0:
				return Vector2i(rng.randi_range(1, grid_size.x - 2), rng.randi_range(0, min(2, grid_size.y - 1)))
			1:
				return Vector2i(rng.randi_range(1, grid_size.x - 2), rng.randi_range(max(grid_size.y - 3, 0), grid_size.y - 1))
			2:
				return Vector2i(rng.randi_range(0, min(2, grid_size.x - 1)), rng.randi_range(1, grid_size.y - 2))
			_:
				return Vector2i(rng.randi_range(max(grid_size.x - 3, 0), grid_size.x - 1), rng.randi_range(1, grid_size.y - 2))
	return Vector2i(rng.randi_range(2, grid_size.x - 3), rng.randi_range(2, grid_size.y - 3))


func _get_obstacle_grid_size(bounds: Rect2) -> Vector2i:
	return Vector2i(max(int(floor(bounds.size.x / GRID_SIZE)), 1), max(int(floor(bounds.size.y / GRID_SIZE)), 1))


func _cell_rect(bounds: Rect2, cell: Vector2i) -> Rect2:
	return Rect2(bounds.position + Vector2(float(cell.x), float(cell.y)) * GRID_SIZE, Vector2(GRID_SIZE, GRID_SIZE))


func _random_cardinal_direction(rng: RandomNumberGenerator) -> Vector2i:
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	return directions[rng.randi_range(0, directions.size() - 1)]


func _get_seed_outward_direction(entrance: Vector2i, grid_size: Vector2i, rng: RandomNumberGenerator) -> Vector2i:
	var distances := {
		Vector2i(0, 1): entrance.y,
		Vector2i(0, -1): grid_size.y - 1 - entrance.y,
		Vector2i(1, 0): entrance.x,
		Vector2i(-1, 0): grid_size.x - 1 - entrance.x
	}
	var best_direction := _random_cardinal_direction(rng)
	var best_distance := 9999
	for direction in distances.keys():
		var distance: int = int(distances[direction])
		if distance < best_distance:
			best_distance = distance
			best_direction = direction
	return best_direction


func _get_seed_expansion_directions(outward: Vector2i, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var left := Vector2i(-outward.y, outward.x)
	var right := Vector2i(outward.y, -outward.x)
	var backward := -outward
	var directions: Array[Vector2i] = [outward, left, right, outward, left, right, backward]
	if rng.randf() < 0.5:
		var value := directions[1]
		directions[1] = directions[2]
		directions[2] = value
	if rng.randf() < 0.25:
		directions.append(left)
		directions.append(right)
	return directions


func _get_snake_direction_order(direction: Vector2i, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var left := Vector2i(-direction.y, direction.x)
	var right := Vector2i(direction.y, -direction.x)
	var backward := -direction
	var directions: Array[Vector2i] = [direction, left, right, backward]
	if rng.randf() < 0.45:
		directions[0] = left
		directions[1] = direction
	if rng.randf() < 0.35:
		var value := directions[1]
		directions[1] = directions[2]
		directions[2] = value
	return directions


func _rect_at(center: Vector2, cells: Vector2) -> Rect2:
	var size := Vector2(float(cells.x) * GRID_SIZE, float(cells.y) * GRID_SIZE)
	var approximate_top_left := center - size * 0.5
	var snapped_top_left := Vector2(round(approximate_top_left.x / GRID_SIZE) * GRID_SIZE, round(approximate_top_left.y / GRID_SIZE) * GRID_SIZE)
	return Rect2(snapped_top_left, size)


func _rect_fits_arena(rect: Rect2, level) -> bool:
	if not _rect_fits_level_envelope(rect, level):
		return false
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
		Rect2(_get_room_spawn_position(level) - Vector2(180.0, 140.0), Vector2(360.0, 280.0))
	]
	if level.boss_profile != null:
		var boss_clearance := _get_boss_clearance(level) + 72.0
		reserved.append(Rect2(level.boss_spawn_position - Vector2(boss_clearance, boss_clearance), Vector2(boss_clearance * 2.0, boss_clearance * 2.0)))
	for direction_key in connections.keys():
		var direction := String(direction_key)
		var opening_rect := _get_connection_opening_rect(level, direction)
		if opening_rect.size != Vector2.ZERO:
			reserved.append(opening_rect)
		reserved.append(_get_connection_clear_rect(level, direction))
	for zone in reserved:
		if zone.intersects(rect):
			return true
	return false


func _get_boss_clearance(level) -> float:
	if level.boss_profile == null:
		return PLAYER_CLEARANCE
	return max(float(level.boss_profile.body_radius) + 34.0, 96.0)


func _build_spawner_placements(level, room_kind: String, floor_number: int, rng: RandomNumberGenerator) -> Array[Resource]:
	var profiles: Array[Resource] = _build_spawner_profile_budget(room_kind, floor_number, rng, _get_level_cell_count(level))
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


func _build_destructible_prop_placements(level, connections: Dictionary, room_kind: String, floor_number: int, rng: RandomNumberGenerator) -> Array[Resource]:
	var placements: Array[Resource] = []
	if room_kind != "combat" and room_kind != "challenge":
		return placements
	var cell_count: int = _get_level_cell_count(level)
	var target_count: int = _get_destructible_prop_budget(cell_count, room_kind, floor_number, rng)
	var chest_chance: float = clamp(0.08 + float(cell_count) * 0.025 + float(floor_number) * 0.006, 0.1, 0.22)
	var chest_pending := target_count >= 3 and rng.randf() < chest_chance
	var candidate_points := _build_prop_candidate_points(level.arena_bounds, rng)
	var blockers: Array[Rect2] = _get_wall_void_blockers(level)
	for point in candidate_points:
		if placements.size() >= target_count:
			break
		var prop_kind := "crate"
		if chest_pending and placements.size() >= 1 and rng.randf() < 0.34:
			prop_kind = "chest"
			chest_pending = false
		var placement = _make_prop_placement(point, prop_kind)
		if not _prop_placement_is_clear(level, placement, connections, blockers, placements):
			continue
		placements.append(placement)
	if chest_pending and placements.size() < target_count + 1:
		for point in candidate_points:
			var chest = _make_prop_placement(point, "chest")
			if not _prop_placement_is_clear(level, chest, connections, blockers, placements):
				continue
			placements.append(chest)
			break
	return placements


func _get_destructible_prop_budget(cell_count: int, room_kind: String, floor_number: int, rng: RandomNumberGenerator) -> int:
	var min_count := 2
	var max_count := 3
	if cell_count == 2:
		min_count = 3
		max_count = 5
	elif cell_count == 3:
		min_count = 4
		max_count = 6
	elif cell_count == 4:
		min_count = 5
		max_count = 7
	elif cell_count >= 5:
		min_count = 6
		max_count = 8
	if room_kind == "challenge":
		max_count += 1
	var floor_bonus: int = clamp(int(floor(float(max(floor_number - 1, 0)) / 3.0)), 0, 2)
	return clamp(rng.randi_range(min_count, max_count) + floor_bonus, min_count, max_count + floor_bonus)


func _make_prop_placement(position: Vector2, prop_kind: String):
	var placement = DESTRUCTIBLE_PROP_PLACEMENT_SCRIPT.new()
	placement.position = position
	placement.prop_kind = prop_kind
	match prop_kind:
		"chest":
			placement.size = Vector2(54.0, 42.0)
			placement.max_health = 5
			placement.score_value = 4
			placement.drop_kind = "treasure"
		_:
			placement.size = Vector2(48.0, 48.0)
			placement.max_health = 3
			placement.score_value = 1
			placement.drop_kind = "minor"
	return placement


func _prop_placement_is_clear(level, placement, connections: Dictionary, blockers: Array[Rect2], placements: Array[Resource]) -> bool:
	var rect := _prop_rect(placement)
	if not _rect_fits_arena(rect, level):
		return false
	if _rect_hits_reserved_zone(rect.grow(42.0), level, connections):
		return false
	for blocker in blockers:
		if blocker.grow(12.0).intersects(rect):
			return false
	for spawner in level.spawner_placements:
		if spawner != null and rect.grow(SPAWNER_CLEARANCE).has_point(spawner.position):
			return false
	for existing in placements:
		if _prop_rect(existing).grow(28.0).intersects(rect):
			return false
	return true


func _build_prop_candidate_points(bounds: Rect2, rng: RandomNumberGenerator) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var cols: int = max(int(floor(bounds.size.x / GRID_SIZE)), 1)
	var rows: int = max(int(floor(bounds.size.y / GRID_SIZE)), 1)
	for x in range(1, max(cols - 1, 1)):
		for y in range(1, max(rows - 1, 1)):
			if rng.randf() > 0.55:
				continue
			points.append(_cell_center(bounds, Vector2i(x, y)))
	for index in range(points.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := points[index]
		points[index] = points[swap_index]
		points[swap_index] = value
	return points


func _build_spawner_profile_budget(room_kind: String, floor_number: int, rng: RandomNumberGenerator, cell_count: int = 2) -> Array[Resource]:
	var count_bounds := _get_spawner_count_bounds_for_cells(cell_count, room_kind)
	var min_count := count_bounds.x
	var max_count := count_bounds.y
	var budget: int = min_count * 3 + max(floor_number - 1, 0) * (2 if room_kind == "challenge" else 1)
	if cell_count >= 5:
		budget += 8
	elif cell_count >= 4:
		budget += 5
	var profiles: Array[Resource] = []
	var options := _get_spawner_options(floor_number)
	var minimum_cost := _get_min_spawner_cost(options)
	while profiles.size() < min_count and budget >= minimum_cost:
		var remaining_required_slots: int = min_count - profiles.size() - 1
		var max_affordable_cost: int = budget - remaining_required_slots * minimum_cost
		var option: Dictionary = _choose_weighted_spawner_option(options, max_affordable_cost, rng)
		if option.is_empty():
			break
		profiles.append(option["profile"])
		budget -= int(option["cost"])
	budget = _ensure_profile_variety(profiles, budget, options, rng)
	while profiles.size() < max_count:
		var selected: Dictionary = _choose_weighted_spawner_option(options, budget, rng)
		if selected.is_empty():
			break
		profiles.append(selected["profile"])
		budget -= int(selected["cost"])
	return profiles


func _get_spawner_count_bounds(level, room_kind: String) -> Vector2i:
	return _get_spawner_count_bounds_for_cells(_get_level_cell_count(level), room_kind)


func _get_spawner_count_bounds_for_cells(cell_count: int, room_kind: String) -> Vector2i:
	if room_kind == "boss":
		return Vector2i(0, 0)
	if cell_count <= 1:
		return Vector2i(2, 3)
	if cell_count == 2:
		return Vector2i(4, 5)
	if cell_count == 3:
		return Vector2i(5, 6)
	if cell_count == 4:
		return Vector2i(6, 8)
	return Vector2i(8, 10)


func _get_level_cell_count(level) -> int:
	if level != null and level.has_meta("footprint_cells"):
		var cells: Array = level.get_meta("footprint_cells")
		return max(cells.size(), 1)
	return 1


func _get_room_active_enemy_budget(level, room_kind: String, floor_number: int) -> int:
	if room_kind == "boss":
		return 1
	var cell_count: int = _get_level_cell_count(level)
	var base_budget: int = 18 + cell_count * 5 + level.spawner_placements.size() * 2
	if cell_count >= 5:
		base_budget += 8
	elif room_kind == "challenge":
		base_budget += 4
	return clamp(base_budget + floor_number * 3, 24, 60)


func _get_room_spawn_position(level) -> Vector2:
	return ROOM_GEOMETRY_BUILDER.get_spawn_position(_get_level_footprint_cells(level))


func _apply_wall_tiles(level, wall_tiles: Array[Rect2]) -> void:
	wall_tiles = _filter_rects_to_level_envelope(level, wall_tiles)
	level.set_meta("wall_tile_rects", wall_tiles)
	level.wall_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(wall_tiles)


func _apply_void_rects(level, void_rects: Array[Rect2]) -> void:
	var void_tiles := ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(void_rects)
	void_tiles = _filter_rects_to_level_envelope(level, void_tiles)
	level.set_meta("void_tile_rects", void_tiles)
	level.void_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(void_tiles)


func _filter_rects_to_level_envelope(level, rects: Array[Rect2]) -> Array[Rect2]:
	if level == null or not level.has_meta("footprint_cells"):
		return rects.duplicate()
	var filtered: Array[Rect2] = []
	for rect in rects:
		if _rect_fits_level_envelope(rect, level):
			filtered.append(rect)
	return filtered


func _get_level_wall_tiles(level) -> Array[Rect2]:
	if level != null and level.has_meta("wall_tile_rects"):
		var typed_tiles: Array[Rect2] = []
		for rect in level.get_meta("wall_tile_rects"):
			typed_tiles.append(rect)
		return typed_tiles
	return ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(level.wall_rects)


func _get_spawner_options(floor_number: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var floor_pressure_bonus: int = max(floor_number - 1, 0)
	options.append({"profile": BASIC_SPAWNER, "cost": 3, "weight": 6})
	options.append({"profile": FAST_SPAWNER, "cost": 3, "weight": 5})
	options.append({"profile": SHOOTER_SPAWNER, "cost": 4, "weight": 3 + int(floor_pressure_bonus / 2)})
	options.append({"profile": TANK_SPAWNER, "cost": 5, "weight": 2 + int(floor_pressure_bonus / 3)})
	return options


func _choose_weighted_spawner_option(options: Array[Dictionary], budget: int, rng: RandomNumberGenerator) -> Dictionary:
	var affordable: Array[Dictionary] = []
	var total_weight := 0
	for option in options:
		if int(option.get("cost", 999)) > budget:
			continue
		affordable.append(option)
		total_weight += max(int(option.get("weight", 1)), 1)
	if affordable.is_empty():
		return {}
	var roll := rng.randi_range(1, total_weight)
	for option in affordable:
		roll -= max(int(option.get("weight", 1)), 1)
		if roll <= 0:
			return option
	return affordable[affordable.size() - 1]


func _get_min_spawner_cost(options: Array[Dictionary]) -> int:
	var minimum_cost := 999
	for option in options:
		minimum_cost = min(minimum_cost, int(option.get("cost", 999)))
	return minimum_cost


func _ensure_profile_variety(profiles: Array[Resource], remaining_budget: int, options: Array[Dictionary], rng: RandomNumberGenerator) -> int:
	if profiles.is_empty() or not _profiles_are_all_basic(profiles):
		return remaining_budget
	var basic_cost := _get_spawner_option_cost(options, BASIC_SPAWNER)
	var replacement_options: Array[Dictionary] = []
	var total_weight := 0
	for option in options:
		if option.get("profile", null) == BASIC_SPAWNER:
			continue
		var cost_delta: int = int(option.get("cost", basic_cost)) - basic_cost
		if cost_delta > remaining_budget:
			continue
		replacement_options.append(option)
		total_weight += max(int(option.get("weight", 1)), 1)
	if replacement_options.is_empty():
		return remaining_budget
	var roll := rng.randi_range(1, total_weight)
	var selected: Dictionary = replacement_options[replacement_options.size() - 1]
	for option in replacement_options:
		roll -= max(int(option.get("weight", 1)), 1)
		if roll <= 0:
			selected = option
			break
	var replace_index := rng.randi_range(0, profiles.size() - 1)
	profiles[replace_index] = selected["profile"]
	return remaining_budget - (int(selected["cost"]) - basic_cost)


func _profiles_are_all_basic(profiles: Array[Resource]) -> bool:
	for profile in profiles:
		if profile != BASIC_SPAWNER:
			return false
	return true


func _get_spawner_option_cost(options: Array[Dictionary], profile: Resource) -> int:
	for option in options:
		if option.get("profile", null) == profile:
			return int(option.get("cost", 999))
	return 999


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
	var shell_wall_tiles: Array[Rect2] = _get_level_wall_tiles(level)
	var fallback_wall_tiles := shell_wall_tiles.duplicate()
	fallback_wall_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(fallback_walls))
	_apply_wall_tiles(level, fallback_wall_tiles)
	_apply_void_rects(level, fallback_voids)
	var min_count := _get_spawner_count_bounds(level, room_kind).x
	var profiles := _build_spawner_profile_budget(room_kind, floor_number, rng, _get_level_cell_count(level))
	while profiles.size() > min_count:
		profiles.pop_back()
	var fallback_placements: Array[Resource] = []
	level.spawner_placements = fallback_placements
	var points := _build_fallback_spawner_points(bounds, 7)
	var selected_points := _select_fallback_spawner_points(level, points, min_count)
	if selected_points.size() < min_count:
		_apply_wall_tiles(level, fallback_wall_tiles.duplicate())
		selected_points = _select_fallback_spawner_points(level, points, min_count)
	for index in range(min_count):
		var placement = SPAWNER_PLACEMENT_SCRIPT.new()
		placement.position = selected_points[index] if index < selected_points.size() else _get_room_spawn_position(level)
		placement.profile = profiles[index] if index < profiles.size() else BASIC_SPAWNER
		placement.warmup_seconds = 1.0 + float(index) * 0.45
		level.spawner_placements.append(placement)
	level.max_active_enemies = _get_room_active_enemy_budget(level, room_kind, floor_number)


func _apply_fallback_boss_interior(level) -> void:
	var bounds: Rect2 = level.arena_bounds
	var center := bounds.get_center()
	var fallback_walls: Array[Rect2] = [
		_rect_at(center + Vector2(0.0, -bounds.size.y * 0.24), Vector2(2, 1)),
		_rect_at(center + Vector2(0.0, bounds.size.y * 0.24), Vector2(2, 1)),
		_rect_at(center + Vector2(-bounds.size.x * 0.28, 0.0), Vector2(1, 2)),
		_rect_at(center + Vector2(bounds.size.x * 0.28, 0.0), Vector2(1, 2))
	]
	var fallback_voids: Array[Rect2] = []
	var empty_spawners: Array[Resource] = []
	var empty_positions: Array[Vector2] = []
	var shell_wall_tiles: Array[Rect2] = _get_level_wall_tiles(level)
	var fallback_wall_tiles := shell_wall_tiles.duplicate()
	fallback_wall_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(fallback_walls))
	_apply_wall_tiles(level, fallback_wall_tiles)
	_apply_void_rects(level, fallback_voids)
	level.spawner_placements = empty_spawners
	level.spawner_positions = empty_positions
	level.max_active_enemies = 1


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
	var blockers := _get_wall_void_blockers(level)
	blockers.append_array(_get_prop_blocker_rects(level))
	return blockers


func _get_wall_void_blockers(level) -> Array[Rect2]:
	var blockers: Array[Rect2] = []
	blockers.append_array(level.wall_rects)
	blockers.append_array(level.void_rects)
	return blockers


func _get_prop_blocker_rects(level) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for placement in level.destructible_prop_placements:
		if placement != null:
			rects.append(_prop_rect(placement))
	return rects


func _prop_rect(placement) -> Rect2:
	if placement == null:
		return Rect2()
	return Rect2(placement.position - placement.size * 0.5, placement.size)


func _point_is_clear(level, point: Vector2, blockers: Array[Rect2], clearance: float) -> bool:
	if not _point_is_in_level_envelope(level, point):
		return false
	if not ArenaGeometry.contains_point(point, level.arena_bounds, int(level.arena_shape)):
		return false
	for blocker in blockers:
		if blocker.grow(clearance).has_point(point):
			return false
	return true


func _rect_fits_level_envelope(rect: Rect2, level) -> bool:
	if level == null or not level.has_meta("footprint_cells"):
		return true
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return false
	var inset: float = min(1.0, min(rect.size.x, rect.size.y) * 0.25)
	var points := [
		rect.position + Vector2(inset, inset),
		rect.position + Vector2(rect.size.x - inset, inset),
		rect.position + rect.size - Vector2(inset, inset),
		rect.position + Vector2(inset, rect.size.y - inset),
		rect.get_center()
	]
	for point in points:
		if not _point_is_in_level_envelope(level, point):
			return false
	return true


func _point_is_in_level_envelope(level, point: Vector2) -> bool:
	if level == null or not level.has_meta("footprint_cells"):
		return true
	var epsilon := 0.5
	var cells: Array[Vector2i] = _get_level_footprint_cells(level)
	for cell in cells:
		var cell_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_cell_rect(cells, cell)
		if point.x >= cell_rect.position.x - epsilon and point.y >= cell_rect.position.y - epsilon and point.x <= cell_rect.position.x + cell_rect.size.x + epsilon and point.y <= cell_rect.position.y + cell_rect.size.y + epsilon:
			return true
	return false


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


func _get_connection_entry_position(level, direction: String) -> Vector2:
	if level != null and level.has_meta("connection_edges") and level.has_meta("footprint_cells"):
		var edges: Dictionary = level.get_meta("connection_edges")
		if edges.has(direction):
			var edge: Dictionary = edges[direction]
			var cells: Array[Vector2i] = _get_level_footprint_cells(level)
			return ROOM_GEOMETRY_BUILDER.get_entry_position(cells, edge.get("source_cell", Vector2i.ZERO), direction)
	return _get_door_entry_position(level.arena_bounds, direction)


func _get_connection_opening_rect(level, direction: String) -> Rect2:
	if level != null and level.has_meta("connection_edges") and level.has_meta("footprint_cells"):
		var edges: Dictionary = level.get_meta("connection_edges")
		if edges.has(direction):
			var edge: Dictionary = edges[direction]
			var cells: Array[Vector2i] = _get_level_footprint_cells(level)
			return ROOM_GEOMETRY_BUILDER.get_opening_rect(cells, edge.get("source_cell", Vector2i.ZERO), direction)
	return Rect2()


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


func _get_connection_clear_rect(level, direction: String) -> Rect2:
	if level != null and level.has_meta("connection_edges") and level.has_meta("footprint_cells"):
		var edges: Dictionary = level.get_meta("connection_edges")
		if edges.has(direction):
			var edge: Dictionary = edges[direction]
			var cells: Array[Vector2i] = _get_level_footprint_cells(level)
			return ROOM_GEOMETRY_BUILDER.get_door_clear_rect(cells, edge.get("source_cell", Vector2i.ZERO), direction)
	return _get_door_clear_rect(level.arena_bounds, direction)


func _get_level_footprint_cells(level) -> Array[Vector2i]:
	var typed_cells: Array[Vector2i] = []
	if level != null and level.has_meta("footprint_cells"):
		for cell in level.get_meta("footprint_cells"):
			typed_cells.append(cell)
	if typed_cells.is_empty():
		typed_cells.append(Vector2i.ZERO)
	return typed_cells


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


func _get_main_component_threshold(reachable: Dictionary) -> float:
	if _has_large_dodge_pocket(reachable):
		return 0.38
	if _has_dodge_pocket(reachable):
		return 0.45
	return 0.55


func _has_large_dodge_pocket(reachable: Dictionary) -> bool:
	for key in reachable.keys():
		var origin: Vector2i = reachable[key]
		if _rect_cells_reachable(origin, Vector2i(8, 5), reachable) or _rect_cells_reachable(origin, Vector2i(5, 8), reachable):
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
