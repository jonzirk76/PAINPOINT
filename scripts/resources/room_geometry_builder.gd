extends RefCounted
class_name RoomGeometryBuilder

const CELL_SIZE := Vector2(1280.0, 720.0)
const CELL_TILE_COLUMNS := 32
const CELL_TILE_ROWS := 18
const WALL_TILE_SIZE: float = CELL_SIZE.x / float(CELL_TILE_COLUMNS)
const WALL_THICKNESS := WALL_TILE_SIZE
const OPENING_WIDTH := WALL_TILE_SIZE * 4.0
const TRIGGER_DEPTH := WALL_TILE_SIZE * 2.0
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
	var wall_top_tiles := build_wall_tile_rects(cells, connection_edges)
	return merge_wall_tiles(build_wall_body_tile_rects(wall_top_tiles, cells, connection_edges))


static func get_exposed_edges(cells: Array[Vector2i], facing_direction: String = "") -> Array[Dictionary]:
	var occupied := _build_cell_lookup(cells)
	var edges: Array[Dictionary] = []
	for cell in cells:
		for direction in DIRECTIONS:
			if not facing_direction.is_empty() and direction != facing_direction:
				continue
			var neighbor: Vector2i = cell + DIRECTION_OFFSETS[direction]
			if occupied.has(_cell_key(neighbor)):
				continue
			edges.append({
				"cell": cell,
				"direction": direction
			})
	return edges


static func build_wall_tile_rects(cells: Array[Vector2i], connection_edges: Dictionary = {}) -> Array[Rect2]:
	var walls: Array[Rect2] = []
	var wall_lookup := {}
	var footprint_tiles := _build_footprint_tile_lookup(cells)
	for cell in cells:
		var cell_rect := get_cell_rect(cells, cell)
		for tile_x in range(CELL_TILE_COLUMNS):
			for tile_y in range(CELL_TILE_ROWS):
				var tile_coord := _cell_tile_coord(cell, tile_x, tile_y)
				var exposed_directions := _get_exposed_envelope_directions(tile_coord, footprint_tiles)
				if exposed_directions.is_empty():
					continue
				var tile := Rect2(cell_rect.position + Vector2(float(tile_x) * WALL_TILE_SIZE, float(tile_y) * WALL_TILE_SIZE), Vector2(WALL_TILE_SIZE, WALL_TILE_SIZE))
				if _envelope_tile_is_wall(cells, cell, tile, exposed_directions, connection_edges):
					_append_unique_wall_tile(walls, wall_lookup, tile)
	return walls


static func build_wall_body_tile_rects(wall_top_tiles: Array[Rect2], cells: Array[Vector2i], connection_edges: Dictionary = {}) -> Array[Rect2]:
	var body_tiles: Array[Rect2] = []
	var body_lookup := {}
	var opening_rects := _get_connection_opening_rects(cells, connection_edges)
	for wall_top in wall_top_tiles:
		var body_tile := Rect2(wall_top.position + Vector2(0.0, WALL_TILE_SIZE), wall_top.size)
		if not _rect_fits_footprint(cells, body_tile):
			continue
		if _tile_is_inside_any_opening(body_tile, opening_rects):
			continue
		_append_unique_wall_tile(body_tiles, body_lookup, body_tile)
	return body_tiles


static func rects_to_wall_tiles(rects: Array[Rect2]) -> Array[Rect2]:
	var tiles: Array[Rect2] = []
	for rect in rects:
		tiles.append_array(_rect_to_wall_tiles(rect))
	return tiles


static func snap_rect_to_tile_grid(rect: Rect2) -> Rect2:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Rect2()
	var left: float = floor(rect.position.x / WALL_TILE_SIZE) * WALL_TILE_SIZE
	var top: float = floor(rect.position.y / WALL_TILE_SIZE) * WALL_TILE_SIZE
	var right: float = ceil((rect.position.x + rect.size.x) / WALL_TILE_SIZE) * WALL_TILE_SIZE
	var bottom: float = ceil((rect.position.y + rect.size.y) / WALL_TILE_SIZE) * WALL_TILE_SIZE
	return Rect2(Vector2(left, top), Vector2(max(right - left, WALL_TILE_SIZE), max(bottom - top, WALL_TILE_SIZE)))


