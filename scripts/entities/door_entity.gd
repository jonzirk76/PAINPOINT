extends Area2D
class_name DoorEntity

signal entered(door)

@export var door_size: Vector2 = Vector2(88.0, 28.0)

const DOOR_GATE_TOP_VISUAL_SCRIPT := preload("res://scripts/entities/door_gate_top_visual.gd")
const ROOM_GEOMETRY_BUILDER := preload("res://scripts/resources/room_geometry_builder.gd")
const ARM_DELAY_SECONDS := 0.12
const WALL_TOP_Z_INDEX := 5
const WALL_TOP_FILL_COLOR := Color(0.09, 0.1, 0.12, 1.0)
const WALL_TOP_OUTLINE_COLOR := Color(0.72, 0.78, 0.82, 1.0)
const GATE_BODY_COLOR := Color(0.16, 0.17, 0.19, 1.0)
const GATE_SPECIAL_BODY_COLOR := Color(0.18, 0.165, 0.195, 1.0)

var direction: String = "north"
var target_room_id: String = ""
var target_room_kind: String = ""
var unlocked: bool = false
var visual_size: Vector2 = Vector2.ZERO
var visual_offset: Vector2 = Vector2.ZERO
var passage_size: Vector2 = Vector2.ZERO
var passage_offset: Vector2 = Vector2.ZERO
var _collision_shape: CollisionShape2D = null
var _gate_body: StaticBody2D = null
var _gate_collision_shape: CollisionShape2D = null
var _gate_top_visual = null
var _armed: bool = false
var _arm_delay_remaining: float = 0.0
var _monitoring_enabled: bool = true
var _gate_blocking_enabled: bool = false
var _trigger_collision_update_deferred: bool = false
var _gate_collision_update_deferred: bool = false


func _init() -> void:
	_configure_collision_identity()
	_add_or_update_collision()
	_add_or_update_gate_collision()


func _ready() -> void:
	_configure_collision_identity()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func initialize(door_direction: String, target_id: String, center_position: Vector2, size: Vector2, is_unlocked: bool, target_kind: String = "") -> void:
	direction = door_direction
	target_room_id = target_id
	target_room_kind = target_kind
	global_position = center_position
	door_size = size
	unlocked = is_unlocked
	_armed = false
	_arm_delay_remaining = ARM_DELAY_SECONDS if unlocked else 0.0
	_add_or_update_collision()
	_add_or_update_gate_collision()
	_sync_gate_top_visual()
	set_physics_process(_monitoring_enabled and unlocked)
	queue_redraw()


func set_visual_rect(center_position: Vector2, size: Vector2) -> void:
	var snapped_center := Vector2(round(center_position.x), round(center_position.y))
	visual_offset = snapped_center - global_position
	visual_size = Vector2(round(size.x), round(size.y))
	_add_or_update_gate_collision()
	_sync_gate_top_visual()
	queue_redraw()


func set_passage_rect(center_position: Vector2, size: Vector2) -> void:
	var snapped_center := Vector2(round(center_position.x), round(center_position.y))
	passage_offset = snapped_center - global_position
	passage_size = Vector2(round(size.x), round(size.y))
	queue_redraw()


func set_unlocked(value: bool) -> void:
	unlocked = value
	_armed = false
	_arm_delay_remaining = ARM_DELAY_SECONDS if unlocked else 0.0
	_set_gate_blocking_enabled(not unlocked)
	_sync_gate_top_visual()
	set_physics_process(_monitoring_enabled and unlocked and not _armed)
	queue_redraw()


func is_gate_blocking() -> bool:
	return _gate_blocking_enabled


func set_monitoring_enabled(value: bool) -> void:
	_monitoring_enabled = value
	_set_area_property("monitoring", value)
	if not value:
		_armed = false
		set_physics_process(false)
	elif unlocked:
		set_physics_process(not _armed)


func get_gate_blocker_rect() -> Rect2:
	var size := visual_size if visual_size != Vector2.ZERO else door_size
	return Rect2(global_position + visual_offset - size * 0.5, size)


func _configure_collision_identity() -> void:
	_set_area_property("collision_layer", 0)
	_set_area_property("collision_mask", 1)
	_set_area_property("monitoring", _monitoring_enabled)
	_set_area_property("monitorable", false)
	add_to_group("dungeon_doors")


