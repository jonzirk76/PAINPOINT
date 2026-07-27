extends Node2D
class_name ArenaWallTopOverlay

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

var _tile_rects: Array[Rect2] = []
var _draw_rects: Array[Rect2] = []
var _opaque_fog_rects: Array[Rect2] = []
var _dim_rects: Array[Rect2] = []
var _wall_height_tiles: int = ROOM_GEOMETRY_BUILDER.DEFAULT_WALL_HEIGHT_TILES
var _fill_color: Color = Color(0.09, 0.1, 0.12)
var _outline_color: Color = Color(0.72, 0.78, 0.82)
var _outline_width: float = 2.0


func configure(tile_rects: Array[Rect2], draw_rects: Array[Rect2], opaque_fog_rects: Array[Rect2], dim_rects: Array[Rect2], wall_height_tiles: int, fill_color: Color, outline_color: Color, outline_width: float) -> void:
	_tile_rects = tile_rects.duplicate()
	_draw_rects = draw_rects.duplicate()
	_opaque_fog_rects = opaque_fog_rects.duplicate()
	_dim_rects = dim_rects.duplicate()
	_wall_height_tiles = max(wall_height_tiles, 1)
	_fill_color = fill_color
	_outline_color = outline_color
	_outline_width = outline_width
	visible = not _tile_rects.is_empty() or not _dim_rects.is_empty()
	queue_redraw()


func clear() -> void:
	_tile_rects.clear()
	_draw_rects.clear()
	_opaque_fog_rects.clear()
	_dim_rects.clear()
	visible = false
	queue_redraw()


func _draw() -> void:
	if not _tile_rects.is_empty():
		_draw_tile_mass(_tile_rects, _draw_rects, _fill_color, _outline_color, _outline_width)
	_draw_dim()


func _draw_tile_mass(tile_rects: Array[Rect2], fill_rects: Array[Rect2], fill_color: Color, outline_color: Color, outline_width: float) -> void:
	for rect in fill_rects:
		draw_rect(rect, fill_color, true)
	var lookup := _build_tile_lookup(tile_rects)
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var height_offset: float = tile_size * float(_wall_height_tiles)
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
			var south_start := Vector2(left, bottom + height_offset)
			var south_end := Vector2(right, bottom + height_offset)
			if not _segment_intersects_opaque_fog(south_start, south_end):
				draw_line(
					south_start,
					south_end,
					outline_color,
					outline_width
				)
		if not lookup.has(_tile_key(cell + Vector2i(-1, 0))):
			draw_line(Vector2(left, top), Vector2(left, bottom), outline_color, outline_width)
			var west_start := Vector2(left, bottom)
			var west_end := Vector2(left, bottom + height_offset)
			if not _segment_intersects_opaque_fog(west_start, west_end):
				draw_line(
					west_start,
					west_end,
					outline_color,
					outline_width
				)
		if not lookup.has(_tile_key(cell + Vector2i(1, 0))):
			draw_line(Vector2(right, top), Vector2(right, bottom), outline_color, outline_width)
			var east_start := Vector2(right, bottom)
			var east_end := Vector2(right, bottom + height_offset)
			if not _segment_intersects_opaque_fog(east_start, east_end):
				draw_line(
					east_start,
					east_end,
					outline_color,
					outline_width
				)

func _build_tile_lookup(tile_rects: Array[Rect2]) -> Dictionary:
	var lookup := {}
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in tile_rects:
		lookup[_tile_key(_tile_key_vector(rect.position, tile_size))] = true
	return lookup


func _segment_intersects_opaque_fog(start: Vector2, end: Vector2) -> bool:
	var segment_rect := Rect2(
		Vector2(min(start.x, end.x), min(start.y, end.y)),
		Vector2(abs(end.x - start.x), abs(end.y - start.y))
	).grow(max(_outline_width, 1.0))
	for fog_rect in _opaque_fog_rects:
		if fog_rect.intersects(segment_rect, true):
			return true
	return false


func _draw_dim() -> void:
	if _dim_rects.is_empty():
		return
	for rect in _dim_rects:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.36), true)


func _tile_key_vector(world_position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(world_position.x / tile_size)), int(round(world_position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
