extends Node2D
class_name DoorPathVisual

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const WALL_OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")

var _mat_rects: Array[Rect2] = []
var _path_points: Array[PackedVector2Array] = []
var _visual_bounds: Rect2 = Rect2()
var _mat_color: Color = Color(0.12, 0.13, 0.14, 0.72)
var _path_color: Color = Color(0.19, 0.2, 0.21, 0.78)
var _border_color: Color = Color(0.08, 0.09, 0.1, 0.9)
var _path_width: float = 24.0
var _border_width: float = 5.0


func configure(
	opening_infos: Array,
	depth_tiles: int,
	mat_color: Color,
	path_color: Color,
	border_color: Color,
	path_width: float,
	border_width: float,
	room_center: Vector2,
	obstruction_rects: Array[Rect2],
	room_id: String
) -> void:
	var world_mat_rects: Array[Rect2] = []
	for info in opening_infos:
		if info is Dictionary and info.has("opening_rect"):
			world_mat_rects.append(_get_world_mat_rect(
				info["opening_rect"],
				String(info.get("direction", "north")),
				depth_tiles
			))
	if world_mat_rects.is_empty():
		visible = false
		return
	var world_bounds := world_mat_rects[0]
	for index in range(1, world_mat_rects.size()):
		world_bounds = world_bounds.merge(world_mat_rects[index])
	position = world_bounds.get_center()
	_visual_bounds = Rect2(world_bounds.position - position, world_bounds.size)
	_mat_rects.clear()
	for mat_rect in world_mat_rects:
		_mat_rects.append(Rect2(mat_rect.position - position, mat_rect.size))
	var local_obstruction_rects: Array[Rect2] = []
	for obstruction_rect in obstruction_rects:
		local_obstruction_rects.append(Rect2(
			obstruction_rect.position - position,
			obstruction_rect.size
		))
	_mat_color = mat_color
	_path_color = path_color
	_border_color = border_color
	_path_width = max(path_width, 4.0)
	_border_width = max(border_width, 1.0)
	_path_points = _build_center_paths(
		_mat_rects,
		room_center - position,
		local_obstruction_rects,
		_path_width + _border_width * 2.0
	)
	WALL_OCCLUSION_LAYERS.mark_entity_tree(self, room_id)
	visible = true
	queue_redraw()


func get_perspective_world_rect() -> Rect2:
	return Rect2(global_position + _visual_bounds.position, _visual_bounds.size).grow(_path_width + _border_width)


func _draw() -> void:
	for points in _path_points:
		_draw_rounded_path(points, _path_width + _border_width * 2.0, _border_color)
		_draw_rounded_path(points, _path_width, _path_color)
	for mat_rect in _mat_rects:
		draw_rect(mat_rect, _border_color, true)
		draw_rect(mat_rect.grow(-_border_width), _mat_color, true)
		draw_rect(mat_rect.grow(-_border_width), Color(0.32, 0.33, 0.34, 0.38), false, 1.0)


func _draw_rounded_path(points: PackedVector2Array, width: float, color: Color) -> void:
	if points.size() < 2:
		return
	draw_polyline(points, color, width, true)
	var radius := width * 0.5
	for point in points:
		draw_circle(point, radius, color)


func _build_center_paths(
	mat_rects: Array[Rect2],
	room_center: Vector2,
	obstruction_rects: Array[Rect2],
	total_width: float
) -> Array[PackedVector2Array]:
	var clear_spokes: Array[PackedVector2Array] = []
	if mat_rects.size() < 2:
		return clear_spokes
	for mat_rect in mat_rects:
		var start: Vector2 = mat_rect.get_center()
		if _corridor_is_obstructed(start, room_center, total_width, obstruction_rects):
			continue
		clear_spokes.append(PackedVector2Array([start, room_center]))
	if clear_spokes.size() < 2:
		clear_spokes.clear()
	return clear_spokes


func _corridor_is_obstructed(
	start: Vector2,
	end: Vector2,
	total_width: float,
	obstruction_rects: Array[Rect2]
) -> bool:
	var corridor := Rect2(
		Vector2(min(start.x, end.x), min(start.y, end.y)),
		Vector2(abs(end.x - start.x), abs(end.y - start.y))
	).grow(total_width * 0.5)
	for obstruction_rect in obstruction_rects:
		var blocker: Rect2 = obstruction_rect.grow(-1.0)
		if blocker.size.x <= 0.0 or blocker.size.y <= 0.0:
			continue
		if corridor.intersects(blocker, false):
			return true
	return false


func _get_world_mat_rect(opening_rect: Rect2, direction: String, depth_tiles: int) -> Rect2:
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var depth: float = tile_size * float(max(depth_tiles, 1))
	match direction:
		"north":
			return Rect2(Vector2(opening_rect.position.x, opening_rect.end.y), Vector2(opening_rect.size.x, depth))
		"south":
			return Rect2(Vector2(opening_rect.position.x, opening_rect.position.y - depth), Vector2(opening_rect.size.x, depth))
		"east":
			return Rect2(Vector2(opening_rect.position.x - depth, opening_rect.position.y), Vector2(depth, opening_rect.size.y))
		"west":
			return Rect2(Vector2(opening_rect.end.x, opening_rect.position.y), Vector2(depth, opening_rect.size.y))
	return opening_rect
