extends Node
class_name DungeonManager

signal dungeon_generated(room_count: int)
signal room_changed(room_id: String)

const START_PIECE := preload("res://resources/rooms/start_square.tres")
const WIDE_PIECE := preload("res://resources/rooms/combat_wide.tres")
const TALL_PIECE := preload("res://resources/rooms/combat_tall.tres")
const L_PIECE := preload("res://resources/rooms/combat_l_room.tres")
const T_PIECE := preload("res://resources/rooms/combat_t_room.tres")
const RING_PIECE := preload("res://resources/rooms/combat_ring.tres")
const HOURGLASS_PIECE := preload("res://resources/rooms/combat_hourglass.tres")
const CROSSROADS_PIECE := preload("res://resources/rooms/combat_crossroads.tres")
const TREASURE_PIECE := preload("res://resources/rooms/treasure_nook.tres")
const CHALLENGE_PIECE := preload("res://resources/rooms/challenge_zigzag.tres")
const BOSS_PIECE := preload("res://resources/rooms/boss_chamber.tres")
const ROOM_INTERIOR_GENERATOR_SCRIPT := preload("res://scripts/resources/room_interior_generator.gd")
const SPAWNER_PLACEMENT_SCRIPT := preload("res://scripts/resources/spawner_placement.gd")
const BASIC_SPAWNER := preload("res://resources/spawners/basic_spawner.tres")
const FAST_SPAWNER := preload("res://resources/spawners/fast_spawner.tres")
const SHOOTER_SPAWNER := preload("res://resources/spawners/shooter_spawner.tres")
const TANK_SPAWNER := preload("res://resources/spawners/tank_spawner.tres")

const OPPOSITE_DIRECTIONS := {
	"north": "south",
	"south": "north",
	"east": "west",
	"west": "east"
}

const DIRECTION_OFFSETS := {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}

const CARDINAL_DIRECTIONS := ["north", "east", "south", "west"]

const COMBAT_PIECES := [
	WIDE_PIECE,
	TALL_PIECE,
	L_PIECE,
	T_PIECE,
	RING_PIECE,
	HOURGLASS_PIECE,
	CROSSROADS_PIECE
]

var enabled: bool = false
var current_room_id: String = ""
var floor_number: int = 1
var run_seed: int = 0
var floor_generation_seed: int = 0
var _rooms: Dictionary = {}
var _room_order: Array[String] = []
var _occupied_cells: Dictionary = {}
var _interior_generator = ROOM_INTERIOR_GENERATOR_SCRIPT.new()


func initialize(_context: Dictionary) -> void:
	pass


func reset_run(generation_floor: int = 1, generation_seed: int = 0) -> void:
	floor_number = max(generation_floor, 1)
	run_seed = max(generation_seed, 0)
	_generate_layout()


func set_enabled(value: bool) -> void:
	enabled = value


func get_current_level_definition():
	var state := get_current_room_state()
	if state.is_empty():
		return null
	if state.has("level_definition") and state["level_definition"] != null:
		return state["level_definition"]
	var piece = state["piece"]
	var level = piece.create_level_definition()
	level.id = String(state["id"])
	level.display_name = "%s - %s" % [piece.display_name, String(state["id"]).capitalize()]
	level.difficulty_label = "Floor %d %s" % [floor_number, piece.room_kind.capitalize()]
	level.floor_number = max(floor_number, 1)
	_apply_floor_scaling(level, String(piece.room_kind))
	return level


func get_current_room_state() -> Dictionary:
	if current_room_id.is_empty() or not _rooms.has(current_room_id):
		return {}
	return _rooms[current_room_id]


func get_current_door_infos() -> Array:
	var state := get_current_room_state()
	if state.is_empty():
		return []
	var connections: Dictionary = state["connections"]
	var ordered_directions := ["north", "east", "south", "west"]
	var door_infos: Array = []
	for direction in ordered_directions:
		if connections.has(direction):
			door_infos.append({
				"direction": direction,
				"target_room_id": String(connections[direction])
			})
	return door_infos


func is_current_room_cleared() -> bool:
	var state := get_current_room_state()
	return not state.is_empty() and bool(state["cleared"])


func is_current_boss_room() -> bool:
	var state := get_current_room_state()
	if state.is_empty():
		return false
	return String(state["piece"].room_kind) == "boss"


