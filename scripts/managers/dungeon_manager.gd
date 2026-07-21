extends Node
class_name DungeonManager

signal dungeon_generated(room_count: int)
signal room_changed(room_id: String)

const START_PIECE := preload("res://resources/rooms/start_square.tres")
const CELL_PIECE := preload("res://resources/rooms/combat_cell.tres")
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
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
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
const CAT_START_ROOM_SPAWN_CHANCE := 0.85

const COMBAT_PIECES := [
	CELL_PIECE,
	WIDE_PIECE,
	TALL_PIECE,
	L_PIECE,
	T_PIECE,
	RING_PIECE,
	HOURGLASS_PIECE,
	CROSSROADS_PIECE
]

const COMBAT_PIECES_BY_SIZE := {
	1: [CELL_PIECE],
	2: [WIDE_PIECE, TALL_PIECE],
	3: [L_PIECE, HOURGLASS_PIECE],
	4: [T_PIECE, RING_PIECE],
	5: [CROSSROADS_PIECE]
}

var enabled: bool = false
var current_room_id: String = ""
var floor_number: int = 1
var run_seed: int = 0
var floor_generation_seed: int = 0
var floor_cat_room_id: String = ""
var _rooms: Dictionary = {}
var _room_order: Array[String] = []
var _occupied_cells: Dictionary = {}
var _interior_generator = ROOM_INTERIOR_GENERATOR_SCRIPT.new()
var _large_room_count: int = 0
var _crossroads_placed: bool = false
var _piece_variant_cache: Dictionary = {}
var _floor_cat_room_position: Vector2 = Vector2.ZERO
var _floor_cat_seed: int = 0


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


func get_current_full_floor_level_definition(include_active_contents: bool = true):
	return get_full_floor_level_definition(current_room_id, include_active_contents)


func get_full_floor_level_definition(active_room_id: String = "", include_active_contents: bool = true):
	var room_ids: Array[String] = _get_full_floor_room_ids()
	var level_id: String = "full_floor_%d" % floor_number if active_room_id.is_empty() else "full_floor_%d_%s" % [floor_number, active_room_id]
	var level = _build_floor_level_definition(room_ids, level_id, "Floor %d" % floor_number, "Floor %d Full Map" % floor_number)
	if level == null:
		return null
	level.set_meta("full_floor", true)
	level.set_meta("active_room_id", active_room_id)
	level.set_meta("fog_rects", _get_full_floor_fog_rects(active_room_id, room_ids))
	level.set_meta("visible_bounds", get_full_floor_visible_bounds(active_room_id))
	if not active_room_id.is_empty():
		level.set_meta("active_room_bounds", get_full_floor_room_bounds(active_room_id))
	_apply_visible_floor_destructible_prop_placements(level, active_room_id, room_ids, include_active_contents)
	if include_active_contents:
		_apply_active_room_contents_to_full_floor_level(level, active_room_id, room_ids)
	return level


func remove_destructible_prop_placement(room_id: String, placement) -> bool:
	if room_id.is_empty() or placement == null or not _rooms.has(room_id):
		return false
	var state: Dictionary = _rooms[room_id]
	var room_level: LevelDefinition = state.get("level_definition", null) as LevelDefinition
	if room_level == null or not room_level.destructible_prop_placements.has(placement):
		return false
	room_level.destructible_prop_placements.erase(placement)
	state["level_definition"] = room_level
	_rooms[room_id] = state
	return true


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
			var target_room_id := String(connections[direction])
			var edge := Dictionary(Dictionary(state.get("connection_edges", {})).get(direction, {}))
			var source_cell: Vector2i = edge.get("source_cell", Vector2i.ZERO)
			door_infos.append({
				"direction": direction,
				"target_room_id": target_room_id,
				"target_room_kind": _get_room_kind(target_room_id),
				"trigger_rect": ROOM_GEOMETRY_BUILDER.get_trigger_rect(state["piece"].footprint_cells, source_cell, direction),
				"opening_rect": ROOM_GEOMETRY_BUILDER.get_wall_body_opening_rect(state["piece"].footprint_cells, source_cell, direction),
				"source_cell": source_cell,
				"target_cell": edge.get("target_cell", Vector2i.ZERO)
			})
	return door_infos


func get_current_entry_position(entry_direction: String) -> Vector2:
	return get_room_entry_position(current_room_id, entry_direction)


func get_current_entry_clear_position(entry_direction: String) -> Vector2:
	return get_room_entry_clear_position(current_room_id, entry_direction)


func get_room_entry_position(room_id: String, entry_direction: String) -> Vector2:
	if room_id.is_empty() or not _rooms.has(room_id):
		return Vector2.INF
	var state: Dictionary = _rooms[room_id]
	if state.is_empty() or entry_direction.is_empty():
		return Vector2.INF
	var entry_edge_direction := String(OPPOSITE_DIRECTIONS.get(entry_direction, ""))
	if entry_edge_direction.is_empty():
		return Vector2.INF
	var edge := Dictionary(Dictionary(state.get("connection_edges", {})).get(entry_edge_direction, {}))
	if edge.is_empty():
		return Vector2.INF
	var source_cell: Vector2i = edge.get("source_cell", Vector2i.ZERO)
	return ROOM_GEOMETRY_BUILDER.get_entry_position(state["piece"].footprint_cells, source_cell, entry_edge_direction)


func get_room_entry_clear_position(room_id: String, entry_direction: String) -> Vector2:
	if room_id.is_empty() or not _rooms.has(room_id):
		return Vector2.INF
	var state: Dictionary = _rooms[room_id]
	if state.is_empty() or entry_direction.is_empty():
		return Vector2.INF
	var entry_edge_direction := String(OPPOSITE_DIRECTIONS.get(entry_direction, ""))
	if entry_edge_direction.is_empty():
		return Vector2.INF
	var edge := Dictionary(Dictionary(state.get("connection_edges", {})).get(entry_edge_direction, {}))
	if edge.is_empty():
		return Vector2.INF
	var source_cell: Vector2i = edge.get("source_cell", Vector2i.ZERO)
	return ROOM_GEOMETRY_BUILDER.get_door_clear_rect(state["piece"].footprint_cells, source_cell, entry_edge_direction).get_center()


func get_current_spawn_position() -> Vector2:
	var state := get_current_room_state()
	if state.is_empty():
		return Vector2.ZERO
	return ROOM_GEOMETRY_BUILDER.get_spawn_position(state["piece"].footprint_cells)


