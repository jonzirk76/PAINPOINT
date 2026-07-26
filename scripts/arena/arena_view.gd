extends Node2D
class_name ArenaView

const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const ARENA_WALL_TOP_OVERLAY_SCRIPT := preload("res://scripts/arena/arena_wall_top_overlay.gd")
const ARENA_WALL_BODY_VISUAL_SCRIPT := preload("res://scripts/arena/arena_wall_body_visual.gd")
const ARENA_FLOOR_TILE_VISUAL_SCRIPT := preload("res://scripts/arena/arena_floor_tile_visual.gd")
const WALL_BODY_FILL_COLOR := Color(0.16, 0.17, 0.19)
const WALL_BODY_OUTLINE_COLOR := Color(0.5, 0.58, 0.64)
const WALL_TOP_FILL_COLOR := Color(0.09, 0.1, 0.12)
const WALL_TOP_OUTLINE_COLOR := Color(0.72, 0.78, 0.82)
const FLOOR_TILE_SIZE := 40.0

@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var grid_size: float = 60.0
@export var arena_shape: int = 0
@export var wall_rects: Array[Rect2] = []
@export var void_rects: Array[Rect2] = []
@export var depth_sort_layer_path: NodePath = ^"../DepthSortLayer"

@export_group("Procedural Floor Wear")
## [Description] Controls how often small chips appear along the edges of the inset floor panels.
@export_range(0.0, 1.0, 0.01) var floor_chip_density: float = 0.34
## [Description] Controls how often a two-to-four-tile crack run begins on the canonical floor grid.
@export_range(0.0, 0.2, 0.002) var floor_crack_density: float = 0.026
## [Description] Base fill beneath the four inset panels that make up each canonical floor tile.
@export var floor_base_color := Color("#34373a")
## [Description] Main top-facing color of each inset concrete floor panel.
@export var floor_panel_color := Color("#5b5958")
## [Description] Dark worn-concrete color used for edge chips.
@export var floor_chip_color := Color("#37393b")
## [Description] Thin recessed color used by procedural cracks.
@export var floor_crack_color := Color("#252a2d")

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
var _blocker_rebuild_deferred: bool = false
var _floor_wear_seed: int = 0
var _floor_tile_visual = null


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
	_floor_wear_seed = int(level_definition.get_meta(
		"floor_visual_seed",
		String(level_definition.id).hash() ^ (int(level_definition.floor_number) * 7919)
	))
	_fog_rects = _get_meta_rects(level_definition, "fog_rects", [])
	_inactive_room_dim_rects = _get_meta_rects(level_definition, "inactive_room_dim_rects", [])
	_configure_floor_tile_visual()
	_configure_wall_top_overlay()
	_configure_wall_body_depth_visuals()
	_rebuild_blocker_bodies()
	queue_redraw()


func _exit_tree() -> void:
	_clear_floor_tile_visual()
	_clear_wall_body_depth_visuals()


func _draw() -> void:
	var polygon := _get_arena_polygon()
	if _uses_canonical_wall_tiles:
		_draw_canonical_grid()
		_draw_canonical_floor_wear()
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


func _draw_canonical_grid() -> void:
	var grid_color := Color(0.085, 0.092, 0.102, 0.58)
	for cell in _footprint_cells:
		var rect := _cell_rect(cell)
		var x := rect.position.x
		while x <= rect.position.x + rect.size.x + 0.5:
			draw_line(Vector2(x, rect.position.y), Vector2(x, rect.position.y + rect.size.y), grid_color, 1.0)
			x += FLOOR_TILE_SIZE
		var y := rect.position.y
		while y <= rect.position.y + rect.size.y + 0.5:
			draw_line(Vector2(rect.position.x, y), Vector2(rect.position.x + rect.size.x, y), grid_color, 1.0)
			y += FLOOR_TILE_SIZE


func _draw_canonical_floor_wear() -> void:
	var tile_lookup := _build_floor_tile_lookup()
	var sorted_keys: Array = tile_lookup.keys()
	sorted_keys.sort()
	for key_value in sorted_keys:
		var tile_coord: Vector2i = tile_lookup[key_value]
		if _wear_value(tile_coord, 701) < floor_crack_density:
			_draw_crack_run(tile_coord, tile_lookup)


