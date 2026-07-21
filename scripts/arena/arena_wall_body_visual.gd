extends Node2D
class_name ArenaWallBodyVisual

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

var _local_rect: Rect2 = Rect2()
var _fill_color: Color = Color(0.16, 0.17, 0.19)
var _outline_color: Color = Color(0.5, 0.58, 0.64)
var _outline_width: float = 3.0
var _draw_top_edge: bool = true
var _draw_bottom_edge: bool = true
var _draw_left_edge: bool = true
var _draw_right_edge: bool = true


func configure(tile_rect: Rect2, wall_body_lookup: Dictionary, fill_color: Color, outline_color: Color, outline_width: float) -> void:
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var cell := _tile_key_vector(tile_rect.position, tile_size)
	position = tile_rect.position + Vector2(tile_rect.size.x * 0.5, tile_rect.size.y)
	_local_rect = Rect2(Vector2(-tile_rect.size.x * 0.5, -tile_rect.size.y), tile_rect.size)
	_fill_color = fill_color
	_outline_color = outline_color
	_outline_width = outline_width
	_draw_top_edge = not wall_body_lookup.has(_tile_key(cell + Vector2i(0, -1)))
	_draw_bottom_edge = not wall_body_lookup.has(_tile_key(cell + Vector2i(0, 1)))
	_draw_left_edge = not wall_body_lookup.has(_tile_key(cell + Vector2i(-1, 0)))
	_draw_right_edge = not wall_body_lookup.has(_tile_key(cell + Vector2i(1, 0)))
	visible = tile_rect.size.x > 0.0 and tile_rect.size.y > 0.0
	queue_redraw()


func _draw() -> void:
	draw_rect(_local_rect, _fill_color, true)
	var left := _local_rect.position.x
	var top := _local_rect.position.y
	var right := _local_rect.position.x + _local_rect.size.x
	var bottom := _local_rect.position.y + _local_rect.size.y
	if _draw_top_edge:
		draw_line(Vector2(left, top), Vector2(right, top), _outline_color, _outline_width)
	if _draw_bottom_edge:
		draw_line(Vector2(left, bottom), Vector2(right, bottom), _outline_color, _outline_width)
	if _draw_left_edge:
		draw_line(Vector2(left, top), Vector2(left, bottom), _outline_color, _outline_width)
	if _draw_right_edge:
		draw_line(Vector2(right, top), Vector2(right, bottom), _outline_color, _outline_width)


func _tile_key_vector(position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(position.x / tile_size)), int(round(position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
