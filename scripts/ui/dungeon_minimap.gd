extends Control
class_name DungeonMinimap

@export var cell_size: float = 24.0
@export var cell_gap: float = 3.0
@export var padding: float = 12.0

var rooms: Array = []
var current_room_id: String = ""
var current_player_cell: Vector2i = Vector2i.ZERO
var has_current_player_cell: bool = false
var current_player_position: Vector2 = Vector2.ZERO
var has_current_player_position: bool = false


func _ready() -> void:
	clip_contents = true


func set_map(room_infos: Array, current_id: String, player_location = null) -> void:
	rooms = room_infos
	current_room_id = current_id
	has_current_player_cell = false
	has_current_player_position = false
	if typeof(player_location) == TYPE_VECTOR2:
		current_player_position = player_location
		current_player_cell = Vector2i(floori(current_player_position.x), floori(current_player_position.y))
		has_current_player_position = true
		has_current_player_cell = true
	elif typeof(player_location) == TYPE_VECTOR2I:
		current_player_cell = player_location
		has_current_player_cell = true
	if has_current_player_cell and not has_current_player_position:
		current_player_position = Vector2(current_player_cell) + Vector2(0.5, 0.5)
	visible = not rooms.is_empty()
	queue_redraw()


func clear_map() -> void:
	rooms.clear()
	current_room_id = ""
	has_current_player_cell = false
	has_current_player_position = false
	visible = false
	queue_redraw()


func _draw() -> void:
	if rooms.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.015, 0.018, 0.82), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.42, 0.48, 0.95), false, 2.0)
	var visible_rooms := _get_visible_rooms()
	if visible_rooms.is_empty():
		return
	var bounds := _get_cell_bounds(visible_rooms)
	var pitch := cell_size + cell_gap
	var viewport := _get_map_viewport()
	var draw_bounds := Rect2(Vector2.ZERO, size)
	var origin := _get_map_origin(bounds, pitch, viewport)
	_draw_connections(visible_rooms, origin, pitch, draw_bounds)
	for info in visible_rooms:
		_draw_room_fill(info, origin, pitch, draw_bounds)
	for info in visible_rooms:
		_draw_special_room_logo(info, origin, pitch, draw_bounds)
	for info in visible_rooms:
		_draw_room_details(info, origin, pitch, draw_bounds)
	_draw_connection_doors(visible_rooms, origin, pitch, draw_bounds)
	_draw_unexplored_connection_doors(visible_rooms, origin, pitch, draw_bounds)
	_draw_player_marker(origin, pitch, draw_bounds)


func _get_map_viewport() -> Rect2:
	var inset: float = min(padding, min(size.x, size.y) * 0.25)
	var viewport_size := Vector2(max(size.x - inset * 2.0, 1.0), max(size.y - inset * 2.0, 1.0))
	return Rect2(Vector2(inset, inset), viewport_size)


func _get_map_origin(bounds: Rect2i, pitch: float, viewport: Rect2) -> Vector2:
	if has_current_player_position or has_current_player_cell:
		return viewport.get_center() - _get_player_marker_center(Vector2.ZERO, pitch)
	var map_size := Vector2(float(bounds.size.x) * pitch - cell_gap, float(bounds.size.y) * pitch - cell_gap)
	return viewport.get_center() - map_size * 0.5 - Vector2(bounds.position) * pitch


func _get_visible_rooms() -> Array:
	var visible_rooms: Array = []
	for info in rooms:
		if bool(info.get("revealed", false)):
			visible_rooms.append(info)
	return visible_rooms


func _get_cell_bounds(visible_rooms: Array) -> Rect2i:
	var initialized := false
	var min_cell := Vector2i.ZERO
	var max_cell := Vector2i.ZERO
	for info in visible_rooms:
		var anchor: Vector2i = info["anchor"]
		for local_cell in info["footprint_cells"]:
			var cell: Vector2i = anchor + local_cell
			if not initialized:
				min_cell = cell
				max_cell = cell
				initialized = true
			else:
				min_cell.x = min(min_cell.x, cell.x)
				min_cell.y = min(min_cell.y, cell.y)
				max_cell.x = max(max_cell.x, cell.x)
				max_cell.y = max(max_cell.y, cell.y)
	if not initialized:
		return Rect2i(Vector2i.ZERO, Vector2i.ONE)
	return Rect2i(min_cell, max_cell - min_cell + Vector2i.ONE)