static func merge_wall_tiles(tiles: Array[Rect2]) -> Array[Rect2]:
	var rows := {}
	for tile in tiles:
		var key := "%d:%d" % [int(round(tile.position.y)), int(round(tile.size.y))]
		var row: Array = rows.get(key, [])
		row.append(tile)
		rows[key] = row
	var horizontal: Array[Rect2] = []
	for key in rows.keys():
		var row: Array = rows[key]
		row.sort_custom(func(a: Rect2, b: Rect2) -> bool:
			return a.position.x < b.position.x
		)
		var current: Rect2 = row[0]
		for index in range(1, row.size()):
			var next: Rect2 = row[index]
			var touches: bool = abs((current.position.x + current.size.x) - next.position.x) <= 0.5
			if touches and abs(current.position.y - next.position.y) <= 0.5 and abs(current.size.y - next.size.y) <= 0.5:
				current.size.x += next.size.x
			else:
				horizontal.append(current)
				current = next
		horizontal.append(current)
	var columns := {}
	for rect in horizontal:
		var key := "%d:%d:%d" % [int(round(rect.position.x)), int(round(rect.size.x)), int(round(rect.size.y))]
		var column: Array = columns.get(key, [])
		column.append(rect)
		columns[key] = column
	var merged: Array[Rect2] = []
	for key in columns.keys():
		var column: Array = columns[key]
		column.sort_custom(func(a: Rect2, b: Rect2) -> bool:
			return a.position.y < b.position.y
		)
		var current: Rect2 = column[0]
		for index in range(1, column.size()):
			var next: Rect2 = column[index]
			var touches: bool = abs((current.position.y + current.size.y) - next.position.y) <= 0.5
			if touches and abs(current.position.x - next.position.x) <= 0.5 and abs(current.size.x - next.size.x) <= 0.5:
				current.size.y += next.size.y
			else:
				merged.append(current)
				current = next
		merged.append(current)
	return merged


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
	var cell_rect := get_cell_rect(cells, local_cell)
	var opening := get_opening_rect(cells, local_cell, direction)
	var clear_width: float = max(OPENING_WIDTH - WALL_TILE_SIZE, WALL_TILE_SIZE * 2.0)
	var clear_depth: float = WALL_TILE_SIZE * 3.0
	var center := opening.get_center()
	match direction:
		"north":
			return Rect2(Vector2(center.x - clear_width * 0.5, cell_rect.position.y + WALL_THICKNESS), Vector2(clear_width, clear_depth))
		"south":
			return Rect2(Vector2(center.x - clear_width * 0.5, cell_rect.position.y + cell_rect.size.y - WALL_THICKNESS - clear_depth), Vector2(clear_width, clear_depth))
		"east":
			return Rect2(Vector2(cell_rect.position.x + cell_rect.size.x - WALL_THICKNESS - clear_depth, center.y - clear_width * 0.5), Vector2(clear_depth, clear_width))
		"west":
			return Rect2(Vector2(cell_rect.position.x + WALL_THICKNESS, center.y - clear_width * 0.5), Vector2(clear_depth, clear_width))
	return Rect2(cell_rect.get_center() - Vector2(150.0, 150.0), Vector2(300.0, 300.0))


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


static func _envelope_tile_is_wall(cells: Array[Vector2i], local_cell: Vector2i, tile: Rect2, exposed_directions: Array[String], connection_edges: Dictionary) -> bool:
	var has_opening_edge := false
	for direction in exposed_directions:
		if _tile_is_inside_connection_opening(tile, cells, local_cell, direction, connection_edges):
			has_opening_edge = true
		else:
			return true
	return not has_opening_edge


static func _build_footprint_tile_lookup(cells: Array[Vector2i]) -> Dictionary:
	var lookup := {}
	for cell in cells:
		for tile_x in range(CELL_TILE_COLUMNS):
			for tile_y in range(CELL_TILE_ROWS):
				lookup[_tile_coord_key(_cell_tile_coord(cell, tile_x, tile_y))] = true
	return lookup


