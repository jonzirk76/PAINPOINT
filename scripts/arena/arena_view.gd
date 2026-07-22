extends Node2D
class_name ArenaView

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const ARENA_WALL_TOP_OVERLAY_SCRIPT := preload("res://scripts/arena/arena_wall_top_overlay.gd")
const ARENA_WALL_BODY_VISUAL_SCRIPT := preload("res://scripts/arena/arena_wall_body_visual.gd")
const WALL_BODY_FILL_COLOR := Color(0.16, 0.17, 0.19)
const WALL_BODY_OUTLINE_COLOR := Color(0.5, 0.58, 0.64)
const WALL_TOP_FILL_COLOR := Color(0.09, 0.1, 0.12)
const WALL_TOP_OUTLINE_COLOR := Color(0.72, 0.78, 0.82)

@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var grid_size: float = 60.0
@export var arena_shape: int = 0
@export var wall_rects: Array[Rect2] = []
@export var void_rects: Array[Rect2] = []
@export var depth_sort_layer_path: NodePath = ^"../DepthSortLayer"

var _wall_bodies: Array[StaticBody2D] = []
var _void_bodies: Array[StaticBody2D] = []
var _uses_canonical_wall_tiles: bool = false
var _wall_tile_rects: Array[Rect2] = []
var _wall_top_tile_rects: Array[Rect2] = []
var _void_tile_rects: Array[Rect2] = []
var _wall_draw_rects: Array[Rect2] = []
var _wall_draw_tile_rects: Array[Rect2] = []
var _void_draw_rects: Array[Rect2] = []
var _footprint_cells: Array[Vector2i] = []
var _fog_rects: Array[Rect2] = []
var _inactive_room_dim_rects: Array[Rect2] = []
var _wall_top_overlay = null
var _wall_body_visuals: Array[Node2D] = []
var _wall_body_depth_visuals_enabled: bool = false


func configure(level_definition) -> void:
	if level_definition == null:
		return
	arena_bounds = level_definition.arena_bounds
	arena_shape = int(level_definition.arena_shape)
	wall_rects = level_definition.wall_rects
	void_rects = level_definition.void_rects
	_uses_canonical_wall_tiles = level_definition.has_meta("footprint_cells")
	_wall_tile_rects = _get_meta_rects(level_definition, "wall_body_tile_rects", ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(wall_rects))
	_wall_top_tile_rects = _get_wall_top_tile_rects(level_definition)
	_void_tile_rects = _get_meta_rects(level_definition, "void_tile_rects", ROOM_GEOMETRY_BUILDER.rects_to_wall_tiles(void_rects))
	if _uses_canonical_wall_tiles:
		_wall_draw_tile_rects = _get_uncovered_wall_body_tiles(_wall_tile_rects, _wall_top_tile_rects)
		_wall_draw_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(_wall_draw_tile_rects)
		_void_draw_rects = ROOM_GEOMETRY_BUILDER.merge_wall_tiles(_void_tile_rects)
	else:
		_wall_draw_tile_rects = _wall_tile_rects.duplicate()
		_wall_draw_rects = wall_rects.duplicate()
		_void_draw_rects = void_rects.duplicate()
	_footprint_cells = _get_meta_cells(level_definition, "footprint_cells")
	_fog_rects = _get_meta_rects(level_definition, "fog_rects", [])
	_inactive_room_dim_rects = _get_meta_rects(level_definition, "inactive_room_dim_rects", [])
	_configure_wall_top_overlay()
	_configure_wall_body_depth_visuals()
	_rebuild_blocker_bodies()
	queue_redraw()


func _exit_tree() -> void:
	_clear_wall_body_depth_visuals()


func _draw() -> void:
	var polygon := _get_arena_polygon()
	if _uses_canonical_wall_tiles:
		draw_rect(arena_bounds.grow(960.0), Color.BLACK, true)
		_draw_canonical_floor()
		_draw_canonical_grid()
	else:
		draw_colored_polygon(polygon, Color(0.07, 0.08, 0.09))
		_draw_clipped_grid(polygon)
	_draw_voids()
	_draw_walls()
	if not _uses_canonical_wall_tiles:
		_draw_fog()
	if not _uses_canonical_wall_tiles:
		draw_polyline(_closed_points(polygon), Color(0.52, 0.58, 0.62), 4.0, true)