func mark_current_room_cleared() -> bool:
	if current_room_id.is_empty() or not _rooms.has(current_room_id):
		return false
	var state: Dictionary = _rooms[current_room_id]
	if bool(state["cleared"]):
		return false
	state["cleared"] = true
	_rooms[current_room_id] = state
	return true


func can_enter_direction(direction: String) -> bool:
	var state := get_current_room_state()
	if state.is_empty() or not bool(state["cleared"]):
		return false
	return Dictionary(state["connections"]).has(direction)


func enter_direction(direction: String) -> bool:
	if not enabled or not can_enter_direction(direction):
		return false
	var state := get_current_room_state()
	var connections: Dictionary = state["connections"]
	current_room_id = String(connections[direction])
	_reveal_room(current_room_id)
	room_changed.emit(current_room_id)
	return true


func get_minimap_rooms() -> Array:
	var room_infos: Array = []
	for room_id in _room_order:
		var state: Dictionary = _rooms[room_id]
		var piece = state["piece"]
		room_infos.append({
			"id": room_id,
			"kind": String(piece.room_kind),
			"anchor": state["anchor"],
			"footprint_cells": piece.footprint_cells.duplicate(),
			"connections": Dictionary(state["connections"]).duplicate(),
			"cleared": bool(state["cleared"]),
			"revealed": bool(state["revealed"])
		})
	return room_infos


func get_revealed_room_count() -> int:
	var count := 0
	for room_id in _room_order:
		var state: Dictionary = _rooms[room_id]
		if bool(state["revealed"]):
			count += 1
	return count


func get_minimap_text() -> String:
	var lines: Array[String] = []
	for room_id in _room_order:
		var state: Dictionary = _rooms[room_id]
		var piece = state["piece"]
		var marker := "*" if room_id == current_room_id else " "
		var status := "clear" if bool(state["cleared"]) else "sealed"
		lines.append("%s %s  %s" % [marker, piece.display_name, status])
	return "\n".join(lines)


func get_room_count() -> int:
	return _rooms.size()


func get_occupied_cell_count() -> int:
	return _occupied_cells.size()


func get_room_ids() -> Array[String]:
	return _room_order.duplicate()


func get_run_seed() -> int:
	return run_seed


func get_floor_generation_seed() -> int:
	return floor_generation_seed


func _generate_layout() -> void:
	_rooms.clear()
	_room_order.clear()
	_occupied_cells.clear()
	current_room_id = ""
	var rng := RandomNumberGenerator.new()
	floor_generation_seed = _compute_floor_generation_seed()
	rng.seed = floor_generation_seed
	_place_room("start", START_PIECE, Vector2i.ZERO, true)
	var path_room_ids := _build_boss_path(rng)
	_try_place_required_branch("treasure_1", TREASURE_PIECE, path_room_ids, rng)
	if not _try_place_connected_any_direction("start", "challenge_1", CHALLENGE_PIECE, rng):
		_try_place_required_branch("challenge_1", CHALLENGE_PIECE, path_room_ids, rng)
	_fill_optional_branches(path_room_ids, rng)
	_generate_room_interiors()
	current_room_id = "start"
	_reveal_room(current_room_id)
	dungeon_generated.emit(_rooms.size())
	room_changed.emit(current_room_id)


func _compute_floor_generation_seed() -> int:
	if run_seed <= 0:
		return 1907 + floor_number * 7919
	var seed_text := "%d:%d" % [run_seed, floor_number]
	return abs(seed_text.hash()) + 1


func _build_boss_path(rng: RandomNumberGenerator) -> Array[String]:
	var path_room_ids: Array[String] = ["start"]
	var current_id := "start"
	var path_direction := _shuffled_cardinal_directions(rng)[0]
	var path_room_count: int = clamp(2 + int((floor_number - 1) / 2), 2, 5)
	for index in range(path_room_count):
		var room_id := "path_%d" % (index + 1)
		var piece = _choose_combat_piece(rng, index)
		if not _try_place_connected_from_candidates(current_id, _get_path_candidate_directions(path_direction, rng), room_id, piece):
			piece = WIDE_PIECE
			if not _try_place_connected_from_candidates(current_id, _get_path_candidate_directions(path_direction, rng), room_id, piece):
				break
		path_room_ids.append(room_id)
		current_id = room_id
	if not _try_place_connected(current_id, path_direction, "boss", BOSS_PIECE):
		for room_id in path_room_ids.duplicate():
			if room_id == "start":
				continue
			if _try_place_connected(room_id, path_direction, "boss", BOSS_PIECE):
				break
	return path_room_ids


