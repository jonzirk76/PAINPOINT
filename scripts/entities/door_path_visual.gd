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
	connection_chance: float,
	visual_seed: int,
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
	_path_points = _build_path_pairs(_mat_rects, connection_chance, visual_seed)
	_mat_color = mat_color
	_path_color = path_color
	_border_color = border_color
	_path_width = max(path_width, 4.0)
	_border_width = max(border_width, 1.0)
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


func _build_path_pairs(mat_rects: Array[Rect2], connection_chance: float, visual_seed: int) -> Array[PackedVector2Array]:
	var paths: Array[PackedVector2Array] = []
	if mat_rects.size() < 2:
		return paths
	var rng := RandomNumberGenerator.new()
	rng.seed = visual_seed
	var available_indices: Array[int] = []
	for index in range(mat_rects.size()):
		available_indices.append(index)
	for index in range(available_indices.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := available_indices[index]
		available_indices[index] = available_indices[swap_index]
		available_indices[swap_index] = held
	for pair_index in range(0, available_indices.size() - 1, 2):
		if rng.randf() > clamp(connection_chance, 0.0, 1.0):
			continue
		var start := mat_rects[available_indices[pair_index]].get_center()
		var end := mat_rects[available_indices[pair_index + 1]].get_center()
		var bend := Vector2(end.x, start.y) if rng.randi() % 2 == 0 else Vector2(start.x, end.y)
		var points := PackedVector2Array([start])
		if start.distance_squared_to(bend) > 1.0 and bend.distance_squared_to(end) > 1.0:
			points.append(bend)
		points.append(end)
		paths.append(points)
	return paths


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
