extends Node2D
class_name ArenaWallTopOverlay

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

var _tile_rects: Array[Rect2] = []
var _draw_rects: Array[Rect2] = []
var _fog_rects: Array[Rect2] = []
var _dim_rects: Array[Rect2] = []
var _fill_color: Color = Color(0.09, 0.1, 0.12)
var _outline_color: Color = Color(0.72, 0.78, 0.82)
var _outline_width: float = 2.0


func configure(tile_rects: Array[Rect2], draw_rects: Array[Rect2], fog_rects: Array[Rect2], dim_rects: Array[Rect2], fill_color: Color, outline_color: Color, outline_width: float) -> void:
	_tile_rects = tile_rects.duplicate()
	_draw_rects = draw_rects.duplicate()
	_fog_rects = fog_rects.duplicate()
	_dim_rects = dim_rects.duplicate()
	_fill_color = fill_color
	_outline_color = outline_color
	_outline_width = outline_width
	visible = not _tile_rects.is_empty() or not _fog_rects.is_empty() or not _dim_rects.is_empty()
	queue_redraw()


func clear() -> void:
	_tile_rects.clear()
	_draw_rects.clear()
	_fog_rects.clear()
	_dim_rects.clear()
	visible = false
	queue_redraw()


func _draw() -> void:
	if not _tile_rects.is_empty():
		_draw_tile_mass(_tile_rects, _draw_rects, _fill_color, _outline_color, _outline_width)
	_draw_dim()
	_draw_fog()


func _draw_tile_mass(tile_rects: Array[Rect2], fill_rects: Array[Rect2], fill_color: Color, outline_color: Color, outline_width: float) -> void:
	for rect in fill_rects:
		draw_rect(rect, fill_color, true)
	var lookup := _build_tile_lookup(tile_rects)
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for tile in tile_rects:
		var cell := _tile_key_vector(tile.position, tile_size)
		var left := tile.position.x
		var top := tile.position.y
		var right := tile.position.x + tile.size.x
		var bottom := tile.position.y + tile.size.y
		if not lookup.has(_tile_key(cell + Vector2i(0, -1))):
			draw_line(Vector2(left, top), Vector2(right, top), outline_color, outline_width)
		if not lookup.has(_tile_key(cell + Vector2i(0, 1))):
			draw_line(Vector2(left, bottom), Vector2(right, bottom), outline_color, outline_width)
		if not lookup.has(_tile_key(cell + Vector2i(-1, 0))):
			draw_line(Vector2(left, top), Vector2(left, bottom), outline_color, outline_width)
		if not lookup.has(_tile_key(cell + Vector2i(1, 0))):
			draw_line(Vector2(right, top), Vector2(right, bottom), outline_color, outline_width)


func _build_tile_lookup(tile_rects: Array[Rect2]) -> Dictionary:
	var lookup := {}
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in tile_rects:
		lookup[_tile_key(_tile_key_vector(rect.position, tile_size))] = true
	return lookup


func _draw_fog() -> void:
	if _fog_rects.is_empty():
		return
	for rect in _fog_rects:
		draw_rect(rect.grow(4.0), Color.BLACK, true)
		draw_rect(rect.grow(-2.0), Color(0.03, 0.09, 0.1, 0.34), false, 2.0)


func _draw_dim() -> void:
	if _dim_rects.is_empty():
		return
	for rect in _dim_rects:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.36), true)


func _tile_key_vector(world_position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(world_position.x / tile_size)), int(round(world_position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
