extends RefCounted
class_name RoomGeometryBuilder

const CELL_SIZE := Vector2(1040.0, 600.0)
const WALL_THICKNESS := 48.0
const OPENING_WIDTH := 220.0
const TRIGGER_DEPTH := 92.0
const ENTRY_MARGIN := 96.0

const DIRECTIONS := ["north", "east", "south", "west"]
const DIRECTION_OFFSETS := {
	"north": Vector2i(0, -1),
	"south": Vector2i(0, 1),
	"east": Vector2i(1, 0),
	"west": Vector2i(-1, 0)
}


static func validate_footprint(piece_id: String, room_kind: String, cells: Array[Vector2i]) -> Dictionary:
	if cells.is_empty():
		return {"ok": false, "reason": "empty_footprint"}
	var seen := {}
	for cell in cells:
		var key := _cell_key(cell)
		if seen.has(key):
			return {"ok": false, "reason": "duplicate_cell"}
		seen[key] = true
	var max_cells := 5 if piece_id == "combat_crossroads" else 4
	if cells.size() > max_cells:
		return {"ok": false, "reason": "too_many_cells"}
	if cells.size() == 5 and piece_id != "combat_crossroads":
		return {"ok": false, "reason": "oversized_non_crossroads"}
	if (room_kind == "start" or room_kind == "treasure") and cells.size() != 1:
		return {"ok": false, "reason": "special_room_not_single_cell"}
	var min_cell := get_min_cell(cells)
	if min_cell != Vector2i.ZERO:
		return {"ok": false, "reason": "footprint_not_normalized"}
	if not _is_connected(cells):
		return {"ok": false, "reason": "disconnected_footprint"}
	return {"ok": true, "reason": ""}


static func get_min_cell(cells: Array[Vector2i]) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var min_cell := cells[0]
	for cell in cells:
		min_cell.x = min(min_cell.x, cell.x)
		min_cell.y = min(min_cell.y, cell.y)
	return min_cell


static func get_max_cell(cells: Array[Vector2i]) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var max_cell := cells[0]
	for cell in cells:
		max_cell.x = max(max_cell.x, cell.x)
		max_cell.y = max(max_cell.y, cell.y)
	return max_cell


static func get_bounds(cells: Array[Vector2i]) -> Rect2:
	var min_cell := get_min_cell(cells)
	var max_cell := get_max_cell(cells)
	var grid_size := Vector2(max_cell.x - min_cell.x + 1, max_cell.y - min_cell.y + 1)
	var size := Vector2(grid_size.x * CELL_SIZE.x, grid_size.y * CELL_SIZE.y)
	return Rect2(-size * 0.5, size)


static func get_cell_rect(cells: Array[Vector2i], local_cell: Vector2i) -> Rect2:
	var bounds := get_bounds(cells)
	return Rect2(bounds.position + Vector2(local_cell.x * CELL_SIZE.x, local_cell.y * CELL_SIZE.y), CELL_SIZE)


static func build_wall_rects(cells: Array[Vector2i], connection_edges: Dictionary = {}) -> Array[Rect2]:
	var walls: Array[Rect2] = []
	var occupied := _build_cell_lookup(cells)
	var min_cell := get_min_cell(cells)
	var max_cell := get_max_cell(cells)
	for x in range(min_cell.x, max_cell.x + 1):
		for y in range(min_cell.y, max_cell.y + 1):
			var cell := Vector2i(x, y)
			if not occupied.has(_cell_key(cell)):
				walls.append(get_cell_rect(cells, cell))
	for cell in cells:
		for direction in DIRECTIONS:
			var neighbor: Vector2i = cell + DIRECTION_OFFSETS.get(direction, Vector2i.ZERO)
			if occupied.has(_cell_key(neighbor)):
				continue
			var opening := Rect2()
			if _connection_uses_cell_edge(connection_edges, direction, cell):
				opening = get_opening_rect(cells, cell, direction)
			for wall_rect in _build_edge_wall_rects(cells, cell, direction, opening):
				walls.append(wall_rect)
	return walls