func get_current_world_cell_for_position(position: Vector2) -> Dictionary:
	var state := get_current_room_state()
	if state.is_empty():
		return {"ok": false, "cell": Vector2i.ZERO}
	var piece = state["piece"]
	var anchor: Vector2i = state["anchor"]
	var best_cell := Vector2i.ZERO
	var best_distance := INF
	for local_cell in piece.footprint_cells:
		var cell_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_cell_rect(piece.footprint_cells, local_cell)
		var world_cell: Vector2i = anchor + local_cell
		if cell_rect.has_point(position):
			return {"ok": true, "cell": world_cell}
		var distance := cell_rect.get_center().distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best_cell = world_cell
	return {"ok": true, "cell": best_cell}


func is_current_room_cleared() -> bool:
	var state := get_current_room_state()
	return not state.is_empty() and bool(state["cleared"])


func is_room_cleared(room_id: String) -> bool:
	if room_id.is_empty() or not _rooms.has(room_id):
		return false
	var state: Dictionary = _rooms[room_id]
	return bool(state["cleared"])


func is_room_revealed(room_id: String) -> bool:
	if room_id.is_empty() or not _rooms.has(room_id):
		return false
	var state: Dictionary = _rooms[room_id]
	return bool(state["revealed"])


func is_room_cleared_floor_available(room_id: String) -> bool:
	if room_id.is_empty() or not _rooms.has(room_id):
		return false
	var state: Dictionary = _rooms[room_id]
	return _room_is_cleared_floor_available(state)


func get_current_room_kind() -> String:
	var state := get_current_room_state()
	if state.is_empty():
		return ""
	var piece = state.get("piece", null)
	if piece == null:
		return ""
	return String(piece.room_kind)


func get_floor_cat_spawn_info() -> Dictionary:
	if floor_cat_room_id.is_empty():
		return {"ok": false, "room_id": "", "room_position": Vector2.ZERO, "seed": 0}
	return {
		"ok": true,
		"room_id": floor_cat_room_id,
		"room_position": _floor_cat_room_position,
		"seed": _floor_cat_seed
	}


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
	if String(state["piece"].room_kind) != "treasure":
		state["cleared_floor_available"] = true
	_rooms[current_room_id] = state
	return true


func mark_current_room_cleared_floor_available() -> bool:
	if current_room_id.is_empty() or not _rooms.has(current_room_id):
		return false
	var state: Dictionary = _rooms[current_room_id]
	if not bool(state.get("cleared", false)):
		return false
	if bool(state.get("cleared_floor_available", false)):
		return false
	state["cleared_floor_available"] = true
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
	return enter_room(String(connections[direction]))


func enter_room(room_id: String) -> bool:
	if not enabled or room_id.is_empty() or not _rooms.has(room_id):
		return false
	current_room_id = room_id
	_reveal_room(current_room_id)
	room_changed.emit(current_room_id)
	return true


func _build_floor_level_definition(cleared_room_ids: Array[String], level_id: String, display_name: String, difficulty_label: String):
	if cleared_room_ids.is_empty():
		return null
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(cleared_room_ids)
	if floor_cells.is_empty():
		return null
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(cleared_room_ids)
	var level: LevelDefinition = LevelDefinition.new()
	level.id = level_id
	level.display_name = display_name
	level.difficulty_label = difficulty_label
	level.floor_number = max(floor_number, 1)
	level.arena_shape = 0
	level.arena_bounds = ROOM_GEOMETRY_BUILDER.get_bounds(floor_cells)
	level.use_default_spawners = false
	level.max_active_enemies = 0
	var empty_spawners: Array[Resource] = []
	var empty_props: Array[Resource] = []
	var empty_voids: Array[Rect2] = []
	level.spawner_placements = empty_spawners
	level.destructible_prop_placements = empty_props
	level.void_rects = empty_voids
	var wall_top_tiles: Array[Rect2] = _get_cleared_floor_wall_top_tiles(cleared_room_ids, min_world_cell, floor_cells)
	var wall_body_tiles: Array[Rect2] = _get_cleared_floor_wall_tiles(cleared_room_ids, min_world_cell, floor_cells)
	level.wall_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(wall_body_tiles)
	level.set_meta("footprint_cells", floor_cells.duplicate())
	level.set_meta("connection_edges", {})
	level.set_meta("wall_top_tile_rects", wall_top_tiles)
	level.set_meta("wall_body_tile_rects", wall_body_tiles)
	level.set_meta("wall_tile_rects", wall_top_tiles)
	level.set_meta("void_tile_rects", empty_voids)
	return level


func get_full_floor_current_door_infos() -> Array:
	if current_room_id.is_empty():
		return []
	return _get_full_floor_door_infos_for_room(current_room_id)


func get_full_floor_traversal_door_infos() -> Array:
	var source_room_ids: Array[String] = _get_full_floor_visible_room_ids(current_room_id)
	var door_infos: Array = []
	if source_room_ids.is_empty():
		return door_infos
	var room_ids: Array[String] = _get_full_floor_room_ids()
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(room_ids)
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(room_ids)
	for room_id in source_room_ids:
		var state: Dictionary = _rooms[room_id]
		var piece = state["piece"]
		var connections: Dictionary = state["connections"]
		var connection_edges: Dictionary = state.get("connection_edges", {})
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		for direction in CARDINAL_DIRECTIONS:
			if not connections.has(direction):
				continue
			var target_room_id := String(connections[direction])
			if _room_is_visible_on_full_floor(target_room_id, current_room_id):
				continue
			var edge: Dictionary = connection_edges.get(direction, {})
			var source_cell: Vector2i = edge.get("source_cell", Vector2i.ZERO)
			var trigger_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_trigger_rect(piece.footprint_cells, source_cell, direction)
			var opening_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_wall_body_opening_rect(piece.footprint_cells, source_cell, direction)
			door_infos.append({
				"direction": direction,
				"target_room_id": target_room_id,
				"target_room_kind": _get_room_kind(target_room_id),
				"trigger_rect": _translated_rect(trigger_rect, offset),
				"opening_rect": _translated_rect(opening_rect, offset),
				"source_room_id": room_id,
				"full_floor_transition": true
			})
	return door_infos


func get_full_floor_position_for_room_position(room_id: String, room_position: Vector2) -> Vector2:
	return _get_floor_position_for_room_position(room_id, room_position, _get_full_floor_room_ids())


func get_full_floor_room_position_for_position(floor_position: Vector2) -> Dictionary:
	return _get_floor_room_position_for_position(floor_position, _get_full_floor_room_ids())


func get_full_floor_minimap_position_for_position(position: Vector2) -> Dictionary:
	return _get_floor_minimap_position_for_position(position, _get_full_floor_room_ids())


func get_full_floor_room_bounds(room_id: String) -> Rect2:
	if room_id.is_empty() or not _rooms.has(room_id):
		return Rect2()
	return _get_floor_bounds_for_room_ids([room_id], _get_full_floor_room_ids())