func _build_floor_tile_lookup() -> Dictionary:
	var lookup := {}
	var tiles_per_cell := Vector2i(
		roundi(ROOM_GEOMETRY_BUILDER.CELL_SIZE.x / FLOOR_TILE_SIZE),
		roundi(ROOM_GEOMETRY_BUILDER.CELL_SIZE.y / FLOOR_TILE_SIZE)
	)
	for cell in _footprint_cells:
		var first_tile := Vector2i(cell.x * tiles_per_cell.x, cell.y * tiles_per_cell.y)
		for tile_y in range(tiles_per_cell.y):
			for tile_x in range(tiles_per_cell.x):
				var tile_coord := first_tile + Vector2i(tile_x, tile_y)
				lookup[_floor_tile_key(tile_coord)] = tile_coord
	return lookup


func _configure_floor_tile_visual() -> void:
	if not _uses_canonical_wall_tiles:
		_clear_floor_tile_visual()
		return
	if _floor_tile_visual == null or not is_instance_valid(_floor_tile_visual):
		_floor_tile_visual = ARENA_FLOOR_TILE_VISUAL_SCRIPT.new()
		_floor_tile_visual.name = "FloorTileVisual"
		_floor_tile_visual.z_index = -10
		add_child(_floor_tile_visual)
	var tile_lookup := _build_floor_tile_lookup()
	var tile_coordinates: Array[Vector2i] = []
	for tile_coord_value in tile_lookup.values():
		tile_coordinates.append(tile_coord_value)
	_floor_tile_visual.configure(
		tile_coordinates,
		arena_bounds.position,
		arena_bounds.grow(960.0),
		_floor_wear_seed,
		floor_chip_density,
		floor_base_color,
		floor_panel_color,
		floor_chip_color
	)


func _clear_floor_tile_visual() -> void:
	if _floor_tile_visual != null and is_instance_valid(_floor_tile_visual):
		_floor_tile_visual.queue_free()
	_floor_tile_visual = null


func _draw_crack_run(start_coord: Vector2i, tile_lookup: Dictionary) -> void:
	var horizontal := _wear_value(start_coord, 709) < 0.5
	var direction := Vector2i.RIGHT if horizontal else Vector2i.DOWN
	var run_length := 2 if _wear_value(start_coord, 719) < 0.28 else 1
	var valid_length := 1
	for step in range(1, run_length):
		if not tile_lookup.has(_floor_tile_key(start_coord + direction * step)):
			break
		valid_length += 1
	var cross_offset := 7.0 + _wear_value(start_coord, 727) * 26.0
	var points := PackedVector2Array()
	for point_index in range(valid_length * 2 + 1):
		var progress := float(point_index) / float(valid_length * 2)
		var along := progress * float(valid_length) * FLOOR_TILE_SIZE
		var bend := (_wear_value(start_coord, 733 + point_index * 11) - 0.5) * 6.0
		var local_point := Vector2(along, cross_offset + bend) if horizontal else Vector2(cross_offset + bend, along)
		points.append(arena_bounds.position + Vector2(start_coord) * FLOOR_TILE_SIZE + local_point)
	draw_polyline(points, floor_crack_color, 1.35, true)
	if points.size() >= 4 and _wear_value(start_coord, 811) < 0.7:
		var branch_index := 1 + int(floor(_wear_value(start_coord, 821) * float(points.size() - 2)))
		var branch_start := points[branch_index]
		var branch_direction := Vector2(0.65, -1.0) if horizontal else Vector2(-1.0, 0.65)
		if _wear_value(start_coord, 823) < 0.5:
			branch_direction *= -1.0
		draw_polyline(
			PackedVector2Array([
				branch_start,
				branch_start + branch_direction * 5.0,
				branch_start + branch_direction * 9.0 + Vector2(2.0, -1.0)
			]),
			floor_crack_color,
			1.1,
			true
		)


func _floor_tile_key(tile_coord: Vector2i) -> String:
	return "%d:%d" % [tile_coord.x, tile_coord.y]


func _wear_value(tile_coord: Vector2i, salt: int) -> float:
	var value := sin(
		float(tile_coord.x) * 12.9898
		+ float(tile_coord.y) * 78.233
		+ float(_floor_wear_seed) * 0.00013
		+ float(salt) * 0.9187
	) * 43758.5453
	return value - floor(value)


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
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _blocker_rebuild_deferred:
			_blocker_rebuild_deferred = true
			call_deferred("_rebuild_blocker_bodies")
		return
	_blocker_rebuild_deferred = false
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


func _tile_key_vector(world_position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(world_position.x / tile_size)), int(round(world_position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]