static func get_opening_rect(cells: Array[Vector2i], local_cell: Vector2i, direction: String) -> Rect2:
	var cell_rect := get_cell_rect(cells, local_cell)
	match direction:
		"north":
			return Rect2(Vector2(cell_rect.get_center().x - OPENING_WIDTH * 0.5, cell_rect.position.y), Vector2(OPENING_WIDTH, WALL_THICKNESS))
		"south":
			return Rect2(Vector2(cell_rect.get_center().x - OPENING_WIDTH * 0.5, cell_rect.position.y + cell_rect.size.y - WALL_THICKNESS), Vector2(OPENING_WIDTH, WALL_THICKNESS))
		"east":
			return Rect2(Vector2(cell_rect.position.x + cell_rect.size.x - WALL_THICKNESS, cell_rect.get_center().y - OPENING_WIDTH * 0.5), Vector2(WALL_THICKNESS, OPENING_WIDTH))
		"west":
			return Rect2(Vector2(cell_rect.position.x, cell_rect.get_center().y - OPENING_WIDTH * 0.5), Vector2(WALL_THICKNESS, OPENING_WIDTH))
	return Rect2()


static func get_trigger_rect(cells: Array[Vector2i], local_cell: Vector2i, direction: String) -> Rect2:
	var cell_rect := get_cell_rect(cells, local_cell)
	match direction:
		"north":
			return Rect2(Vector2(cell_rect.get_center().x - OPENING_WIDTH * 0.5, cell_rect.position.y - TRIGGER_DEPTH * 0.25), Vector2(OPENING_WIDTH, TRIGGER_DEPTH))
		"south":
			return Rect2(Vector2(cell_rect.get_center().x - OPENING_WIDTH * 0.5, cell_rect.position.y + cell_rect.size.y - TRIGGER_DEPTH * 0.75), Vector2(OPENING_WIDTH, TRIGGER_DEPTH))
		"east":
			return Rect2(Vector2(cell_rect.position.x + cell_rect.size.x - TRIGGER_DEPTH * 0.75, cell_rect.get_center().y - OPENING_WIDTH * 0.5), Vector2(TRIGGER_DEPTH, OPENING_WIDTH))
		"west":
			return Rect2(Vector2(cell_rect.position.x - TRIGGER_DEPTH * 0.25, cell_rect.get_center().y - OPENING_WIDTH * 0.5), Vector2(TRIGGER_DEPTH, OPENING_WIDTH))
	return Rect2()


static func get_entry_position(cells: Array[Vector2i], local_cell: Vector2i, direction: String) -> Vector2:
	var cell_rect := get_cell_rect(cells, local_cell)
	match direction:
		"north":
			return Vector2(cell_rect.get_center().x, cell_rect.position.y + ENTRY_MARGIN)
		"south":
			return Vector2(cell_rect.get_center().x, cell_rect.position.y + cell_rect.size.y - ENTRY_MARGIN)
		"east":
			return Vector2(cell_rect.position.x + cell_rect.size.x - ENTRY_MARGIN, cell_rect.get_center().y)
		"west":
			return Vector2(cell_rect.position.x + ENTRY_MARGIN, cell_rect.get_center().y)
	return cell_rect.get_center()


static func get_spawn_position(cells: Array[Vector2i]) -> Vector2:
	if cells.is_empty():
		return Vector2.ZERO
	var bounds := get_bounds(cells)
	var target := bounds.get_center()
	var best_cell := cells[0]
	var best_distance := INF
	for cell in cells:
		var center := get_cell_rect(cells, cell).get_center()
		var distance := center.distance_squared_to(target)
		if distance < best_distance:
			best_cell = cell
			best_distance = distance
	return get_cell_rect(cells, best_cell).get_center()