func get_full_floor_visible_bounds(active_room_id: String = "") -> Rect2:
	var visible_room_ids: Array[String] = _get_full_floor_visible_room_ids(active_room_id)
	if visible_room_ids.is_empty():
		return get_full_floor_room_bounds(current_room_id)
	return _get_floor_bounds_for_room_ids(visible_room_ids, _get_full_floor_room_ids())


func _get_floor_minimap_position_for_position(position: Vector2, cleared_room_ids: Array[String]) -> Dictionary:
	if cleared_room_ids.is_empty():
		return {"ok": false, "cell": Vector2i.ZERO, "position": Vector2.ZERO, "room_id": ""}
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(cleared_room_ids)
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(cleared_room_ids)
	var best_cell: Vector2i = Vector2i.ZERO
	var best_position: Vector2 = Vector2.ZERO
	var best_room_id: String = ""
	var best_distance: float = INF
	for room_id in cleared_room_ids:
		var state: Dictionary = _rooms[room_id]
		var piece: Resource = state["piece"]
		var anchor: Vector2i = state["anchor"]
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		for local_cell in piece.footprint_cells:
			var cell_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_cell_rect(piece.footprint_cells, local_cell)
			var translated_rect: Rect2 = _translated_rect(cell_rect, offset)
			var world_cell: Vector2i = anchor + local_cell
			var cell_fraction: Vector2 = _get_rect_fraction(translated_rect, position)
			var minimap_position: Vector2 = Vector2(world_cell) + cell_fraction
			if translated_rect.has_point(position):
				return {"ok": true, "cell": world_cell, "position": minimap_position, "room_id": room_id}
			var closest_point: Vector2 = _get_closest_point_in_rect(position, translated_rect)
			var distance: float = closest_point.distance_squared_to(position)
			if distance < best_distance:
				best_distance = distance
				best_cell = world_cell
				best_position = minimap_position
				best_room_id = room_id
	return {"ok": true, "cell": best_cell, "position": best_position, "room_id": best_room_id}


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
			"connection_edges": Dictionary(state["connection_edges"]).duplicate(),
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


func _get_cleared_floor_wall_tiles(cleared_room_ids: Array[String], min_world_cell: Vector2i, floor_cells: Array[Vector2i]) -> Array[Rect2]:
	var wall_tiles: Array[Rect2] = []
	for room_id in cleared_room_ids:
		var state: Dictionary = _rooms[room_id]
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		var room_wall_tiles: Array[Rect2] = _get_room_wall_tiles(state)
		for rect in room_wall_tiles:
			wall_tiles.append(_translated_rect(rect, offset))
	return wall_tiles


func _get_cleared_floor_wall_top_tiles(cleared_room_ids: Array[String], min_world_cell: Vector2i, floor_cells: Array[Vector2i]) -> Array[Rect2]:
	var wall_top_tiles: Array[Rect2] = []
	for room_id in cleared_room_ids:
		var state: Dictionary = _rooms[room_id]
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		var room_wall_top_tiles: Array[Rect2] = _get_room_wall_top_tiles(state)
		for rect in room_wall_top_tiles:
			wall_top_tiles.append(_translated_rect(rect, offset))
	return wall_top_tiles


func _apply_visible_floor_destructible_prop_placements(level: LevelDefinition, active_room_id: String, room_ids: Array[String], include_active_contents: bool) -> void:
	if level == null or room_ids.is_empty():
		return
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(room_ids)
	if floor_cells.is_empty():
		return
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(room_ids)
	var visible_props: Array[Resource] = []
	for room_id in _get_full_floor_visible_room_ids(active_room_id):
		if room_id.is_empty() or not _rooms.has(room_id):
			continue
		var state: Dictionary = _rooms[room_id]
		if include_active_contents and room_id == active_room_id and not bool(state.get("cleared", false)):
			continue
		var room_level: LevelDefinition = state.get("level_definition", null) as LevelDefinition
		if room_level == null:
			continue
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		visible_props.append_array(_copy_offset_resource_placements(room_level.destructible_prop_placements, offset, room_id))
	level.destructible_prop_placements = visible_props


func _get_room_wall_tiles(state: Dictionary) -> Array[Rect2]:
	var wall_tiles: Array[Rect2] = []
	var room_level: LevelDefinition = state.get("level_definition", null) as LevelDefinition
	if room_level != null and room_level.has_meta("wall_body_tile_rects"):
		for rect in room_level.get_meta("wall_body_tile_rects"):
			if rect is Rect2:
				wall_tiles.append(rect)
		return wall_tiles
	if room_level != null:
		return ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(room_level.wall_rects)
	return _get_room_shell_body_tiles(state)


func _get_room_wall_top_tiles(state: Dictionary) -> Array[Rect2]:
	var wall_top_tiles: Array[Rect2] = []
	var room_level: LevelDefinition = state.get("level_definition", null) as LevelDefinition
	if room_level != null and room_level.has_meta("wall_top_tile_rects"):
		for rect in room_level.get_meta("wall_top_tile_rects"):
			if rect is Rect2:
				wall_top_tiles.append(rect)
		return wall_top_tiles
	if room_level != null and room_level.has_meta("wall_tile_rects"):
		for rect in room_level.get_meta("wall_tile_rects"):
			if rect is Rect2:
				wall_top_tiles.append(rect)
		return wall_top_tiles
	return _get_room_shell_tiles(state)


func _get_room_shell_tiles(state: Dictionary) -> Array[Rect2]:
	var piece: RoomPieceDefinition = state["piece"] as RoomPieceDefinition
	var connection_edges: Dictionary = Dictionary(state.get("connection_edges", {}))
	if piece == null:
		var empty_tiles: Array[Rect2] = []
		return empty_tiles
	return ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(piece.footprint_cells, connection_edges)


func _get_room_shell_body_tiles(state: Dictionary) -> Array[Rect2]:
	var piece: RoomPieceDefinition = state["piece"] as RoomPieceDefinition
	var connection_edges: Dictionary = Dictionary(state.get("connection_edges", {}))
	if piece == null:
		var empty_tiles: Array[Rect2] = []
		return empty_tiles
	var wall_top_tiles := ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(piece.footprint_cells, connection_edges)
	return ROOM_GEOMETRY_BUILDER.build_wall_body_tile_rects(wall_top_tiles, piece.footprint_cells, connection_edges)


func _get_full_floor_room_ids() -> Array[String]:
	return _room_order.duplicate()


func _get_full_floor_visible_room_ids(active_room_id: String = "") -> Array[String]:
	var visible_room_ids: Array[String] = []
	for room_id in _room_order:
		if _room_is_visible_on_full_floor(room_id, active_room_id):
			visible_room_ids.append(room_id)
	return visible_room_ids


