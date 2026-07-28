extends Node2D
class_name ArenaWallBodyVisual

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

var _local_fill_rects: Array[Rect2] = []
var _local_top_fill_rects: Array[Rect2] = []
var _edge_segments: Array[PackedVector2Array] = []
var _top_edge_segments: Array[PackedVector2Array] = []
var _fill_color: Color = Color(0.16, 0.17, 0.19)
var _outline_color: Color = Color(0.5, 0.58, 0.64)
var _top_fill_color: Color = Color(0.09, 0.1, 0.12)
var _top_outline_color: Color = Color(0.72, 0.78, 0.82)
var _outline_width: float = 3.0


func configure(
	tile_rects: Array[Rect2],
	top_tile_rects: Array[Rect2],
	wall_body_lookup: Dictionary,
	wall_top_lookup: Dictionary,
	opaque_fog_rects: Array[Rect2],
	wall_height_tiles: int,
	fill_color: Color,
	outline_color: Color,
	top_fill_color: Color,
	top_outline_color: Color,
	outline_width: float
) -> void:
	_edge_segments.clear()
	_top_edge_segments.clear()
	if tile_rects.is_empty() and top_tile_rects.is_empty():
		visible = false
		queue_redraw()
		return
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var floor_y: float = _get_floor_y(tile_rects, top_tile_rects, tile_size, wall_height_tiles)
	position = Vector2.ZERO
	position.y = floor_y
	_local_fill_rects.clear()
	for fill_rect in ROOM_GEOMETRY_BUILDER.merge_wall_tiles(tile_rects):
		_local_fill_rects.append(Rect2(fill_rect.position - position, fill_rect.size))
	_local_top_fill_rects.clear()
	for fill_rect in ROOM_GEOMETRY_BUILDER.merge_wall_tiles(top_tile_rects):
		_local_top_fill_rects.append(Rect2(fill_rect.position - position, fill_rect.size))
	_fill_color = fill_color
	_outline_color = outline_color
	_top_fill_color = top_fill_color
	_top_outline_color = top_outline_color
	_outline_width = outline_width
	for tile in tile_rects:
		_add_exposed_tile_edges(tile, wall_body_lookup, tile_size)
	for tile in top_tile_rects:
		_add_top_tile_edges(
			tile,
			wall_top_lookup,
			opaque_fog_rects,
			tile_size,
			wall_height_tiles
		)
	visible = true
	queue_redraw()


func _draw() -> void:
	for fill_rect in _local_fill_rects:
		draw_rect(fill_rect, _fill_color, true)
	for fill_rect in _local_top_fill_rects:
		draw_rect(fill_rect, _top_fill_color, true)
	for segment in _edge_segments:
		if segment.size() >= 2:
			draw_line(segment[0], segment[1], _outline_color, _outline_width)
	for segment in _top_edge_segments:
		if segment.size() >= 2:
			draw_line(segment[0], segment[1], _top_outline_color, _outline_width)


func _get_floor_y(
	tile_rects: Array[Rect2],
	top_tile_rects: Array[Rect2],
	tile_size: float,
	wall_height_tiles: int
) -> float:
	if not tile_rects.is_empty():
		var floor_y: float = -INF
		for tile in tile_rects:
			floor_y = max(floor_y, tile.end.y)
		return floor_y
	return top_tile_rects[0].end.y + tile_size * float(wall_height_tiles)


func _add_exposed_tile_edges(tile: Rect2, wall_body_lookup: Dictionary, tile_size: float) -> void:
	var cell := _tile_key_vector(tile.position, tile_size)
	var left := tile.position.x - position.x
	var top := tile.position.y - position.y
	var right := tile.position.x + tile.size.x - position.x
	var bottom := tile.position.y + tile.size.y - position.y
	if not wall_body_lookup.has(_tile_key(cell + Vector2i(0, 1))):
		_append_edge(Vector2(left, bottom), Vector2(right, bottom))
	if not wall_body_lookup.has(_tile_key(cell + Vector2i(-1, 0))):
		_append_edge(Vector2(left, top), Vector2(left, bottom))
	if not wall_body_lookup.has(_tile_key(cell + Vector2i(1, 0))):
		_append_edge(Vector2(right, top), Vector2(right, bottom))