func _on_body_entered(body: Node) -> void:
	if not _monitoring_enabled or not unlocked or not _armed or not body.is_in_group("player"):
		return
	_armed = false
	entered.emit(self)


func _on_body_exited(body: Node) -> void:
	if _monitoring_enabled and unlocked and _arm_delay_remaining <= 0.0 and body.is_in_group("player"):
		_refresh_armed_state()


func _physics_process(delta: float) -> void:
	if not _monitoring_enabled or not unlocked:
		set_physics_process(false)
		return
	if not _armed:
		if _arm_delay_remaining > 0.0:
			_arm_delay_remaining = max(_arm_delay_remaining - delta, 0.0)
			set_physics_process(true)
			return
		_refresh_armed_state()


func _refresh_armed_state() -> void:
	if not _monitoring_enabled or not unlocked:
		_armed = false
		set_physics_process(false)
		return
	_armed = not _has_player_overlap()
	set_physics_process(not _armed)


func _has_player_overlap() -> bool:
	if not monitoring:
		return false
	for body in get_overlapping_bodies():
		if body != null and is_instance_valid(body) and body.is_in_group("player"):
			return true
	return false


func _draw() -> void:
	var fill_rect := _get_visual_fill_rect()
	var drawn_rect := _get_visual_draw_rect()
	var trim_color := Color(0.16, 0.17, 0.18, 1.0)
	if not unlocked:
		_draw_locked_gate_body(fill_rect, trim_color)
		var locked_marker_rect := _get_passage_draw_rect(drawn_rect)
		_draw_room_kind_marker(_get_floor_marker_center(locked_marker_rect), min(locked_marker_rect.size.x, locked_marker_rect.size.y))
	elif has_special_marker():
		var passage_rect := _get_passage_draw_rect(drawn_rect)
		_draw_room_kind_marker(_get_floor_marker_center(passage_rect), min(passage_rect.size.x, passage_rect.size.y))


func _draw_locked_gate_body(fill_rect: Rect2, trim_color: Color) -> void:
	var body_color := GATE_SPECIAL_BODY_COLOR if has_special_marker() else GATE_BODY_COLOR
	var body_rects := _get_gate_body_rects(fill_rect)
	for body_rect in body_rects:
		draw_rect(body_rect, body_color, true)
	_draw_gate_rect_edges(body_rects, trim_color, 2.0)


func _sync_gate_top_visual() -> void:
	var visual = _ensure_gate_top_visual()
	if unlocked:
		visual.clear()
		return
	var rect: Rect2 = _get_visual_fill_rect()
	visual.configure(_get_gate_top_rects(rect), WALL_TOP_FILL_COLOR, WALL_TOP_OUTLINE_COLOR, 2.0)


func _ensure_gate_top_visual():
	if _gate_top_visual != null and is_instance_valid(_gate_top_visual):
		return _gate_top_visual
	_gate_top_visual = DOOR_GATE_TOP_VISUAL_SCRIPT.new()
	_gate_top_visual.name = "GateTopVisual"
	_gate_top_visual.z_index = WALL_TOP_Z_INDEX
	_gate_top_visual.z_as_relative = false
	add_child(_gate_top_visual)
	return _gate_top_visual


func _get_visual_draw_rect() -> Rect2:
	var rect := _get_visual_fill_rect()
	return rect.grow(-1.0) if rect.size.x > 2.0 and rect.size.y > 2.0 else rect


func _get_visual_fill_rect() -> Rect2:
	var size := visual_size if visual_size != Vector2.ZERO else door_size
	return Rect2(visual_offset - size * 0.5, size)


func _get_gate_top_rects(rect: Rect2) -> Array[Rect2]:
	match direction:
		"north":
			var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
			return _rect_to_gate_tiles(Rect2(rect.position, Vector2(rect.size.x, min(rect.size.y, tile_size))))
		"south":
			return _rect_to_gate_tiles(rect)
		"east", "west":
			var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
			var top_height: float = max(rect.size.y - tile_size, 0.0)
			return _rect_to_gate_tiles(Rect2(rect.position, Vector2(rect.size.x, top_height)))
	return []