func _try_place_required_branch(room_id: String, piece, parent_ids: Array[String], rng: RandomNumberGenerator) -> bool:
	for attempt in range(18):
		var parent_id := parent_ids[rng.randi_range(0, parent_ids.size() - 1)]
		var directions := _shuffled_cardinal_directions(rng)
		for direction in directions:
			if _try_place_connected(parent_id, direction, room_id, piece):
				return true
	return false


func _fill_optional_branches(path_room_ids: Array[String], rng: RandomNumberGenerator) -> void:
	var target_room_count: int = clamp(7 + floor_number, 8, 13)
	var branch_index := 1
	var attempts := 0
	while _rooms.size() < target_room_count and attempts < 80:
		attempts += 1
		var parent_ids := _get_branch_parent_ids(path_room_ids)
		if parent_ids.is_empty():
			return
		var parent_id := parent_ids[rng.randi_range(0, parent_ids.size() - 1)]
		var piece = _choose_branch_piece(rng, branch_index)
		var room_id := "branch_%d" % branch_index
		for direction in _shuffled_cardinal_directions(rng):
			if _try_place_connected(parent_id, direction, room_id, piece):
				branch_index += 1
				break


func _get_branch_parent_ids(path_room_ids: Array[String]) -> Array[String]:
	var parent_ids: Array[String] = []
	for room_id in path_room_ids:
		if _rooms.has(room_id):
			parent_ids.append(room_id)
	for room_id in _room_order:
		if room_id.begins_with("branch_") and _rooms.has(room_id):
			parent_ids.append(room_id)
	return parent_ids


func _try_place_connected(parent_id: String, direction: String, room_id: String, piece) -> bool:
	if not _rooms.has(parent_id) or _rooms.has(room_id):
		return false
	var parent_state: Dictionary = _rooms[parent_id]
	var parent_piece = parent_state["piece"]
	var parent_connections: Dictionary = parent_state["connections"]
	var opposite := String(OPPOSITE_DIRECTIONS.get(direction, ""))
	if opposite.is_empty() or parent_connections.has(direction):
		return false
	if not _piece_allows_connector(parent_piece, direction) or not _piece_allows_connector(piece, opposite):
		return false
	var base_anchor := _get_adjacent_anchor(parent_state, piece, direction)
	for offset in _get_solver_offsets(direction):
		var candidate_anchor := base_anchor + offset
		if _can_place_connected(piece, candidate_anchor, parent_id, direction):
			_place_room(room_id, piece, candidate_anchor)
			_connect_rooms(parent_id, direction, room_id)
			return true
	return false


func _try_place_connected_any_direction(parent_id: String, room_id: String, piece, rng: RandomNumberGenerator) -> bool:
	return _try_place_connected_from_candidates(parent_id, _shuffled_cardinal_directions(rng), room_id, piece)


func _try_place_connected_from_candidates(parent_id: String, directions: Array[String], room_id: String, piece) -> bool:
	for direction in directions:
		if _try_place_connected(parent_id, direction, room_id, piece):
			return true
	return false


func _piece_allows_connector(piece, direction: String) -> bool:
	if piece.has_connector(direction):
		return true
	return String(piece.room_kind) == "boss" and DIRECTION_OFFSETS.has(direction)


func _choose_combat_piece(rng: RandomNumberGenerator, path_index: int):
	var index: int = (rng.randi_range(0, COMBAT_PIECES.size() - 1) + floor_number + path_index) % COMBAT_PIECES.size()
	return COMBAT_PIECES[index]


func _choose_branch_piece(rng: RandomNumberGenerator, branch_index: int):
	if floor_number >= 3 and branch_index % 4 == 0:
		return CHALLENGE_PIECE
	var index: int = rng.randi_range(0, COMBAT_PIECES.size() - 1)
	return COMBAT_PIECES[index]