func _room_is_visible_on_full_floor(room_id: String, active_room_id: String = "") -> bool:
	if room_id.is_empty() or not _rooms.has(room_id):
		return false
	if room_id == active_room_id:
		return true
	var state: Dictionary = _rooms[room_id]
	return bool(state.get("revealed", false)) and _room_is_cleared_floor_available(state)


func _get_full_floor_door_infos_for_room(room_id: String) -> Array:
	var door_infos: Array = []
	if room_id.is_empty() or not _rooms.has(room_id):
		return door_infos
	var room_ids: Array[String] = _get_full_floor_room_ids()
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(room_ids)
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(room_ids)
	var state: Dictionary = _rooms[room_id]
	var piece = state["piece"]
	var connections: Dictionary = state["connections"]
	var connection_edges: Dictionary = state.get("connection_edges", {})
	var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
	for direction in CARDINAL_DIRECTIONS:
		if not connections.has(direction):
			continue
		var target_room_id := String(connections[direction])
		var edge: Dictionary = connection_edges.get(direction, {})
		var source_cell: Vector2i = edge.get("source_cell", Vector2i.ZERO)
		var trigger_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_trigger_rect(piece.footprint_cells, source_cell, direction)
		var opening_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_wall_body_opening_rect(piece.footprint_cells, source_cell, direction)
		door_infos.append({
			"direction": direction,
			"target_room_id": target_room_id,
			"target_room_kind": _get_room_kind(target_room_id),
			"trigger_rect": _translated_rect(trigger_rect, offset),
			"opening_rect": _translated_rect(opening_rect, offset),
			"source_room_id": room_id,
			"full_floor_transition": true
		})
	return door_infos


func _get_floor_position_for_room_position(room_id: String, room_position: Vector2, room_ids: Array[String]) -> Vector2:
	if room_id.is_empty() or not _rooms.has(room_id) or room_ids.is_empty():
		return room_position
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(room_ids)
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(room_ids)
	var state: Dictionary = _rooms[room_id]
	return room_position + _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)


func _get_floor_room_position_for_position(floor_position: Vector2, room_ids: Array[String]) -> Dictionary:
	if room_ids.is_empty():
		return {"ok": false, "room_id": "", "position": floor_position}
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(room_ids)
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(room_ids)
	var best_room_id: String = ""
	var best_position: Vector2 = floor_position
	var best_distance: float = INF
	for room_id in room_ids:
		var state: Dictionary = _rooms[room_id]
		var piece: RoomPieceDefinition = state["piece"] as RoomPieceDefinition
		if piece == null:
			continue
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		for local_cell in piece.footprint_cells:
			var cell_rect: Rect2 = ROOM_GEOMETRY_BUILDER.get_cell_rect(piece.footprint_cells, local_cell)
			var translated_rect: Rect2 = _translated_rect(cell_rect, offset)
			var room_position: Vector2 = floor_position - offset
			if translated_rect.has_point(floor_position):
				return {"ok": true, "room_id": room_id, "position": room_position}
			var closest_point: Vector2 = _get_closest_point_in_rect(floor_position, translated_rect)
			var distance: float = closest_point.distance_squared_to(floor_position)
			if distance < best_distance:
				best_distance = distance
				best_room_id = room_id
				best_position = room_position
	if best_room_id.is_empty():
		return {"ok": false, "room_id": "", "position": floor_position}
	return {"ok": true, "room_id": best_room_id, "position": best_position}


func _get_floor_bounds_for_room_ids(visible_room_ids: Array[String], floor_room_ids: Array[String]) -> Rect2:
	if visible_room_ids.is_empty() or floor_room_ids.is_empty():
		return Rect2()
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(floor_room_ids)
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(floor_room_ids)
	var initialized: bool = false
	var bounds: Rect2 = Rect2()
	for room_id in visible_room_ids:
		if room_id.is_empty() or not _rooms.has(room_id):
			continue
		var state: Dictionary = _rooms[room_id]
		var piece: RoomPieceDefinition = state["piece"] as RoomPieceDefinition
		if piece == null:
			continue
		var offset: Vector2 = _get_room_to_cleared_floor_offset(state, min_world_cell, floor_cells)
		var room_bounds: Rect2 = ROOM_GEOMETRY_BUILDER.get_bounds(piece.footprint_cells)
		var translated_bounds: Rect2 = _translated_rect(room_bounds, offset)
		if not initialized:
			bounds = translated_bounds
			initialized = true
		else:
			bounds = bounds.merge(translated_bounds)
	if not initialized:
		return Rect2()
	return bounds


func _get_full_floor_fog_rects(active_room_id: String, room_ids: Array[String]) -> Array[Rect2]:
	var fog_rects: Array[Rect2] = []
	if room_ids.is_empty():
		return fog_rects
	var floor_cells: Array[Vector2i] = _get_cleared_floor_cells(room_ids)
	if floor_cells.is_empty():
		return fog_rects
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(room_ids)
	var visible_cell_lookup: Dictionary = _get_full_floor_visible_cell_lookup(active_room_id, room_ids, min_world_cell)
	var min_floor_cell: Vector2i = ROOM_GEOMETRY_BUILDER.get_min_cell(floor_cells)
	var max_floor_cell: Vector2i = ROOM_GEOMETRY_BUILDER.get_max_cell(floor_cells)
	var fog_padding_cells := 1
	for y: int in range(min_floor_cell.y - fog_padding_cells, max_floor_cell.y + fog_padding_cells + 1):
		for x: int in range(min_floor_cell.x - fog_padding_cells, max_floor_cell.x + fog_padding_cells + 1):
			var floor_cell := Vector2i(x, y)
			if visible_cell_lookup.has(_cell_key(floor_cell)):
				continue
			fog_rects.append(ROOM_GEOMETRY_BUILDER.get_cell_rect(floor_cells, floor_cell))
	return fog_rects


func _get_full_floor_visible_cell_lookup(active_room_id: String, room_ids: Array[String], min_world_cell: Vector2i) -> Dictionary:
	var lookup: Dictionary = {}
	for room_id: String in room_ids:
		if not _room_is_visible_on_full_floor(room_id, active_room_id):
			continue
		var state: Dictionary = _rooms[room_id]
		var piece: RoomPieceDefinition = state["piece"] as RoomPieceDefinition
		if piece == null:
			continue
		var anchor: Vector2i = state["anchor"]
		for local_cell: Vector2i in piece.footprint_cells:
			var floor_cell: Vector2i = anchor + local_cell - min_world_cell
			lookup[_cell_key(floor_cell)] = true
	return lookup