func _draw_clipped_grid(polygon: PackedVector2Array) -> void:
	var left := arena_bounds.position.x
	var right := arena_bounds.position.x + arena_bounds.size.x
	var top := arena_bounds.position.y
	var bottom := arena_bounds.position.y + arena_bounds.size.y
	var grid_color := Color(0.16, 0.18, 0.2)
	var x := left
	while x <= right:
		_draw_clipped_vertical_line(x, polygon, grid_color)
		x += grid_size
	var y := top
	while y <= bottom:
		_draw_clipped_horizontal_line(y, polygon, grid_color)
		y += grid_size


func _get_arena_polygon() -> PackedVector2Array:
	return ArenaGeometry.build_polygon(arena_bounds, arena_shape)


func _draw_clipped_vertical_line(x: float, polygon: PackedVector2Array, color: Color) -> void:
	var intersections: Array[float] = []
	for index in range(polygon.size()):
		var start := polygon[index]
		var end := polygon[(index + 1) % polygon.size()]
		if abs(end.x - start.x) <= 0.001:
			continue
		if x < min(start.x, end.x) or x > max(start.x, end.x):
			continue
		var t: float = clamp((x - start.x) / (end.x - start.x), 0.0, 1.0)
		intersections.append(lerp(start.y, end.y, t))
	_draw_intersection_segments(intersections, true, x, color)


func _draw_clipped_horizontal_line(y: float, polygon: PackedVector2Array, color: Color) -> void:
	var intersections: Array[float] = []
	for index in range(polygon.size()):
		var start := polygon[index]
		var end := polygon[(index + 1) % polygon.size()]
		if abs(end.y - start.y) <= 0.001:
			continue
		if y < min(start.y, end.y) or y > max(start.y, end.y):
			continue
		var t: float = clamp((y - start.y) / (end.y - start.y), 0.0, 1.0)
		intersections.append(lerp(start.x, end.x, t))
	_draw_intersection_segments(intersections, false, y, color)


func _draw_intersection_segments(intersections: Array[float], vertical: bool, fixed_axis: float, color: Color) -> void:
	var values := _dedupe_sorted_values(intersections)
	if values.size() < 2:
		return
	for index in range(values.size() - 1):
		var start_value: float = values[index]
		var end_value: float = values[index + 1]
		var midpoint_value := (start_value + end_value) * 0.5
		var midpoint := Vector2(fixed_axis, midpoint_value) if vertical else Vector2(midpoint_value, fixed_axis)
		if not ArenaGeometry.is_point_in_polygon(midpoint, _get_arena_polygon()):
			continue
		var start_point := Vector2(fixed_axis, start_value) if vertical else Vector2(start_value, fixed_axis)
		var end_point := Vector2(fixed_axis, end_value) if vertical else Vector2(end_value, fixed_axis)
		draw_line(start_point, end_point, color, 1.0)


func _dedupe_sorted_values(values: Array[float]) -> Array[float]:
	values.sort()
	var deduped: Array[float] = []
	for value in values:
		if deduped.is_empty() or abs(value - deduped[deduped.size() - 1]) > 0.5:
			deduped.append(value)
	return deduped


func _draw_canonical_floor() -> void:
	var floor_color := Color(0.045, 0.052, 0.058)
	for cell in _footprint_cells:
		draw_rect(_cell_rect(cell), floor_color, true)


func _draw_canonical_grid() -> void:
	var tile_size := 40.0
	var grid_color := Color(0.085, 0.092, 0.102, 0.58)
	for cell in _footprint_cells:
		var rect := _cell_rect(cell)
		var x := rect.position.x
		while x <= rect.position.x + rect.size.x + 0.5:
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), grid_color, 1.0)
			x += tile_size
		var y := rect.position.y
		while y <= rect.position.y + rect.size.y + 0.5:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), grid_color, 1.0)
			y += tile_size


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(arena_bounds.position + Vector2(float(cell.x) * ROOM_GEOMETRY_BUILDER.CELL_SIZE.x, float(cell.y) * ROOM_GEOMETRY_BUILDER.CELL_SIZE.y), ROOM_GEOMETRY_BUILDER.CELL_SIZE)