func _shuffled_cardinal_directions(rng: RandomNumberGenerator) -> Array[String]:
	var directions: Array[String] = []
	for direction in CARDINAL_DIRECTIONS:
		directions.append(String(direction))
	for index in range(directions.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := directions[index]
		directions[index] = directions[swap_index]
		directions[swap_index] = value
	return directions


func _get_path_candidate_directions(primary_direction: String, rng: RandomNumberGenerator) -> Array[String]:
	var directions: Array[String] = [primary_direction]
	var shuffled := _shuffled_cardinal_directions(rng)
	var reverse_direction := String(OPPOSITE_DIRECTIONS.get(primary_direction, ""))
	for direction in shuffled:
		if direction == primary_direction or direction == reverse_direction:
			continue
		directions.append(direction)
	if not reverse_direction.is_empty():
		directions.append(reverse_direction)
	return directions


func _place_room(room_id: String, piece, anchor: Vector2i, cleared_override: bool = false) -> void:
	var initially_cleared := cleared_override or String(piece.room_kind) == "treasure"
	_rooms[room_id] = {
		"id": room_id,
		"piece": piece,
		"anchor": anchor,
		"connections": {},
		"level_definition": null,
		"cleared": initially_cleared,
		"revealed": false
	}
	_room_order.append(room_id)
	for local_cell in piece.footprint_cells:
		var world_cell: Vector2i = anchor + local_cell
		_occupied_cells[_cell_key(world_cell)] = room_id


func _connect_rooms(from_id: String, direction: String, to_id: String) -> void:
	var opposite := String(OPPOSITE_DIRECTIONS.get(direction, ""))
	var from_state: Dictionary = _rooms[from_id]
	var to_state: Dictionary = _rooms[to_id]
	var from_connections: Dictionary = from_state["connections"]
	var to_connections: Dictionary = to_state["connections"]
	from_connections[direction] = to_id
	to_connections[opposite] = from_id
	from_state["connections"] = from_connections
	to_state["connections"] = to_connections
	_rooms[from_id] = from_state
	_rooms[to_id] = to_state


func _get_adjacent_anchor(parent_state: Dictionary, child_piece, direction: String) -> Vector2i:
	var parent_anchor: Vector2i = parent_state["anchor"]
	var parent_piece = parent_state["piece"]
	var parent_min: Vector2i = parent_piece.get_min_cell()
	var parent_max: Vector2i = parent_piece.get_max_cell()
	var child_min: Vector2i = child_piece.get_min_cell()
	var child_max: Vector2i = child_piece.get_max_cell()
	match direction:
		"east":
			return Vector2i(parent_anchor.x + parent_max.x + 1 - child_min.x, parent_anchor.y + parent_min.y - child_min.y)
		"west":
			return Vector2i(parent_anchor.x + parent_min.x - 1 - child_max.x, parent_anchor.y + parent_min.y - child_min.y)
		"south":
			return Vector2i(parent_anchor.x + parent_min.x - child_min.x, parent_anchor.y + parent_max.y + 1 - child_min.y)
		"north":
			return Vector2i(parent_anchor.x + parent_min.x - child_min.x, parent_anchor.y + parent_min.y - 1 - child_max.y)
	return parent_anchor


func _get_solver_offsets(direction: String) -> Array[Vector2i]:
	var scalar_offsets := [0, -1, 1, -2, 2, -3, 3]
	var offsets: Array[Vector2i] = []
	for offset in scalar_offsets:
		if direction == "east" or direction == "west":
			offsets.append(Vector2i(0, offset))
		else:
			offsets.append(Vector2i(offset, 0))
	return offsets


func _can_place(piece, anchor: Vector2i) -> bool:
	for local_cell in piece.footprint_cells:
		var world_cell: Vector2i = anchor + local_cell
		if _occupied_cells.has(_cell_key(world_cell)):
			return false
	return true


func _can_place_connected(piece, anchor: Vector2i, parent_id: String, parent_to_child_direction: String) -> bool:
	if not _can_place(piece, anchor):
		return false
	var expected_child_to_parent_direction := String(OPPOSITE_DIRECTIONS.get(parent_to_child_direction, ""))
	if expected_child_to_parent_direction.is_empty():
		return false
	var parent_contact_count := 0
	for local_cell in piece.footprint_cells:
		var world_cell: Vector2i = anchor + local_cell
		for direction_key in DIRECTION_OFFSETS.keys():
			var direction := String(direction_key)
			var neighbor_cell: Vector2i = world_cell + DIRECTION_OFFSETS[direction]
			var neighbor_id := String(_occupied_cells.get(_cell_key(neighbor_cell), ""))
			if neighbor_id.is_empty():
				continue
			if neighbor_id != parent_id:
				return false
			if direction != expected_child_to_parent_direction:
				return false
			parent_contact_count += 1
			if parent_contact_count > 1:
				return false
	return parent_contact_count == 1


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _reveal_room(room_id: String) -> void:
	if not _rooms.has(room_id):
		return
	var state: Dictionary = _rooms[room_id]
	state["revealed"] = true
	_rooms[room_id] = state


func _generate_room_interiors() -> void:
	for room_id in _room_order:
		var state: Dictionary = _rooms[room_id]
		var piece = state["piece"]
		var room_kind := String(piece.room_kind)
		var connections: Dictionary = state["connections"]
		var level = null
		if room_kind == "combat" or room_kind == "challenge" or room_kind == "boss":
			level = _interior_generator.generate(piece, String(room_id), floor_number, floor_generation_seed, connections)
		else:
			level = piece.create_level_definition()
			level.id = String(room_id)
			level.display_name = "%s - %s" % [piece.display_name, String(room_id).capitalize()]
			level.difficulty_label = "Floor %d %s" % [floor_number, room_kind.capitalize()]
			level.floor_number = max(floor_number, 1)
			_apply_floor_scaling(level, room_kind)
		state["level_definition"] = level
		_rooms[room_id] = state


func _apply_floor_scaling(level, room_kind: String) -> void:
	level.floor_number = max(floor_number, 1)
	var floor_bonus: int = max(floor_number - 1, 0)
	level.max_active_enemies = min(int(level.max_active_enemies) + floor_bonus * 3, 48)
	var extra_spawner_count := _get_extra_spawner_count(room_kind)
	if extra_spawner_count <= 0:
		return
	var placements: Array = level.spawner_placements.duplicate()
	var candidate_positions := _get_extra_spawner_positions(level.arena_bounds)
	var added := 0
	for candidate in candidate_positions:
		if added >= extra_spawner_count:
			break
		if not ArenaGeometry.contains_point(candidate, level.arena_bounds, int(level.arena_shape)):
			continue
		if not _position_is_clear_of_walls(candidate, level.wall_rects):
			continue
		var placement = SPAWNER_PLACEMENT_SCRIPT.new()
		placement.position = candidate
		placement.profile = _get_floor_spawner_profile(added, room_kind)
		placement.warmup_seconds = 1.5 + float(added) * 0.55
		placements.append(placement)
		added += 1
	level.spawner_placements = placements


func _get_extra_spawner_count(room_kind: String) -> int:
	if room_kind == "start" or room_kind == "treasure":
		return 0
	var count: int = int((floor_number - 1) / 2)
	if room_kind == "challenge" and floor_number >= 3:
		count += 1
	if room_kind == "boss" and floor_number >= 2:
		count += 1
	return clamp(count, 0, 4)


func _get_floor_spawner_profile(index: int, room_kind: String):
	if room_kind == "boss" and floor_number >= 4 and index % 3 == 0:
		return TANK_SPAWNER
	if floor_number >= 3 and index % 2 == 1:
		return SHOOTER_SPAWNER
	if floor_number >= 2:
		return FAST_SPAWNER
	return BASIC_SPAWNER


func _get_extra_spawner_positions(bounds: Rect2) -> Array[Vector2]:
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	return [
		center + Vector2(-half.x * 0.34, 0.0),
		center + Vector2(half.x * 0.34, 0.0),
		center + Vector2(0.0, -half.y * 0.34),
		center + Vector2(0.0, half.y * 0.34),
		center + Vector2(-half.x * 0.24, -half.y * 0.24),
		center + Vector2(half.x * 0.24, half.y * 0.24)
	]


func _position_is_clear_of_walls(position: Vector2, wall_rects: Array[Rect2]) -> bool:
	for wall_rect in wall_rects:
		if wall_rect.grow(32.0).has_point(position):
			return false
	return true