func _get_gate_body_rects(rect: Rect2) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	match direction:
		"south":
			return rects
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for top_rect in _get_gate_top_rects(rect):
		rects.append(Rect2(top_rect.position + Vector2(0.0, tile_size), top_rect.size))
	return rects


func _rect_to_gate_tiles(rect: Rect2) -> Array[Rect2]:
	var tiles: Array[Rect2] = []
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return tiles
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	var columns: int = max(1, int(ceil(rect.size.x / tile_size)))
	var rows: int = max(1, int(ceil(rect.size.y / tile_size)))
	for y in range(rows):
		for x in range(columns):
			var tile_position := rect.position + Vector2(float(x) * tile_size, float(y) * tile_size)
			var tile_size_clipped := Vector2(
				min(tile_size, rect.position.x + rect.size.x - tile_position.x),
				min(tile_size, rect.position.y + rect.size.y - tile_position.y)
			)
			if tile_size_clipped.x > 0.0 and tile_size_clipped.y > 0.0:
				tiles.append(Rect2(tile_position, tile_size_clipped))
	return tiles


func _draw_gate_rect_edges(rects: Array[Rect2], color: Color, width: float) -> void:
	var lookup := _build_gate_rect_lookup(rects)
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in rects:
		var cell := _tile_key_vector(rect.position, tile_size)
		var left := rect.position.x
		var top := rect.position.y
		var right := rect.position.x + rect.size.x
		var bottom := rect.position.y + rect.size.y
		if not lookup.has(_tile_key(cell + Vector2i(0, -1))):
			draw_line(Vector2(left, top), Vector2(right, top), color, width)
		if not lookup.has(_tile_key(cell + Vector2i(0, 1))):
			draw_line(Vector2(left, bottom), Vector2(right, bottom), color, width)
		if not lookup.has(_tile_key(cell + Vector2i(-1, 0))):
			draw_line(Vector2(left, top), Vector2(left, bottom), color, width)
		if not lookup.has(_tile_key(cell + Vector2i(1, 0))):
			draw_line(Vector2(right, top), Vector2(right, bottom), color, width)


func _build_gate_rect_lookup(rects: Array[Rect2]) -> Dictionary:
	var lookup := {}
	var tile_size: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	for rect in rects:
		lookup[_tile_key(_tile_key_vector(rect.position, tile_size))] = true
	return lookup


func _tile_key_vector(world_position: Vector2, tile_size: float) -> Vector2i:
	return Vector2i(int(round(world_position.x / tile_size)), int(round(world_position.y / tile_size)))


func _tile_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _get_passage_draw_rect(fallback_rect: Rect2) -> Rect2:
	if passage_size == Vector2.ZERO:
		return fallback_rect
	return Rect2(passage_offset - passage_size * 0.5, passage_size)


func _get_floor_marker_center(rect: Rect2) -> Vector2:
	return rect.get_center() + _get_floor_marker_offset()


func _get_floor_marker_offset() -> Vector2:
	var offset: float = ROOM_GEOMETRY_BUILDER.WALL_TILE_SIZE
	match direction:
		"north":
			return Vector2(0.0, offset)
		"south":
			return Vector2(0.0, -offset)
		"east":
			return Vector2(-offset, 0.0)
		"west":
			return Vector2(offset, 0.0)
	return Vector2.ZERO


func has_special_marker() -> bool:
	return target_room_kind == "treasure" or target_room_kind == "challenge" or target_room_kind == "boss"


func _draw_room_kind_marker(center: Vector2, marker_extent: float) -> void:
	if not has_special_marker():
		return
	var marker_size: float = clamp(marker_extent * 0.78, 16.0, 30.0)
	var badge_color := Color(0.015, 0.018, 0.02, 0.86) if unlocked else Color(0.05, 0.07, 0.09, 0.92)
	var accent_color := _get_marker_accent_color()
	draw_circle(center, marker_size * 0.54, badge_color)
	draw_arc(center, marker_size * 0.54, 0.0, TAU, 24, accent_color, 2.0)
	draw_set_transform(center)
	match target_room_kind:
		"treasure":
			_draw_treasure_marker(marker_size, accent_color)
		"challenge":
			_draw_challenge_marker(marker_size, accent_color)
		"boss":
			_draw_boss_marker(marker_size, accent_color)
	draw_set_transform(Vector2.ZERO)