func _apply_active_room_contents_to_full_floor_level(level: LevelDefinition, active_room_id: String, room_ids: Array[String]) -> void:
	if level == null or active_room_id.is_empty() or not _rooms.has(active_room_id):
		return
	var state: Dictionary = _rooms[active_room_id]
	if bool(state.get("cleared", false)):
		return
	var active_level: LevelDefinition = state.get("level_definition", null) as LevelDefinition
	if active_level == null:
		return
	var offset: Vector2 = _get_floor_position_for_room_position(active_room_id, Vector2.ZERO, room_ids)
	level.max_active_enemies = int(active_level.max_active_enemies)
	level.spawner_health = int(active_level.spawner_health)
	level.spawner_radius = float(active_level.spawner_radius)
	level.spawn_interval = float(active_level.spawn_interval)
	level.spawner_placements = _copy_offset_resource_placements(active_level.spawner_placements, offset)
	level.destructible_prop_placements.append_array(_copy_offset_resource_placements(active_level.destructible_prop_placements, offset, active_room_id))
	level.boss_profile = active_level.boss_profile
	level.generate_agent_boss = bool(active_level.generate_agent_boss)
	level.randomize_agent_boss_each_load = bool(active_level.randomize_agent_boss_each_load)
	level.boss_spawn_position = active_level.boss_spawn_position + offset


func _copy_offset_resource_placements(source_placements: Array, offset: Vector2, source_room_id: String = "") -> Array[Resource]:
	var copied_placements: Array[Resource] = []
	for source in source_placements:
		var source_resource: Resource = source as Resource
		if source_resource == null:
			continue
		copied_placements.append(_copy_offset_resource_placement(source_resource, offset, source_room_id))
	return copied_placements


func _copy_offset_resource_placement(source_resource: Resource, offset: Vector2, source_room_id: String = "") -> Resource:
	var copied_resource: Resource = source_resource.duplicate(true)
	var source_position: Vector2 = source_resource.get("position")
	copied_resource.set("position", source_position + offset)
	if not source_room_id.is_empty():
		copied_resource.set_meta("source_room_id", source_room_id)
		copied_resource.set_meta("source_placement", source_resource)
	return copied_resource


func _room_is_cleared_floor_available(state: Dictionary) -> bool:
	if state.is_empty() or not bool(state.get("cleared", false)):
		return false
	return bool(state.get("cleared_floor_available", bool(state.get("cleared", false))))


func _get_cleared_floor_min_world_cell(cleared_room_ids: Array[String]) -> Vector2i:
	var initialized := false
	var min_cell := Vector2i.ZERO
	for room_id in cleared_room_ids:
		var state: Dictionary = _rooms[room_id]
		var anchor: Vector2i = state["anchor"]
		var piece = state["piece"]
		for local_cell in piece.footprint_cells:
			var world_cell: Vector2i = anchor + local_cell
			if not initialized:
				min_cell = world_cell
				initialized = true
			else:
				min_cell.x = min(min_cell.x, world_cell.x)
				min_cell.y = min(min_cell.y, world_cell.y)
	return min_cell


func _get_cleared_floor_cells(cleared_room_ids: Array[String]) -> Array[Vector2i]:
	var floor_cells: Array[Vector2i] = []
	if cleared_room_ids.is_empty():
		return floor_cells
	var min_world_cell: Vector2i = _get_cleared_floor_min_world_cell(cleared_room_ids)
	for room_id in cleared_room_ids:
		var state: Dictionary = _rooms[room_id]
		var anchor: Vector2i = state["anchor"]
		var piece = state["piece"]
		for local_cell in piece.footprint_cells:
			floor_cells.append(anchor + local_cell - min_world_cell)
	floor_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return floor_cells


func _get_room_to_cleared_floor_offset(state: Dictionary, min_world_cell: Vector2i, floor_cells: Array[Vector2i]) -> Vector2:
	if state.is_empty() or floor_cells.is_empty():
		return Vector2.ZERO
	var piece = state["piece"]
	var anchor: Vector2i = state["anchor"]
	var room_bounds: Rect2 = ROOM_GEOMETRY_BUILDER.get_bounds(piece.footprint_cells)
	var floor_bounds: Rect2 = ROOM_GEOMETRY_BUILDER.get_bounds(floor_cells)
	var floor_local_anchor: Vector2i = anchor - min_world_cell
	return floor_bounds.position + Vector2(floor_local_anchor) * ROOM_GEOMETRY_BUILDER.CELL_SIZE - room_bounds.position


func _translated_rect(rect: Rect2, offset: Vector2) -> Rect2:
	return Rect2(rect.position + offset, rect.size)


func _get_rect_fraction(rect: Rect2, position: Vector2) -> Vector2:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(0.5, 0.5)
	return Vector2(
		clamp((position.x - rect.position.x) / rect.size.x, 0.0, 1.0),
		clamp((position.y - rect.position.y) / rect.size.y, 0.0, 1.0)
	)


func _get_closest_point_in_rect(position: Vector2, rect: Rect2) -> Vector2:
	return Vector2(
		clamp(position.x, rect.position.x, rect.position.x + rect.size.x),
		clamp(position.y, rect.position.y, rect.position.y + rect.size.y)
	)


func _get_room_kind(room_id: String) -> String:
	if room_id.is_empty() or not _rooms.has(room_id):
		return ""
	var state: Dictionary = _rooms[room_id]
	var piece = state.get("piece", null)
	if piece == null:
		return ""
	return String(piece.room_kind)


func get_run_seed() -> int:
	return run_seed


func get_floor_generation_seed() -> int:
	return floor_generation_seed


func _generate_layout() -> void:
	_rooms.clear()
	_room_order.clear()
	_occupied_cells.clear()
	_large_room_count = 0
	_crossroads_placed = false
	current_room_id = ""
	floor_cat_room_id = ""
	_floor_cat_room_position = Vector2.ZERO
	_floor_cat_seed = 0
	var rng := RandomNumberGenerator.new()
	floor_generation_seed = _compute_floor_generation_seed()
	rng.seed = floor_generation_seed
	_place_room("start", START_PIECE, Vector2i.ZERO, true)
	var path_room_ids := _build_boss_path(rng)
	_try_place_required_branch("treasure_1", TREASURE_PIECE, path_room_ids, rng)
	var challenge_piece = _choose_room_piece_variant(CHALLENGE_PIECE, rng)
	if not _try_place_connected_any_direction("start", "challenge_1", challenge_piece, rng):
		_try_place_required_branch("challenge_1", challenge_piece, path_room_ids, rng)
	_fill_optional_branches(path_room_ids, rng)
	_generate_room_interiors()
	_assign_floor_cat_spawn(rng)
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
		if not _try_place_connected_from_candidates(current_id, _get_path_candidate_directions(path_direction, rng), room_id, piece, rng):
			piece = _choose_room_piece_variant(WIDE_PIECE, rng)
			if not _try_place_connected_from_candidates(current_id, _get_path_candidate_directions(path_direction, rng), room_id, piece, rng):
				break
		path_room_ids.append(room_id)
		current_id = room_id
	if not _try_place_connected(current_id, path_direction, "boss", BOSS_PIECE, rng):
		for room_id in path_room_ids.duplicate():
			if room_id == "start":
				continue
			if _try_place_connected(room_id, path_direction, "boss", BOSS_PIECE, rng):
				break
	return path_room_ids