static func get_door_clear_rect(cells: Array[Vector2i], local_cell: Vector2i, direction: String) -> Rect2:
	var entry := get_entry_position(cells, local_cell, direction)
	match direction:
		"north", "south":
			return Rect2(entry - Vector2(90.0, 110.0), Vector2(180.0, 220.0))
		"east", "west":
			return Rect2(entry - Vector2(110.0, 90.0), Vector2(220.0, 180.0))
	return Rect2(entry - Vector2(150.0, 150.0), Vector2(300.0, 300.0))


static func find_contact_edge(source_cells: Array[Vector2i], source_anchor: Vector2i, target_cells: Array[Vector2i], target_anchor: Vector2i, direction: String) -> Dictionary:
	var target_lookup := {}
	for target_cell in target_cells:
		target_lookup[_cell_key(target_anchor + target_cell)] = target_cell
	for source_cell in source_cells:
		var world_cell := source_anchor + source_cell
		var target_world: Vector2i = world_cell + DIRECTION_OFFSETS.get(direction, Vector2i.ZERO)
		var key := _cell_key(target_world)
		if target_lookup.has(key):
			return {
				"source_cell": source_cell,
				"target_cell": target_lookup[key]
			}
	return {}


static func _build_edge_wall_rects(cells: Array[Vector2i], local_cell: Vector2i, direction: String, opening: Rect2) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var cell_rect := get_cell_rect(cells, local_cell)
	var full_rect := Rect2()
	match direction:
		"north":
			full_rect = Rect2(cell_rect.position, Vector2(cell_rect.size.x, WALL_THICKNESS))
		"south":
			full_rect = Rect2(Vector2(cell_rect.position.x, cell_rect.position.y + cell_rect.size.y - WALL_THICKNESS), Vector2(cell_rect.size.x, WALL_THICKNESS))
		"east":
			full_rect = Rect2(Vector2(cell_rect.position.x + cell_rect.size.x - WALL_THICKNESS, cell_rect.position.y), Vector2(WALL_THICKNESS, cell_rect.size.y))
		"west":
			full_rect = Rect2(cell_rect.position, Vector2(WALL_THICKNESS, cell_rect.size.y))
	if opening.size == Vector2.ZERO:
		rects.append(full_rect)
		return rects
	if direction == "north" or direction == "south":
		var left_width: float = max(opening.position.x - full_rect.position.x, 0.0)
		var right_x: float = opening.position.x + opening.size.x
		var right_width: float = max(full_rect.position.x + full_rect.size.x - right_x, 0.0)
		if left_width > 1.0:
			rects.append(Rect2(full_rect.position, Vector2(left_width, full_rect.size.y)))
		if right_width > 1.0:
			rects.append(Rect2(Vector2(right_x, full_rect.position.y), Vector2(right_width, full_rect.size.y)))
	else:
		var top_height: float = max(opening.position.y - full_rect.position.y, 0.0)
		var bottom_y: float = opening.position.y + opening.size.y
		var bottom_height: float = max(full_rect.position.y + full_rect.size.y - bottom_y, 0.0)
		if top_height > 1.0:
			rects.append(Rect2(full_rect.position, Vector2(full_rect.size.x, top_height)))
		if bottom_height > 1.0:
			rects.append(Rect2(Vector2(full_rect.position.x, bottom_y), Vector2(full_rect.size.x, bottom_height)))
	return rects


static func _connection_uses_cell_edge(connection_edges: Dictionary, direction: String, local_cell: Vector2i) -> bool:
	if not connection_edges.has(direction):
		return false
	var edge := Dictionary(connection_edges[direction])
	return edge.has("source_cell") and edge["source_cell"] == local_cell


static func _build_cell_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		lookup[_cell_key(cell)] = true
	return lookup


static func _is_connected(cells: Array[Vector2i]) -> bool:
	var lookup := _build_cell_lookup(cells)
	var start := cells[0]
	var visited := {_cell_key(start): true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for direction in DIRECTIONS:
			var next: Vector2i = cell + DIRECTION_OFFSETS.get(direction, Vector2i.ZERO)
			var key := _cell_key(next)
			if not lookup.has(key) or visited.has(key):
				continue
			visited[key] = true
			queue.append(next)
	return visited.size() == cells.size()


static func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
