extends Node2D
class_name DoorGateTopVisual

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")

var _rects: Array[Rect2] = []
var _fill_color: Color = Color(0.09, 0.1, 0.12)
var _outline_color: Color = Color(0.72, 0.78, 0.82)
var _outline_width: float = 2.0


func configure(rects: Array[Rect2], fill_color: Color, outline_color: Color, outline_width: float) -> void:
	_rects.clear()
	for rect in rects:
		if rect.size.x > 0.0 and rect.size.y > 0.0:
			_rects.append(rect)
	_fill_color = fill_color
	_outline_color = outline_color
	_outline_width = outline_width
	visible = not _rects.is_empty()
	queue_redraw()


func clear() -> void:
	_rects.clear()
	visible = false
	queue_redraw()


func _draw() -> void:
	var lookup := _build_tile_lookup(_rects)
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in _rects:
		draw_rect(rect, _fill_color, true)
	for rect in _rects:
		var cell := _tile_key_vector(rect.position, tile_size)
		var left := rect.position.x
		var top := rect.position.y
		var right := rect.position.x + rect.size.x
		var bottom := rect.position.y + rect.size.y
		if not lookup.has(_tile_key(cell + Vector2i(0, -1))):
			draw_line(Vector2(left, top), Vector2(right, top), _outline_color, _outline_width)
		if not lookup.has(_tile_key(cell + Vector2i(0, 1))):
			draw_line(Vector2(left, bottom), Vector2(right, bottom), _outline_color, _outline_width)
		if not lookup.has(_tile_key(cell + Vector2i(-1, 0))):
			draw_line(Vector2(left, top), Vector2(left, bottom), _outline_color, _outline_width)
		if not lookup.has(_tile_key(cell + Vector2i(1, 0))):
			draw_line(Vector2(right, top), Vector2(right, bottom), _outline_color, _outline_width)


func _build_tile_lookup(rects: Array[Rect2]) -> Dictionary:
	var lookup := {}
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in rects:
		lookup[_tile_key(_tile_key_vector(rect.position, tile_size))] = true
	return lookup


func _tile_key_vector(position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(position.x / tile_size)), int(round(position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