func _try_place_required_branch(room_id: String, piece, parent_ids: Array[String], rng: RandomNumberGenerator) -> bool:
	for attempt in range(18):
		var parent_id := parent_ids[rng.randi_range(0, parent_ids.size() - 1)]
		var directions := _shuffled_cardinal_directions(rng)
		for direction in directions:
			if _try_place_connected(parent_id, direction, room_id, piece, rng):
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
			if _try_place_connected(parent_id, direction, room_id, piece, rng):
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


func _try_place_connected(parent_id: String, direction: String, room_id: String, piece, rng: RandomNumberGenerator = null) -> bool:
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
	var parent_edges := _get_piece_exposed_edges(parent_piece, direction)
	var child_edges := _get_piece_exposed_edges(piece, opposite)
	_shuffle_edge_candidates(parent_edges, rng)
	_shuffle_edge_candidates(child_edges, rng)
	var best_candidates: Array[Dictionary] = []
	var best_score := -1
	for parent_edge in parent_edges:
		var parent_cell: Vector2i = parent_edge.get("cell", Vector2i.ZERO)
		for child_edge in child_edges:
			var child_cell: Vector2i = child_edge.get("cell", Vector2i.ZERO)
			var candidate_anchor: Vector2i = Vector2i(parent_state["anchor"]) + parent_cell + DIRECTION_OFFSETS[direction] - child_cell
			if _can_place_connected(piece, candidate_anchor, parent_id, direction):
				var score := _get_place_density_score(piece, candidate_anchor, parent_id, direction)
				if score > best_score:
					best_score = score
					best_candidates.clear()
				if score == best_score:
					best_candidates.append({
						"anchor": candidate_anchor,
						"source_cell": parent_cell,
						"target_cell": child_cell
					})
	if best_candidates.is_empty():
		return false
	var selected: Dictionary = best_candidates[0]
	if rng != null and best_candidates.size() > 1:
		selected = best_candidates[rng.randi_range(0, best_candidates.size() - 1)]
	_place_room(room_id, piece, Vector2i(selected["anchor"]))
	_connect_rooms(parent_id, direction, room_id, {
		"source_cell": Vector2i(selected["source_cell"]),
		"target_cell": Vector2i(selected["target_cell"])
	})
	return true


func _try_place_connected_any_direction(parent_id: String, room_id: String, piece, rng: RandomNumberGenerator) -> bool:
	return _try_place_connected_from_candidates(parent_id, _shuffled_cardinal_directions(rng), room_id, piece, rng)


func _try_place_connected_from_candidates(parent_id: String, directions: Array[String], room_id: String, piece, rng: RandomNumberGenerator) -> bool:
	for direction in directions:
		if _try_place_connected(parent_id, direction, room_id, piece, rng):
			return true
	return false


func _piece_allows_connector(piece, direction: String) -> bool:
	if piece.has_connector(direction):
		return true
	return String(piece.room_kind) == "boss" and DIRECTION_OFFSETS.has(direction)


func _get_piece_exposed_edges(piece, direction: String) -> Array[Dictionary]:
	if not _piece_allows_connector(piece, direction):
		return []
	return ROOM_GEOMETRY_BUILDER.get_exposed_edges(piece.footprint_cells, direction)