func _get_meta_rects(level_definition, meta_key: String, fallback: Array[Rect2]) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition.has_meta(meta_key):
		for rect in level_definition.get_meta(meta_key):
			rects.append(rect)
	else:
		rects.append_array(fallback)
	return rects


func _get_meta_cells(level_definition, meta_key: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if level_definition.has_meta(meta_key):
		for cell in level_definition.get_meta(meta_key):
			cells.append(cell)
	if cells.is_empty():
		cells.append(Vector2i.ZERO)
	return cells


func _get_wall_top_tile_rects(level_definition) -> Array[Rect2]:
	if level_definition.has_meta("wall_top_tile_rects"):
		return _get_meta_rects(level_definition, "wall_top_tile_rects", [])
	if level_definition.has_meta("wall_tile_rects"):
		return _get_meta_rects(level_definition, "wall_tile_rects", [])
	return _wall_tile_rects.duplicate()


func _get_uncovered_wall_body_tiles(body_tiles: Array[Rect2], wall_top_tiles: Array[Rect2]) -> Array[Rect2]:
	var visible_tiles: Array[Rect2] = []
	var wall_top_lookup := _build_tile_lookup(wall_top_tiles)
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for body_tile in body_tiles:
		var body_key := _tile_key(_tile_key_vector(body_tile.position, tile_size))
		if wall_top_lookup.has(body_key):
			continue
		visible_tiles.append(body_tile)
	return visible_tiles


func _configure_wall_top_overlay() -> void:
	var overlay = _ensure_wall_top_overlay()
	if not _uses_canonical_wall_tiles:
		overlay.clear()
		return
	overlay.configure(
		_wall_top_tile_rects,
		ROOM_GEOMETRY_BUILDER.merge_wall_tiles(_wall_top_tile_rects),
		_fog_rects,
		_inactive_room_dim_rects,
		WALL_TOP_FILL_COLOR,
		WALL_TOP_OUTLINE_COLOR,
		2.0
	)


func _ensure_wall_top_overlay():
	if _wall_top_overlay != null and is_instance_valid(_wall_top_overlay):
		return _wall_top_overlay
	_wall_top_overlay = ARENA_WALL_TOP_OVERLAY_SCRIPT.new()
	_wall_top_overlay.name = "WallTopOverlay"
	_wall_top_overlay.z_index = 5
	add_child(_wall_top_overlay)
	return _wall_top_overlay


func _configure_wall_body_depth_visuals() -> void:
	_clear_wall_body_depth_visuals()
	if not _uses_canonical_wall_tiles:
		return
	var depth_sort_layer: Node2D = _get_depth_sort_layer()
	if depth_sort_layer == null:
		return
	var wall_body_lookup := _build_tile_lookup(_wall_draw_tile_rects)
	var wall_body_runs := _build_horizontal_wall_body_runs(_wall_draw_tile_rects)
	for index in range(wall_body_runs.size()):
		var visual: ArenaWallBodyVisual = ARENA_WALL_BODY_VISUAL_SCRIPT.new()
		var run_tiles: Array[Rect2] = []
		for tile in wall_body_runs[index]:
			run_tiles.append(tile)
		visual.name = "ArenaWallBodyVisual%d" % index
		depth_sort_layer.add_child(visual)
		visual.configure(run_tiles, wall_body_lookup, WALL_BODY_FILL_COLOR, WALL_BODY_OUTLINE_COLOR, 3.0)
		_wall_body_visuals.append(visual)
	_wall_body_depth_visuals_enabled = true


func _build_horizontal_wall_body_runs(tile_rects: Array[Rect2]) -> Array:
	var rows := {}
	for tile in tile_rects:
		var key := "%d:%d" % [int(round(tile.position.y)), int(round(tile.size.y))]
		var row: Array = rows.get(key, [])
		row.append(tile)
		rows[key] = row
	var runs: Array = []
	for key in rows.keys():
		var row: Array = rows[key]
		row.sort_custom(func(a: Rect2, b: Rect2) -> bool:
			return a.position.x < b.position.x
		)
		var current_run: Array[Rect2] = []
		for tile in row:
			if current_run.is_empty():
				current_run.append(tile)
				continue
			var previous: Rect2 = current_run[current_run.size() - 1]
			var touches: bool = abs((previous.position.x + previous.size.x) - tile.position.x) <= 0.5
			if touches:
				current_run.append(tile)
			else:
				runs.append(current_run)
				current_run = []
				current_run.append(tile)
		if not current_run.is_empty():
			runs.append(current_run)
	return runs


func _clear_wall_body_depth_visuals() -> void:
	for visual in _wall_body_visuals:
		if is_instance_valid(visual):
			visual.visible = false
			visual.queue_free()
	_wall_body_visuals.clear()
	_wall_body_depth_visuals_enabled = false


func _get_depth_sort_layer() -> Node2D:
	if String(depth_sort_layer_path).is_empty():
		return null
	return get_node_or_null(depth_sort_layer_path) as Node2D


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _rebuild_blocker_bodies() -> void:
	for wall_body in _wall_bodies:
		if is_instance_valid(wall_body):
			wall_body.collision_layer = 0
			wall_body.collision_mask = 0
			wall_body.queue_free()
	_wall_bodies.clear()
	for void_body in _void_bodies:
		if is_instance_valid(void_body):
			void_body.collision_layer = 0
			void_body.collision_mask = 0
			void_body.queue_free()
	_void_bodies.clear()
	for index in range(wall_rects.size()):
		var rect := wall_rects[index]
		var body := StaticBody2D.new()
		body.name = "ArenaWall%d" % index
		body.collision_layer = 32
		body.collision_mask = 0
		body.add_to_group("arena_walls")
		body.position = rect.get_center()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision_shape := CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		collision_shape.shape = shape
		body.add_child(collision_shape)
		add_child(body)
		_wall_bodies.append(body)
	for index in range(void_rects.size()):
		var rect := void_rects[index]
		var body := StaticBody2D.new()
		body.name = "ArenaVoid%d" % index
		body.collision_layer = 64
		body.collision_mask = 0
		body.add_to_group("arena_voids")
		body.position = rect.get_center()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collision_shape := CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		collision_shape.shape = shape
		body.add_child(collision_shape)
		add_child(body)
		_void_bodies.append(body)


func _draw_walls() -> void:
	if _uses_canonical_wall_tiles:
		if not _wall_body_depth_visuals_enabled:
			_draw_tile_mass(_wall_draw_tile_rects, _wall_draw_rects, WALL_BODY_FILL_COLOR, WALL_BODY_OUTLINE_COLOR, 3.0)
	else:
		for rect in _wall_draw_rects:
			draw_rect(rect, Color(0.11, 0.12, 0.14), true)
			draw_rect(rect, Color(0.65, 0.72, 0.76), false, 3.0)


func _draw_voids() -> void:
	if _uses_canonical_wall_tiles:
		_draw_tile_mass(_void_tile_rects, _void_draw_rects, Color(0.02, 0.03, 0.045), Color(0.17, 0.24, 0.34), 2.0)
	else:
		for rect in _void_draw_rects:
			draw_rect(rect, Color(0.02, 0.03, 0.045), true)
			draw_rect(rect, Color(0.17, 0.24, 0.34), false, 2.0)


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


func _draw_fog() -> void:
	if _fog_rects.is_empty():
		return
	for rect in _fog_rects:
		draw_rect(rect.grow(4.0), Color.BLACK, true)
		draw_rect(rect.grow(-2.0), Color(0.03, 0.09, 0.1, 0.34), false, 2.0)


func _build_tile_lookup(tile_rects: Array[Rect2]) -> Dictionary:
	var lookup := {}
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in tile_rects:
		lookup[_tile_key(_tile_key_vector(rect.position, tile_size))] = true
	return lookup


func _tile_key_vector(position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(position.x / tile_size)), int(round(position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