func _get_marker_accent_color() -> Color:
	match target_room_kind:
		"treasure":
			return Color(1.0, 0.82, 0.18, 1.0)
		"challenge":
			return Color(1.0, 0.28, 0.18, 1.0)
		"boss":
			return Color(0.78, 0.34, 1.0, 1.0)
	return Color(0.84, 0.94, 1.0, 1.0)


func _draw_treasure_marker(marker_size: float, accent_color: Color) -> void:
	var half := marker_size * 0.28
	var diamond := PackedVector2Array([
		Vector2(0.0, -half),
		Vector2(half, 0.0),
		Vector2(0.0, half),
		Vector2(-half, 0.0)
	])
	draw_colored_polygon(diamond, accent_color)
	draw_polyline(diamond, Color(1.0, 1.0, 0.75, 1.0), 2.0, true)


func _draw_challenge_marker(marker_size: float, accent_color: Color) -> void:
	var arm := marker_size * 0.36
	var bright := Color(1.0, 0.78, 0.36, 1.0)
	draw_line(Vector2(-arm, -arm), Vector2(arm, arm), accent_color, 3.0)
	draw_line(Vector2(arm, -arm), Vector2(-arm, arm), bright, 3.0)
	draw_circle(Vector2.ZERO, marker_size * 0.12, Color(0.12, 0.02, 0.02, 1.0))


func _draw_boss_marker(marker_size: float, accent_color: Color) -> void:
	var crown_width := marker_size * 0.62
	var crown_height := marker_size * 0.42
	var base_y := crown_height * 0.35
	var crown := PackedVector2Array([
		Vector2(-crown_width * 0.5, base_y),
		Vector2(-crown_width * 0.42, -crown_height * 0.15),
		Vector2(-crown_width * 0.2, crown_height * 0.02),
		Vector2(0.0, -crown_height * 0.5),
		Vector2(crown_width * 0.2, crown_height * 0.02),
		Vector2(crown_width * 0.42, -crown_height * 0.15),
		Vector2(crown_width * 0.5, base_y)
	])
	draw_colored_polygon(crown, accent_color)
	draw_line(Vector2(-crown_width * 0.5, base_y), Vector2(crown_width * 0.5, base_y), Color(1.0, 0.78, 1.0, 1.0), 2.0)


func _add_or_update_collision() -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _trigger_collision_update_deferred:
			_trigger_collision_update_deferred = true
			call_deferred("_add_or_update_collision")
		return
	_trigger_collision_update_deferred = false
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)
	var shape := RectangleShape2D.new()
	shape.size = door_size
	_collision_shape.shape = shape


func _add_or_update_gate_collision() -> void:
	_gate_blocking_enabled = not unlocked
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _gate_collision_update_deferred:
			_gate_collision_update_deferred = true
			call_deferred("_add_or_update_gate_collision")
		return
	_gate_collision_update_deferred = false
	if _gate_body == null:
		_gate_body = StaticBody2D.new()
		_gate_body.name = "GateBlocker"
		_gate_body.add_to_group("arena_walls")
		add_child(_gate_body)
	if _gate_collision_shape == null:
		_gate_collision_shape = CollisionShape2D.new()
		_gate_collision_shape.name = "CollisionShape2D"
		_gate_body.add_child(_gate_collision_shape)
	var size := visual_size if visual_size != Vector2.ZERO else door_size
	var shape := RectangleShape2D.new()
	shape.size = size
	_gate_body.position = visual_offset
	_gate_collision_shape.shape = shape
	_set_gate_blocking_enabled(not unlocked)


func _set_gate_blocking_enabled(value: bool) -> void:
	_gate_blocking_enabled = value
	if _gate_body == null or _gate_collision_shape == null:
		return
	_set_gate_body_property("collision_layer", 32 if value else 0)
	_set_gate_body_property("collision_mask", 0)
	_set_gate_collision_shape_disabled(not value)


func _set_gate_body_property(property_name: StringName, value: Variant) -> void:
	if _gate_body == null:
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		_gate_body.set_deferred(property_name, value)
		return
	_gate_body.set(property_name, value)


func _set_gate_collision_shape_disabled(value: bool) -> void:
	if _gate_collision_shape == null:
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		_gate_collision_shape.set_deferred("disabled", value)
		return
	_gate_collision_shape.disabled = value


func _set_area_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)