func _shuffle_edge_candidates(edges: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	if rng == null:
		return
	for index in range(edges.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var value := edges[index]
		edges[index] = edges[swap_index]
		edges[swap_index] = value


func _choose_combat_piece(rng: RandomNumberGenerator, path_index: int):
	var size := _choose_combat_room_size(rng, true)
	var pieces: Array = _get_room_piece_variants(COMBAT_PIECES_BY_SIZE.get(size, [WIDE_PIECE]))
	var index: int = (rng.randi_range(0, pieces.size() - 1) + floor_number + path_index) % pieces.size()
	return pieces[index]


func _choose_branch_piece(rng: RandomNumberGenerator, branch_index: int):
	if floor_number >= 3 and branch_index % 4 == 0:
		return _choose_room_piece_variant(CHALLENGE_PIECE, rng)
	var size := _choose_combat_room_size(rng, false)
	var pieces: Array = _get_room_piece_variants(COMBAT_PIECES_BY_SIZE.get(size, [WIDE_PIECE]))
	return pieces[rng.randi_range(0, pieces.size() - 1)]


func _choose_room_piece_variant(piece, rng: RandomNumberGenerator):
	var variants := _get_room_piece_variants([piece])
	return variants[rng.randi_range(0, variants.size() - 1)]


func _get_room_piece_variants(pieces: Array) -> Array:
	var variants: Array = []
	for piece in pieces:
		var cache_key := _get_piece_variant_cache_key(piece)
		if not _piece_variant_cache.has(cache_key):
			_piece_variant_cache[cache_key] = _build_room_piece_variants(piece)
		variants.append_array(Array(_piece_variant_cache[cache_key]))
	return variants


func _build_room_piece_variants(piece) -> Array:
	var variants: Array = []
	var seen := {}
	for variant_data in _get_room_piece_variant_data(piece):
		var footprint: Array[Vector2i] = []
		for cell in variant_data["footprint"]:
			footprint.append(cell)
		var connector_directions: PackedStringArray = variant_data["connector_directions"]
		var key := "%s:%s:%s" % [String(piece.id), _footprint_key(footprint), _connector_key(connector_directions)]
		if seen.has(key):
			continue
		seen[key] = true
		if int(variant_data["transform_index"]) == 0:
			variants.append(piece)
		else:
			var variant = piece.duplicate(true)
			variant.footprint_cells = footprint
			variant.connector_directions = connector_directions
			variants.append(variant)
	return variants


func _get_piece_variant_cache_key(piece) -> String:
	return "%s:%s:%s:%s" % [
		String(piece.resource_path),
		String(piece.id),
		_footprint_key(piece.footprint_cells),
		_connector_key(piece.get_connector_directions())
	]


func _get_room_piece_variant_data(piece) -> Array:
	var variants: Array = []
	var seen := {}
	for transform_index in range(8):
		var transformed: Array[Vector2i] = []
		for cell in piece.footprint_cells:
			transformed.append(_transform_footprint_cell(cell, transform_index))
		transformed = _normalize_footprint_cells(transformed)
		var transformed_connectors := _transform_connector_directions(piece.get_connector_directions(), transform_index)
		var key := "%s:%s" % [_footprint_key(transformed), _connector_key(transformed_connectors)]
		if seen.has(key):
			continue
		seen[key] = true
		variants.append({
			"footprint": transformed,
			"connector_directions": transformed_connectors,
			"transform_index": transform_index
		})
	return variants


func _transform_footprint_cell(cell: Vector2i, transform_index: int) -> Vector2i:
	match transform_index:
		0:
			return Vector2i(cell.x, cell.y)
		1:
			return Vector2i(-cell.y, cell.x)
		2:
			return Vector2i(-cell.x, -cell.y)
		3:
			return Vector2i(cell.y, -cell.x)
		4:
			return Vector2i(-cell.x, cell.y)
		5:
			return Vector2i(cell.y, cell.x)
		6:
			return Vector2i(cell.x, -cell.y)
		_:
			return Vector2i(-cell.y, -cell.x)


func _transform_connector_directions(connector_directions: PackedStringArray, transform_index: int) -> PackedStringArray:
	var directions: Array[String] = []
	for direction in connector_directions:
		var offset: Vector2i = DIRECTION_OFFSETS.get(String(direction), Vector2i.ZERO)
		var transformed_offset := _transform_footprint_cell(offset, transform_index)
		var transformed_direction := _direction_from_offset(transformed_offset)
		if transformed_direction.is_empty() or directions.has(transformed_direction):
			continue
		directions.append(transformed_direction)
	directions.sort()
	return PackedStringArray(directions)


func _direction_from_offset(offset: Vector2i) -> String:
	for direction_key in DIRECTION_OFFSETS.keys():
		if DIRECTION_OFFSETS[direction_key] == offset:
			return String(direction_key)
	return ""


func _normalize_footprint_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
	var min_cell := cells[0]
	for cell in cells:
		min_cell.x = min(min_cell.x, cell.x)
		min_cell.y = min(min_cell.y, cell.y)
	var normalized: Array[Vector2i] = []
	for cell in cells:
		normalized.append(cell - min_cell)
	normalized.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
	return normalized


func _footprint_key(cells: Array) -> String:
	var parts: Array[String] = []
	for cell in cells:
		parts.append("%d,%d" % [cell.x, cell.y])
	return ";".join(parts)


func _connector_key(connector_directions: PackedStringArray) -> String:
	var directions: Array[String] = []
	for direction in connector_directions:
		directions.append(String(direction))
	directions.sort()
	return ",".join(directions)


func _choose_combat_room_size(rng: RandomNumberGenerator, is_path_room: bool) -> int:
	var non_special_room_count := _get_non_special_combat_room_count()
	var large_cap: int = max(1, int(ceil(float(max(non_special_room_count + 1, 4)) * 0.25)))
	var allow_large := _large_room_count < large_cap
	var allow_crossroads := (not _crossroads_placed) and non_special_room_count >= 4
	var roll := rng.randf()
	if allow_crossroads and roll < 0.04:
		return 5
	if allow_large and roll < 0.18:
		return 4
	if roll < 0.46:
		return 2
	if roll < 0.74:
		return 3
	if not is_path_room or roll < 0.92:
		return 1
	return 2


func _get_non_special_combat_room_count() -> int:
	var count := 0
	for room_id in _room_order:
		var state: Dictionary = _rooms[room_id]
		var piece = state["piece"]
		if String(piece.room_kind) == "combat":
			count += 1
	return count


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
	var cleared_floor_available := initially_cleared and String(piece.room_kind) != "treasure"
	_rooms[room_id] = {
		"id": room_id,
		"piece": piece,
		"anchor": anchor,
		"connections": {},
		"connection_edges": {},
		"level_definition": null,
		"cleared": initially_cleared,
		"cleared_floor_available": cleared_floor_available,
		"revealed": false
	}
	_room_order.append(room_id)
	if String(piece.room_kind) == "combat":
		var cell_count: int = piece.footprint_cells.size()
		if cell_count >= 4:
			_large_room_count += 1
		if String(piece.id) == "combat_crossroads":
			_crossroads_placed = true
	for local_cell in piece.footprint_cells:
		var world_cell: Vector2i = anchor + local_cell
		_occupied_cells[_cell_key(world_cell)] = room_id


func _connect_rooms(from_id: String, direction: String, to_id: String, contact: Dictionary = {}) -> void:
	var opposite := String(OPPOSITE_DIRECTIONS.get(direction, ""))
	var from_state: Dictionary = _rooms[from_id]
	var to_state: Dictionary = _rooms[to_id]
	var from_connections: Dictionary = from_state["connections"]
	var to_connections: Dictionary = to_state["connections"]
	var from_edges: Dictionary = from_state["connection_edges"]
	var to_edges: Dictionary = to_state["connection_edges"]
	from_connections[direction] = to_id
	to_connections[opposite] = from_id
	if contact.is_empty():
		contact = ROOM_GEOMETRY_BUILDER.find_contact_edge(
			from_state["piece"].footprint_cells,
			from_state["anchor"],
			to_state["piece"].footprint_cells,
			to_state["anchor"],
			direction
		)
	from_edges[direction] = contact
	to_edges[opposite] = {
		"source_cell": contact.get("target_cell", Vector2i.ZERO),
		"target_cell": contact.get("source_cell", Vector2i.ZERO)
	}
	from_state["connections"] = from_connections
	to_state["connections"] = to_connections
	from_state["connection_edges"] = from_edges
	to_state["connection_edges"] = to_edges
	_rooms[from_id] = from_state
	_rooms[to_id] = to_state


func _can_place(piece, anchor: Vector2i) -> bool:
	for local_cell in piece.footprint_cells:
		var world_cell: Vector2i = anchor + local_cell
		if _occupied_cells.has(_cell_key(world_cell)):
			return false
	return true


func _can_place_connected(piece, anchor: Vector2i, _parent_id: String, _parent_to_child_direction: String) -> bool:
	if not _can_place(piece, anchor):
		return false
	return true


func _get_place_density_score(piece, anchor: Vector2i, parent_id: String, parent_to_child_direction: String) -> int:
	var child_to_parent_direction := String(OPPOSITE_DIRECTIONS.get(parent_to_child_direction, ""))
	var score := 0
	var counted := {}
	for local_cell in piece.footprint_cells:
		var world_cell: Vector2i = anchor + local_cell
		for direction_key in DIRECTION_OFFSETS.keys():
			var direction := String(direction_key)
			var neighbor_cell: Vector2i = world_cell + DIRECTION_OFFSETS[direction]
			var neighbor_id := String(_occupied_cells.get(_cell_key(neighbor_cell), ""))
			if neighbor_id.is_empty():
				continue
			if neighbor_id == parent_id and direction == child_to_parent_direction:
				continue
			var contact_key := "%s:%s:%s" % [neighbor_id, _cell_key(world_cell), _cell_key(neighbor_cell)]
			if counted.has(contact_key):
				continue
			counted[contact_key] = true
			score += 1
	return score


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
			level = _interior_generator.generate(piece, String(room_id), floor_number, floor_generation_seed, connections, state["connection_edges"])
		else:
			level = piece.create_level_definition()
			level.id = String(room_id)
			level.display_name = "%s - %s" % [piece.display_name, String(room_id).capitalize()]
			level.difficulty_label = "Floor %d %s" % [floor_number, room_kind.capitalize()]
			level.floor_number = max(floor_number, 1)
			_apply_floor_scaling(level, room_kind)
			_apply_room_geometry(level, piece, state["connection_edges"])
		state["level_definition"] = level
		_rooms[room_id] = state


func _assign_floor_cat_spawn(rng: RandomNumberGenerator) -> void:
	if _rooms.has("start") and rng.randf() < CAT_START_ROOM_SPAWN_CHANCE:
		floor_cat_room_id = "start"
		_floor_cat_room_position = _pick_floor_cat_room_position(floor_cat_room_id, rng)
		_floor_cat_seed = abs(("%d:%d:%s:cat" % [floor_generation_seed, floor_number, floor_cat_room_id]).hash()) + 1
		return
	var candidates: Array[String] = []
	for room_id in _room_order:
		var room_kind := _get_room_kind(room_id)
		if room_kind == "start" or room_kind == "combat":
			candidates.append(room_id)
	if candidates.is_empty():
		return
	floor_cat_room_id = candidates[rng.randi_range(0, candidates.size() - 1)]
	_floor_cat_room_position = _pick_floor_cat_room_position(floor_cat_room_id, rng)
	_floor_cat_seed = abs(("%d:%d:%s:cat" % [floor_generation_seed, floor_number, floor_cat_room_id]).hash()) + 1


func _pick_floor_cat_room_position(room_id: String, rng: RandomNumberGenerator) -> Vector2:
	if room_id.is_empty() or not _rooms.has(room_id):
		return Vector2.ZERO
	var state: Dictionary = _rooms[room_id]
	var piece: RoomPieceDefinition = state.get("piece", null) as RoomPieceDefinition
	var level: LevelDefinition = state.get("level_definition", null) as LevelDefinition
	if level == null:
		return ROOM_GEOMETRY_BUILDER.get_spawn_position(piece.footprint_cells) if piece != null else Vector2.ZERO
	var bounds: Rect2 = level.arena_bounds
	var center := bounds.get_center()
	var half := bounds.size * 0.5
	for _attempt in range(32):
		var candidate := center + Vector2(
			rng.randf_range(-half.x * 0.42, half.x * 0.42),
			rng.randf_range(-half.y * 0.38, half.y * 0.38)
		)
		candidate = _find_clear_floor_cat_position(candidate, level)
		if _floor_cat_position_is_clear(candidate, level):
			return candidate
	var fallback := ROOM_GEOMETRY_BUILDER.get_spawn_position(piece.footprint_cells) if piece != null else center
	return _find_clear_floor_cat_position(fallback, level)


func _find_clear_floor_cat_position(preferred_position: Vector2, level: LevelDefinition) -> Vector2:
	var blockers := _get_floor_cat_blocker_rects(level)
	var playable_rects := _get_level_playable_rects(level)
	var constrained := ArenaGeometry.constrain_point_to_playable_regions(preferred_position, level.arena_bounds, int(level.arena_shape), playable_rects, blockers, 18.0)
	if _floor_cat_position_is_clear(constrained, level):
		return constrained
	var search_step := 48.0
	for radius_index in range(1, 7):
		var radius := search_step * float(radius_index)
		var sample_count := 8 + radius_index * 4
		for sample_index in range(sample_count):
			var candidate := preferred_position + Vector2.RIGHT.rotated(TAU * float(sample_index) / float(sample_count)) * radius
			candidate = ArenaGeometry.constrain_point_to_playable_regions(candidate, level.arena_bounds, int(level.arena_shape), playable_rects, blockers, 18.0)
			if _floor_cat_position_is_clear(candidate, level):
				return candidate
	return constrained


func _floor_cat_position_is_clear(position: Vector2, level: LevelDefinition) -> bool:
	if level == null:
		return false
	var blockers := _get_floor_cat_blocker_rects(level)
	var playable_rects := _get_level_playable_rects(level)
	var constrained := ArenaGeometry.constrain_point_to_playable_regions(position, level.arena_bounds, int(level.arena_shape), playable_rects, blockers, 18.0)
	if position.distance_squared_to(constrained) > 1.0:
		return false
	for blocker in blockers:
		if blocker.grow(18.0).has_point(position):
			return false
	return true


func _get_floor_cat_blocker_rects(level: LevelDefinition) -> Array[Rect2]:
	var blockers: Array[Rect2] = []
	if level == null:
		return blockers
	blockers.append_array(level.wall_rects)
	blockers.append_array(level.void_rects)
	for placement in level.spawner_placements:
		if placement == null:
			continue
		var position: Vector2 = placement.get("position")
		blockers.append(Rect2(position - Vector2(86.0, 86.0), Vector2(172.0, 172.0)))
	for placement in level.destructible_prop_placements:
		if placement == null:
			continue
		var position: Vector2 = placement.get("position")
		var size_value = placement.get("size")
		var size: Vector2 = size_value if size_value is Vector2 else Vector2(48.0, 48.0)
		blockers.append(Rect2(position - size * 0.5, size).grow(18.0))
	return blockers


func _get_level_playable_rects(level: LevelDefinition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level == null or not level.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level.arena_bounds, level.get_meta("footprint_cells")))
	return rects


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


func _apply_room_geometry(level, piece, connection_edges: Dictionary) -> void:
	level.arena_shape = 0
	level.arena_bounds = ROOM_GEOMETRY_BUILDER.get_bounds(piece.footprint_cells)
	level.set_meta("footprint_cells", piece.footprint_cells.duplicate())
	level.set_meta("connection_edges", connection_edges.duplicate())
	var wall_top_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_tile_rects(piece.footprint_cells, connection_edges)
	wall_top_tiles.append_array(ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(piece.wall_rects))
	var wall_body_tiles: Array[Rect2] = ROOM_GEOMETRY_BUILDER.build_wall_body_tile_rects(wall_top_tiles, piece.footprint_cells, connection_edges)
	level.wall_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(wall_body_tiles)
	level.set_meta("wall_top_tile_rects", wall_top_tiles)
	level.set_meta("wall_body_tile_rects", wall_body_tiles)
	level.set_meta("wall_tile_rects", wall_top_tiles)


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
