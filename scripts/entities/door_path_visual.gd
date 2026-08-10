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
	_draw_path_regions(_path_width + _border_width * 2.0, _border_color)
	_draw_path_regions(_path_width, _path_color)
	for mat_rect in _mat_rects:
		draw_rect(mat_rect, _border_color, true)
		draw_rect(mat_rect.grow(-_border_width), _mat_color, true)
		draw_rect(mat_rect.grow(-_border_width), Color(0.32, 0.33, 0.34, 0.38), false, 1.0)


func _draw_path_regions(width: float, color: Color) -> void:
	for region in _build_path_regions(width):
		draw_colored_polygon(region, color)


func _build_path_regions(width: float) -> Array[PackedVector2Array]:
	var regions: Array[PackedVector2Array] = []
	for points in _path_points:
		if points.size() < 2:
			continue
		var offset_regions: Array[PackedVector2Array] = Geometry2D.offset_polyline(
			points,
			width * 0.5,
			Geometry2D.JOIN_MITER,
			Geometry2D.END_SQUARE
		)
		for offset_region in offset_regions:
			_merge_path_region(regions, offset_region)
	return regions


func _merge_path_region(regions: Array[PackedVector2Array], polygon: PackedVector2Array) -> void:
	if polygon.is_empty():
		return
	var merged_polygon := polygon
	var region_index: int = 0
	while region_index < regions.size():
		var merged: Array[PackedVector2Array] = Geometry2D.merge_polygons(
			regions[region_index],
			merged_polygon
		)
		if merged.size() == 1:
			merged_polygon = merged[0]
			regions.remove_at(region_index)
			region_index = 0
			continue
		region_index += 1
	regions.append(merged_polygon)


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
		if _corridor_is_obstructed(
			start,
			room_center,
			total_width,
			obstruction_rects
		):
			continue
		clear_spokes.append(PackedVector2Array([start, room_center]))
	if clear_spokes.size() < 2:
		clear_spokes.clear()
	elif clear_spokes.size() == 2:
		return [PackedVector2Array([
			clear_spokes[0][0],
			room_center,
			clear_spokes[1][0]
		])]
	return clear_spokes


func _corridor_is_obstructed(
	start: Vector2,
	end: Vector2,
	total_width: float,
	obstruction_rects: Array[Rect2]
) -> bool:
	var corridor_delta: Vector2 = end - start
	var validation_start: Vector2 = start
	if corridor_delta.length_squared() > 0.001:
		var doorway_clearance: float = min(
			total_width * 0.5 + 1.0,
			corridor_delta.length()
		)
		validation_start += corridor_delta.normalized() * doorway_clearance
	for obstruction_rect in obstruction_rects:
		var blocker: Rect2 = obstruction_rect.grow(-1.0)
		if blocker.size.x <= 0.0 or blocker.size.y <= 0.0:
			continue
		if _swept_segment_intersects_rect(
			validation_start,
			end,
			total_width * 0.5,
			blocker
		):
			return true
	return false


func _swept_segment_intersects_rect(
	start: Vector2,
	end: Vector2,
	radius: float,
	rect: Rect2
) -> bool:
	var expanded: Rect2 = rect.grow(max(radius, 0.0))
	if expanded.has_point(start) or expanded.has_point(end):
		return true
	var top_left: Vector2 = expanded.position
	var top_right := Vector2(expanded.end.x, expanded.position.y)
	var bottom_right: Vector2 = expanded.end
	var bottom_left := Vector2(expanded.position.x, expanded.end.y)
	return (
		Geometry2D.segment_intersects_segment(start, end, top_left, top_right) != null
		or Geometry2D.segment_intersects_segment(start, end, top_right, bottom_right) != null
		or Geometry2D.segment_intersects_segment(start, end, bottom_right, bottom_left) != null
		or Geometry2D.segment_intersects_segment(start, end, bottom_left, top_left) != null
	)


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