func _append_edge(start: Vector2, end: Vector2) -> void:
	var segment := PackedVector2Array()
	segment.append(start)
	segment.append(end)
	_edge_segments.append(segment)


func _append_top_edge(start: Vector2, end: Vector2) -> void:
	var segment := PackedVector2Array()
	segment.append(start)
	segment.append(end)
	_top_edge_segments.append(segment)


func _add_top_tile_edges(
	tile: Rect2,
	wall_top_lookup: Dictionary,
	opaque_fog_rects: Array[Rect2],
	tile_size: float,
	wall_height_tiles: int
) -> void:
	var cell := _tile_key_vector(tile.position, tile_size)
	var left: float = tile.position.x - position.x
	var top: float = tile.position.y - position.y
	var right: float = tile.end.x - position.x
	var bottom: float = tile.end.y - position.y
	var south_exposed: bool = not wall_top_lookup.has(_tile_key(cell + Vector2i(0, 1)))
	var west_exposed: bool = not wall_top_lookup.has(_tile_key(cell + Vector2i(-1, 0)))
	var east_exposed: bool = not wall_top_lookup.has(_tile_key(cell + Vector2i(1, 0)))
	if not wall_top_lookup.has(_tile_key(cell + Vector2i(0, -1))):
		_append_top_edge(Vector2(left, top), Vector2(right, top))
	if south_exposed:
		_append_top_edge(Vector2(left, bottom), Vector2(right, bottom))
		var height_offset: float = tile_size * float(wall_height_tiles)
		var south_start := Vector2(tile.position.x, tile.end.y + height_offset)
		var south_end := Vector2(tile.end.x, tile.end.y + height_offset)
		if (
			not _horizontal_segment_intersects_wall_top(south_start, south_end, wall_top_lookup, tile_size)
			and not _segment_intersects_rects(south_start, south_end, opaque_fog_rects)
		):
			_append_top_edge(south_start - position, south_end - position)
		if west_exposed:
			var west_start := Vector2(tile.position.x, tile.end.y)
			var west_end := Vector2(tile.position.x, tile.end.y + height_offset)
			if not _segment_intersects_rects(west_start, west_end, opaque_fog_rects):
				_append_top_edge(west_start - position, west_end - position)
		if east_exposed:
			var east_start := Vector2(tile.end.x, tile.end.y)
			var east_end := Vector2(tile.end.x, tile.end.y + height_offset)
			if not _segment_intersects_rects(east_start, east_end, opaque_fog_rects):
				_append_top_edge(east_start - position, east_end - position)
	if west_exposed:
		_append_top_edge(Vector2(left, top), Vector2(left, bottom))
	if east_exposed:
		_append_top_edge(Vector2(right, top), Vector2(right, bottom))


func _horizontal_segment_intersects_wall_top(
	start: Vector2,
	end: Vector2,
	wall_top_lookup: Dictionary,
	tile_size: float
) -> bool:
	var first_x: int = floori(min(start.x, end.x) / tile_size)
	var last_x: int = ceili(max(start.x, end.x) / tile_size) - 1
	var cell_y: int = floori(start.y / tile_size)
	for cell_x in range(first_x, last_x + 1):
		if wall_top_lookup.has(_tile_key(Vector2i(cell_x, cell_y))):
			return true
	return false


func _segment_intersects_rects(start: Vector2, end: Vector2, rects: Array[Rect2]) -> bool:
	var segment_rect := Rect2(
		Vector2(min(start.x, end.x), min(start.y, end.y)),
		Vector2(abs(end.x - start.x), abs(end.y - start.y))
	).grow(max(_outline_width, 1.0))
	for rect in rects:
		if rect.intersects(segment_rect, true):
			return true
	return false


func _tile_key_vector(world_position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(world_position.x / tile_size)), int(round(world_position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