func _draw_connections(visible_rooms: Array, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	var visible_ids := {}
	for info in visible_rooms:
		visible_ids[String(info["id"])] = true
	for info in visible_rooms:
		var from_id := String(info["id"])
		var connections: Dictionary = info["connections"]
		var connection_edges: Dictionary = info.get("connection_edges", {})
		for direction in connections.keys():
			var to_id := String(connections[direction])
			if not visible_ids.has(to_id) or from_id > to_id:
				continue
			var target_info = _find_room_info(visible_rooms, to_id)
			if target_info.is_empty():
				continue
			var edge: Dictionary = connection_edges.get(direction, {})
			var from_center: Vector2 = _get_connection_cell_center(info, edge.get("source_cell", null), origin, pitch)
			var to_center: Vector2 = _get_connection_cell_center(target_info, edge.get("target_cell", null), origin, pitch)
			if not _segment_rect(from_center, to_center).grow(6.0).intersects(viewport):
				continue
			draw_line(from_center, to_center, Color(0.96, 0.9, 0.28, 1.0), max(7.0, cell_gap + 5.0))


func _draw_connection_doors(visible_rooms: Array, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	var visible_ids := {}
	for info in visible_rooms:
		visible_ids[String(info["id"])] = true
	for info in visible_rooms:
		var from_id := String(info["id"])
		var connections: Dictionary = info["connections"]
		var connection_edges: Dictionary = info.get("connection_edges", {})
		for direction in connections.keys():
			var to_id := String(connections[direction])
			if not visible_ids.has(to_id) or from_id > to_id:
				continue
			var target_info = _find_room_info(visible_rooms, to_id)
			if target_info.is_empty():
				continue
			var edge: Dictionary = connection_edges.get(direction, {})
			var from_center: Vector2 = _get_connection_cell_center(info, edge.get("source_cell", null), origin, pitch)
			var to_center: Vector2 = _get_connection_cell_center(target_info, edge.get("target_cell", null), origin, pitch)
			var midpoint: Vector2 = (from_center + to_center) * 0.5
			if not viewport.grow(6.0).has_point(midpoint):
				continue
			var connection_vector: Vector2 = to_center - from_center
			var door_half_length: float = max(5.0, cell_size * 0.26)
			var door_width: float = max(3.0, cell_gap + 1.0)
			if abs(connection_vector.x) >= abs(connection_vector.y):
				draw_line(midpoint + Vector2(0.0, -door_half_length), midpoint + Vector2(0.0, door_half_length), Color(1.0, 0.96, 0.28, 1.0), door_width)
			else:
				draw_line(midpoint + Vector2(-door_half_length, 0.0), midpoint + Vector2(door_half_length, 0.0), Color(1.0, 0.96, 0.28, 1.0), door_width)


func _draw_unexplored_connection_doors(visible_rooms: Array, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	var visible_ids := {}
	for info in visible_rooms:
		visible_ids[String(info["id"])] = true
	for info in visible_rooms:
		var connections: Dictionary = info["connections"]
		var connection_edges: Dictionary = info.get("connection_edges", {})
		for direction in connections.keys():
			var to_id := String(connections[direction])
			if visible_ids.has(to_id):
				continue
			var edge: Dictionary = connection_edges.get(direction, {})
			var source_center: Vector2 = _get_connection_cell_center(info, edge.get("source_cell", null), origin, pitch)
			var midpoint: Vector2 = source_center + _get_minimap_direction_vector(String(direction)) * (pitch * 0.5 - cell_gap * 0.5)
			if not viewport.grow(6.0).has_point(midpoint):
				continue
			var tangent: Vector2 = _get_minimap_door_tangent(String(direction))
			var door_half_length: float = max(4.0, cell_size * 0.2)
			var door_width: float = max(2.5, cell_gap + 0.5)
			draw_line(midpoint - tangent * door_half_length, midpoint + tangent * door_half_length, Color(0.2, 1.0, 0.92, 1.0), door_width)


func _draw_player_marker(origin: Vector2, pitch: float, viewport: Rect2) -> void:
	if not has_current_player_position and not has_current_player_cell:
		return
	var center: Vector2 = _get_player_marker_center(origin, pitch)
	if not viewport.grow(10.0).has_point(center):
		return
	draw_circle(center, 5.5, Color(1.0, 0.96, 0.34, 1.0))
	draw_arc(center, 8.5, 0.0, TAU, 24, Color(0.04, 0.05, 0.06, 1.0), 2.0)


func _draw_room_fill(info: Dictionary, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	var room_color := _get_room_color(String(info.get("kind", "combat")), bool(info.get("cleared", false)))
	var is_current := String(info["id"]) == current_room_id
	if is_current:
		room_color = Color(0.36, 0.82, 1.0, 1.0)
	var occupied := _get_occupied_cells(info)
	for key in occupied.keys():
		var cell := _cell_from_key(String(key))
		var rect := _get_room_cell_mass_rect(cell, occupied, origin, pitch)
		var clipped_rect := rect.intersection(viewport)
		if not clipped_rect.has_area():
			continue
		draw_rect(clipped_rect, room_color, true)


func _draw_room_details(info: Dictionary, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	var occupied := _get_occupied_cells(info)
	_draw_room_outline(occupied, origin, pitch, viewport)


func _draw_special_room_logo(info: Dictionary, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	var kind := String(info.get("kind", "combat"))
	if kind != "treasure" and kind != "challenge" and kind != "boss":
		return
	var center: Vector2 = _get_special_logo_center(info, origin, pitch)
	if not viewport.grow(8.0).has_point(center):
		return
	var marker_size: float = clamp(cell_size * 0.72, 12.0, 20.0)
	var accent_color: Color = _get_special_logo_color(kind)
	draw_circle(center, marker_size * 0.58, Color(0.015, 0.018, 0.02, 0.82))
	draw_arc(center, marker_size * 0.58, 0.0, TAU, 24, accent_color, 1.8)
	draw_set_transform(center)
	match kind:
		"treasure":
			_draw_treasure_logo(marker_size, accent_color)
		"challenge":
			_draw_challenge_logo(marker_size, accent_color)
		"boss":
			_draw_boss_logo(marker_size, accent_color)
	draw_set_transform(Vector2.ZERO)


func _get_special_logo_center(info: Dictionary, origin: Vector2, pitch: float) -> Vector2:
	if String(info.get("kind", "")) == "challenge":
		var reward_cell: Vector2i = _get_challenge_reward_world_cell(info)
		return origin + Vector2(reward_cell) * pitch + Vector2(pitch, pitch) * 0.5 - Vector2(cell_gap, cell_gap) * 0.5
	return _get_room_center(info, origin, pitch)


func _get_challenge_reward_world_cell(info: Dictionary) -> Vector2i:
	var anchor: Vector2i = info["anchor"]
	var local_cell: Vector2i = _get_center_weighted_local_cell(info)
	return anchor + local_cell


func _get_center_weighted_local_cell(info: Dictionary) -> Vector2i:
	var cells: Array = info["footprint_cells"]
	if cells.is_empty():
		return Vector2i.ZERO
	var min_cell: Vector2i = cells[0]
	var max_cell: Vector2i = cells[0]
	for cell in cells:
		var local_cell: Vector2i = cell
		min_cell.x = min(min_cell.x, local_cell.x)
		min_cell.y = min(min_cell.y, local_cell.y)
		max_cell.x = max(max_cell.x, local_cell.x)
		max_cell.y = max(max_cell.y, local_cell.y)
	var target: Vector2 = (Vector2(min_cell) + Vector2(max_cell) + Vector2.ONE) * 0.5
	var best_cell: Vector2i = cells[0]
	var best_distance: float = INF
	for cell in cells:
		var local_cell: Vector2i = cell
		var center: Vector2 = Vector2(local_cell) + Vector2(0.5, 0.5)
		var distance: float = center.distance_squared_to(target)
		if distance < best_distance:
			best_distance = distance
			best_cell = local_cell
	return best_cell


func _get_special_logo_color(kind: String) -> Color:
	match kind:
		"treasure":
			return Color(1.0, 0.82, 0.18, 1.0)
		"challenge":
			return Color(1.0, 0.28, 0.18, 1.0)
		"boss":
			return Color(0.78, 0.34, 1.0, 1.0)
	return Color(0.84, 0.94, 1.0, 1.0)


func _draw_treasure_logo(marker_size: float, accent_color: Color) -> void:
	var half: float = marker_size * 0.28
	var diamond := PackedVector2Array([
		Vector2(0.0, -half),
		Vector2(half, 0.0),
		Vector2(0.0, half),
		Vector2(-half, 0.0)
	])
	draw_colored_polygon(diamond, accent_color)
	draw_polyline(diamond, Color(1.0, 1.0, 0.75, 1.0), 1.5, true)


func _draw_challenge_logo(marker_size: float, accent_color: Color) -> void:
	var arm: float = marker_size * 0.36
	draw_line(Vector2(-arm, -arm), Vector2(arm, arm), accent_color, 2.2)
	draw_line(Vector2(arm, -arm), Vector2(-arm, arm), Color(1.0, 0.78, 0.36, 1.0), 2.2)
	draw_circle(Vector2.ZERO, marker_size * 0.12, Color(0.12, 0.02, 0.02, 1.0))


func _draw_boss_logo(marker_size: float, accent_color: Color) -> void:
	var crown_width: float = marker_size * 0.62
	var crown_height: float = marker_size * 0.42
	var base_y: float = crown_height * 0.35
	var crown := PackedVector2Array([
		Vector2(-crown_width * 0.5, base_y),
		Vector2(-crown_width * 0.42, -crown_height * 0.15),
		Vector2(-crown_width * 0.2, crown_height * 0.02),
		Vector2(0.0, -crown_height * 0.5),
		Vector2(crown_width * 0.2, crown_height * 0.02),
		Vector2(crown_width * 0.42, -crown_height * 0.15),
		Vector2(crown_width * 0.5, base_y)
	])
	draw_colored_polygon(crown, accent_color)
	draw_line(Vector2(-crown_width * 0.5, base_y), Vector2(crown_width * 0.5, base_y), Color(1.0, 0.78, 1.0, 1.0), 1.6)


func _get_occupied_cells(info: Dictionary) -> Dictionary:
	var anchor: Vector2i = info["anchor"]
	var occupied := {}
	for local_cell in info["footprint_cells"]:
		var cell: Vector2i = anchor + local_cell
		occupied[_cell_key(cell)] = true
	return occupied


func _draw_room_outline(occupied: Dictionary, origin: Vector2, pitch: float, viewport: Rect2) -> void:
	for key in occupied.keys():
		var cell := _cell_from_key(String(key))
		var rect := _get_room_cell_mass_rect(cell, occupied, origin, pitch)
		var left := rect.position.x
		var top := rect.position.y
		var right := rect.position.x + rect.size.x
		var bottom := rect.position.y + rect.size.y
		if not occupied.has(_cell_key(cell + Vector2i(0, -1))):
			_draw_clipped_room_edge(Vector2(left, top), Vector2(right, top), viewport)
		if not occupied.has(_cell_key(cell + Vector2i(1, 0))):
			_draw_clipped_room_edge(Vector2(right, top), Vector2(right, bottom), viewport)
		if not occupied.has(_cell_key(cell + Vector2i(0, 1))):
			_draw_clipped_room_edge(Vector2(left, bottom), Vector2(right, bottom), viewport)
		if not occupied.has(_cell_key(cell + Vector2i(-1, 0))):
			_draw_clipped_room_edge(Vector2(left, top), Vector2(left, bottom), viewport)


func _get_room_cell_mass_rect(cell: Vector2i, _occupied: Dictionary, origin: Vector2, pitch: float) -> Rect2:
	return Rect2(origin + Vector2(cell) * pitch - Vector2(cell_gap, cell_gap) * 0.5, Vector2(pitch, pitch))


func _draw_clipped_room_edge(from_point: Vector2, to_point: Vector2, viewport: Rect2) -> void:
	if not _segment_rect(from_point, to_point).grow(2.0).intersects(viewport):
		return
	var start := from_point
	var end := to_point
	if abs(from_point.y - to_point.y) <= 0.001:
		if from_point.y < viewport.position.y or from_point.y > viewport.position.y + viewport.size.y:
			return
		start.x = clamp(start.x, viewport.position.x, viewport.position.x + viewport.size.x)
		end.x = clamp(end.x, viewport.position.x, viewport.position.x + viewport.size.x)
	elif abs(from_point.x - to_point.x) <= 0.001:
		if from_point.x < viewport.position.x or from_point.x > viewport.position.x + viewport.size.x:
			return
		start.y = clamp(start.y, viewport.position.y, viewport.position.y + viewport.size.y)
		end.y = clamp(end.y, viewport.position.y, viewport.position.y + viewport.size.y)
	if start.distance_squared_to(end) <= 0.001:
		return
	draw_line(start, end, Color(0.07, 0.08, 0.1, 1.0), 1.5)


func _get_room_color(kind: String, cleared: bool) -> Color:
	match kind:
		"start":
			return Color(0.35, 0.72, 0.42, 1.0)
		"treasure":
			return Color(0.95, 0.72, 0.25, 1.0)
		"boss":
			return Color(0.82, 0.22, 0.36, 1.0) if not cleared else Color(0.5, 0.3, 0.36, 1.0)
		"challenge":
			return Color(0.74, 0.42, 0.88, 1.0) if not cleared else Color(0.42, 0.34, 0.48, 1.0)
	if cleared:
		return Color(0.32, 0.42, 0.48, 1.0)
	return Color(0.68, 0.76, 0.82, 1.0)


func _get_room_center(info: Dictionary, origin: Vector2, pitch: float) -> Vector2:
	var anchor: Vector2i = info["anchor"]
	var min_cell := Vector2i.ZERO
	var max_cell := Vector2i.ZERO
	var initialized := false
	for local_cell in info["footprint_cells"]:
		var cell: Vector2i = anchor + local_cell
		if not initialized:
			min_cell = cell
			max_cell = cell
			initialized = true
		else:
			min_cell.x = min(min_cell.x, cell.x)
			min_cell.y = min(min_cell.y, cell.y)
			max_cell.x = max(max_cell.x, cell.x)
			max_cell.y = max(max_cell.y, cell.y)
	var center_cell := (Vector2(min_cell) + Vector2(max_cell) + Vector2.ONE) * 0.5
	return origin + center_cell * pitch - Vector2(cell_gap, cell_gap) * 0.5


func _get_player_marker_center(origin: Vector2, pitch: float) -> Vector2:
	if has_current_player_position:
		var marker_cell := Vector2(floor(current_player_position.x), floor(current_player_position.y))
		var marker_fraction := current_player_position - marker_cell
		return origin + marker_cell * pitch + Vector2(marker_fraction.x * cell_size, marker_fraction.y * cell_size)
	return origin + Vector2(current_player_cell) * pitch + Vector2(cell_size, cell_size) * 0.5


func _get_connection_cell_center(info: Dictionary, local_cell, origin: Vector2, pitch: float) -> Vector2:
	if typeof(local_cell) != TYPE_VECTOR2I:
		return _get_room_center(info, origin, pitch)
	var world_cell: Vector2i = info["anchor"] + local_cell
	if not _room_contains_world_cell(info, world_cell):
		return _get_room_center(info, origin, pitch)
	return origin + Vector2(world_cell) * pitch + Vector2(pitch, pitch) * 0.5 - Vector2(cell_gap, cell_gap) * 0.5


func _room_contains_world_cell(info: Dictionary, world_cell: Vector2i) -> bool:
	var anchor: Vector2i = info["anchor"]
	for local_cell in info["footprint_cells"]:
		if anchor + local_cell == world_cell:
			return true
	return false


func _get_minimap_direction_vector(direction: String) -> Vector2:
	match direction:
		"north":
			return Vector2.UP
		"south":
			return Vector2.DOWN
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
	return Vector2.ZERO


func _get_minimap_door_tangent(direction: String) -> Vector2:
	match direction:
		"north", "south":
			return Vector2.RIGHT
		"east", "west":
			return Vector2.DOWN
	return Vector2.RIGHT


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _cell_from_key(key: String) -> Vector2i:
	var parts := key.split(",")
	if parts.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))


func _segment_rect(from_point: Vector2, to_point: Vector2) -> Rect2:
	var left: float = min(from_point.x, to_point.x)
	var top: float = min(from_point.y, to_point.y)
	var right: float = max(from_point.x, to_point.x)
	var bottom: float = max(from_point.y, to_point.y)
	return Rect2(Vector2(left, top), Vector2(max(right - left, 1.0), max(bottom - top, 1.0)))


func _find_room_info(visible_rooms: Array, room_id: String) -> Dictionary:
	for info in visible_rooms:
		if String(info["id"]) == room_id:
			return info
	return {}
