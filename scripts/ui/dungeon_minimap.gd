extends Control
class_name DungeonMinimap

@export var cell_size: float = 24.0
@export var cell_gap: float = 3.0
@export var padding: float = 12.0

var rooms: Array = []
var current_room_id: String = ""


func set_map(room_infos: Array, current_id: String) -> void:
	rooms = room_infos
	current_room_id = current_id
	visible = not rooms.is_empty()
	queue_redraw()


func clear_map() -> void:
	rooms.clear()
	current_room_id = ""
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
	var map_size := Vector2(float(bounds.size.x) * pitch - cell_gap, float(bounds.size.y) * pitch - cell_gap)
	var origin := (size - map_size) * 0.5 - Vector2(bounds.position) * pitch
	_draw_connections(visible_rooms, origin, pitch)
	for info in visible_rooms:
		_draw_room(info, origin, pitch)


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


func _draw_connections(visible_rooms: Array, origin: Vector2, pitch: float) -> void:
	var visible_ids := {}
	for info in visible_rooms:
		visible_ids[String(info["id"])] = true
	for info in visible_rooms:
		var from_id := String(info["id"])
		var from_center := _get_room_center(info, origin, pitch)
		var connections: Dictionary = info["connections"]
		for direction in connections.keys():
			var to_id := String(connections[direction])
			if not visible_ids.has(to_id) or from_id > to_id:
				continue
			var target_info = _find_room_info(visible_rooms, to_id)
			if target_info.is_empty():
				continue
			draw_line(from_center, _get_room_center(target_info, origin, pitch), Color(0.46, 0.56, 0.62, 0.95), 4.0)


func _draw_room(info: Dictionary, origin: Vector2, pitch: float) -> void:
	var room_color := _get_room_color(String(info.get("kind", "combat")), bool(info.get("cleared", false)))
	var is_current := String(info["id"]) == current_room_id
	if is_current:
		room_color = Color(0.36, 0.82, 1.0, 1.0)
	var anchor: Vector2i = info["anchor"]
	for local_cell in info["footprint_cells"]:
		var cell: Vector2i = anchor + local_cell
		var rect := Rect2(origin + Vector2(cell) * pitch, Vector2(cell_size, cell_size))
		draw_rect(rect, room_color, true)
		draw_rect(rect, Color(0.07, 0.08, 0.1, 1.0), false, 1.5)
	if is_current:
		var center := _get_room_center(info, origin, pitch)
		draw_circle(center, 5.5, Color(1.0, 0.96, 0.34, 1.0))
		draw_arc(center, 8.5, 0.0, TAU, 24, Color(0.04, 0.05, 0.06, 1.0), 2.0)


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


func _find_room_info(visible_rooms: Array, room_id: String) -> Dictionary:
	for info in visible_rooms:
		if String(info["id"]) == room_id:
			return info
	return {}