static func _get_exposed_envelope_directions(tile_coord: Vector2i, footprint_tiles: Dictionary) -> Array[String]:
	var exposed: Array[String] = []
	if not footprint_tiles.has(_tile_coord_key(tile_coord + DIRECTION_OFFSETS["north"])):
		exposed.append("north")
	if not footprint_tiles.has(_tile_coord_key(tile_coord + DIRECTION_OFFSETS["south"])):
		exposed.append("south")
	if not footprint_tiles.has(_tile_coord_key(tile_coord + DIRECTION_OFFSETS["east"])):
		exposed.append("east")
	if not footprint_tiles.has(_tile_coord_key(tile_coord + DIRECTION_OFFSETS["west"])):
		exposed.append("west")
	if exposed.is_empty() and _tile_has_diagonal_exposure(tile_coord, footprint_tiles):
		exposed.append("corner")
	return exposed


static func _tile_has_diagonal_exposure(tile_coord: Vector2i, footprint_tiles: Dictionary) -> bool:
	var diagonals := [
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1)
	]
	for offset in diagonals:
		if not footprint_tiles.has(_tile_coord_key(tile_coord + offset)):
			return true
	return false


static func _cell_tile_coord(cell: Vector2i, tile_x: int, tile_y: int) -> Vector2i:
	return Vector2i(cell.x * CELL_TILE_COLUMNS + tile_x, cell.y * CELL_TILE_ROWS + tile_y)


static func _tile_coord_key(tile_coord: Vector2i) -> String:
	return "%d,%d" % [tile_coord.x, tile_coord.y]


static func _rect_to_wall_tiles(rect: Rect2) -> Array[Rect2]:
	var tiles: Array[Rect2] = []
	var snapped_rect := snap_rect_to_tile_grid(rect)
	var cols: int = int(round(snapped_rect.size.x / WALL_TILE_SIZE))
	var rows: int = int(round(snapped_rect.size.y / WALL_TILE_SIZE))
	for x in range(cols):
		for y in range(rows):
			var position := snapped_rect.position + Vector2(float(x) * WALL_TILE_SIZE, float(y) * WALL_TILE_SIZE)
			tiles.append(Rect2(position, Vector2(WALL_TILE_SIZE, WALL_TILE_SIZE)))
	return tiles


static func _tile_is_inside_opening(tile: Rect2, opening: Rect2) -> bool:
	if opening.size == Vector2.ZERO:
		return false
	return opening.has_point(tile.get_center())


static func _tile_is_inside_connection_opening(tile: Rect2, cells: Array[Vector2i], local_cell: Vector2i, direction: String, connection_edges: Dictionary) -> bool:
	if not _connection_uses_cell_edge(connection_edges, direction, local_cell):
		return false
	return _tile_is_inside_opening(tile, get_opening_rect(cells, local_cell, direction))


static func _tile_is_inside_any_opening(tile: Rect2, opening_rects: Array[Rect2]) -> bool:
	for opening in opening_rects:
		if _tile_is_inside_opening(tile, opening):
			return true
	return false


static func _get_connection_opening_rects(cells: Array[Vector2i], connection_edges: Dictionary) -> Array[Rect2]:
	var opening_rects: Array[Rect2] = []
	for direction in DIRECTIONS:
		if not connection_edges.has(direction):
			continue
		var edge := Dictionary(connection_edges[direction])
		if not edge.has("source_cell"):
			continue
		opening_rects.append(get_opening_rect(cells, edge.get("source_cell", Vector2i.ZERO), direction))
	return opening_rects


static func _rect_fits_footprint(cells: Array[Vector2i], rect: Rect2) -> bool:
	if cells.is_empty() or rect.size.x <= 0.0 or rect.size.y <= 0.0:
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
		if not _point_is_in_footprint(cells, point):
			return false
	return true


static func _point_is_in_footprint(cells: Array[Vector2i], point: Vector2) -> bool:
	var epsilon := 0.5
	for cell in cells:
		var rect := get_cell_rect(cells, cell)
		if point.x >= rect.position.x - epsilon and point.y >= rect.position.y - epsilon and point.x <= rect.position.x + rect.size.x + epsilon and point.y <= rect.position.y + rect.size.y + epsilon:
			return true
	return false


static func _append_unique_wall_tile(walls: Array[Rect2], wall_lookup: Dictionary, tile: Rect2) -> void:
	var key := _rect_tile_key(tile)
	if wall_lookup.has(key):
		return
	wall_lookup[key] = true
	walls.append(tile)


static func _rect_tile_key(rect: Rect2) -> String:
	return "%d,%d,%d,%d" % [
		int(round(rect.position.x)),
		int(round(rect.position.y)),
		int(round(rect.size.x)),
		int(round(rect.size.y))
	]


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
