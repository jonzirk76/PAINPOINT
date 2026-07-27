extends Node2D
class_name ArenaWallBodyVisual

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

var _local_fill_rects: Array[Rect2] = []
var _edge_segments: Array[PackedVector2Array] = []
var _fill_color: Color = Color(0.16, 0.17, 0.19)
var _outline_color: Color = Color(0.5, 0.58, 0.64)
var _outline_width: float = 3.0


func configure(tile_rects: Array[Rect2], wall_body_lookup: Dictionary, fill_color: Color, outline_color: Color, outline_width: float) -> void:
	_edge_segments.clear()
	if tile_rects.is_empty():
		visible = false
		queue_redraw()
		return
	var bounds: Rect2 = _get_bounds(tile_rects)
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	position = Vector2(bounds.get_center().x, bounds.position.y + bounds.size.y)
	_local_fill_rects.clear()
	for fill_rect in ROOM_GEOMETRY_BUILDER.merge_wall_tiles(tile_rects):
		_local_fill_rects.append(Rect2(fill_rect.position - position, fill_rect.size))
	_fill_color = fill_color
	_outline_color = outline_color
	_outline_width = outline_width
	for tile in tile_rects:
		_add_exposed_tile_edges(tile, wall_body_lookup, tile_size)
	visible = bounds.size.x > 0.0 and bounds.size.y > 0.0
	queue_redraw()


func _draw() -> void:
	for fill_rect in _local_fill_rects:
		draw_rect(fill_rect, _fill_color, true)
	for segment in _edge_segments:
		if segment.size() >= 2:
			draw_line(segment[0], segment[1], _outline_color, _outline_width)


func _get_bounds(tile_rects: Array[Rect2]) -> Rect2:
	var left := INF
	var top := INF
	var right := -INF
	var bottom := -INF
	for tile in tile_rects:
		left = min(left, tile.position.x)
		top = min(top, tile.position.y)
		right = max(right, tile.position.x + tile.size.x)
		bottom = max(bottom, tile.position.y + tile.size.y)
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))


func _add_exposed_tile_edges(tile: Rect2, wall_body_lookup: Dictionary, tile_size: float) -> void:
	var cell := _tile_key_vector(tile.position, tile_size)
	var left := tile.position.x - position.x
	var top := tile.position.y - position.y
	var right := tile.position.x + tile.size.x - position.x
	var bottom := tile.position.y + tile.size.y - position.y
	if not wall_body_lookup.has(_tile_key(cell + Vector2i(0, -1))):
		_append_edge(Vector2(left, top), Vector2(right, top))
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


func _tile_key_vector(world_position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(world_position.x / tile_size)), int(round(world_position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
