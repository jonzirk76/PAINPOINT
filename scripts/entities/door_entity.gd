extends Area2D
class_name DoorEntity

signal entered(door)

@export var door_size: Vector2 = Vector2(88.0, 28.0)

const ARM_DELAY_SECONDS := 0.12
const GATE_TOP_COLOR := Color(0.09, 0.1, 0.12, 1.0)
const GATE_BODY_COLOR := Color(0.055, 0.062, 0.072, 1.0)
const GATE_SPECIAL_TOP_COLOR := Color(0.105, 0.095, 0.12, 1.0)
const GATE_SPECIAL_BODY_COLOR := Color(0.066, 0.058, 0.078, 1.0)

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
var _armed: bool = false
var _arm_delay_remaining: float = 0.0


func _init() -> void:
	_configure_collision_identity()


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
	set_physics_process(unlocked)
	queue_redraw()


func set_visual_rect(center_position: Vector2, size: Vector2) -> void:
	var snapped_center := Vector2(round(center_position.x), round(center_position.y))
	visual_offset = snapped_center - global_position
	visual_size = Vector2(round(size.x), round(size.y))
	_add_or_update_gate_collision()
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
	set_physics_process(unlocked and not _armed)
	queue_redraw()


func is_gate_blocking() -> bool:
	if _gate_body == null or _gate_collision_shape == null:
		return false
	return _gate_body.collision_layer != 0 and not _gate_collision_shape.disabled


func get_gate_blocker_rect() -> Rect2:
	var size := visual_size if visual_size != Vector2.ZERO else door_size
	return Rect2(global_position + visual_offset - size * 0.5, size)


func _configure_collision_identity() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	add_to_group("dungeon_doors")


func _on_body_entered(body: Node) -> void:
	if not unlocked or not _armed or not body.is_in_group("player"):
		return
	_armed = false
	entered.emit(self)


func _on_body_exited(body: Node) -> void:
	if unlocked and _arm_delay_remaining <= 0.0 and body.is_in_group("player"):
		_refresh_armed_state()


func _physics_process(delta: float) -> void:
	if unlocked and not _armed:
		if _arm_delay_remaining > 0.0:
			_arm_delay_remaining = max(_arm_delay_remaining - delta, 0.0)
			set_physics_process(true)
			return
		_refresh_armed_state()


func _refresh_armed_state() -> void:
	_armed = not _has_player_overlap()
	set_physics_process(unlocked and not _armed)


func _has_player_overlap() -> bool:
	for body in get_overlapping_bodies():
		if body != null and is_instance_valid(body) and body.is_in_group("player"):
			return true
	return false


func _draw() -> void:
	var size := visual_size if visual_size != Vector2.ZERO else door_size
	var rect := Rect2(visual_offset - size * 0.5, size)
	var drawn_rect := rect.grow(-1.0) if rect.size.x > 2.0 and rect.size.y > 2.0 else rect
	var trim_color := Color(0.16, 0.17, 0.18, 1.0)
	if not unlocked:
		_draw_locked_gate(drawn_rect, trim_color)
		_draw_room_kind_marker(drawn_rect.get_center(), min(drawn_rect.size.x, drawn_rect.size.y))
	elif has_special_marker():
		var passage_rect := _get_passage_draw_rect(drawn_rect)
		_draw_room_kind_marker(passage_rect.get_center(), min(passage_rect.size.x, passage_rect.size.y))


func _draw_locked_gate(rect: Rect2, trim_color: Color) -> void:
	var top_color := GATE_SPECIAL_TOP_COLOR if has_special_marker() else GATE_TOP_COLOR
	var body_color := GATE_SPECIAL_BODY_COLOR if has_special_marker() else GATE_BODY_COLOR
	match direction:
		"north":
			var north_cap_height: float = min(rect.size.y * 0.5, rect.size.x * 0.25)
			var top_rect := Rect2(rect.position, Vector2(rect.size.x, north_cap_height))
			var body_rect := Rect2(rect.position + Vector2(0.0, north_cap_height), Vector2(rect.size.x, max(rect.size.y - north_cap_height, 1.0)))
			draw_rect(body_rect, body_color, true)
			draw_rect(top_rect, top_color, true)
		"south":
			draw_rect(rect, top_color, true)
		"east", "west":
			var side_cap_height: float = min(rect.size.y * 0.25, rect.size.x)
			var side_top_rect := Rect2(rect.position, Vector2(rect.size.x, side_cap_height))
			var bottom_rect := Rect2(Vector2(rect.position.x, rect.position.y + rect.size.y - side_cap_height), Vector2(rect.size.x, side_cap_height))
			var side_body_rect := Rect2(rect.position + Vector2(0.0, side_cap_height), Vector2(rect.size.x, max(rect.size.y - side_cap_height * 2.0, 1.0)))
			draw_rect(side_body_rect, body_color, true)
			draw_rect(side_top_rect, top_color, true)
			draw_rect(bottom_rect, top_color, true)
		_:
			draw_rect(rect, body_color, true)
	draw_rect(rect, trim_color, false, 2.0)
	_draw_gate_detail_lines(rect, trim_color)


func _draw_gate_detail_lines(rect: Rect2, trim_color: Color) -> void:
	match direction:
		"north":
			draw_line(Vector2(rect.position.x, rect.get_center().y), Vector2(rect.position.x + rect.size.x, rect.get_center().y), trim_color, 1.0)
		"east", "west":
			var cap_height: float = min(rect.size.y * 0.25, rect.size.x)
			var first_y: float = rect.position.y + cap_height
			var second_y: float = rect.position.y + rect.size.y - cap_height
			draw_line(Vector2(rect.position.x, first_y), Vector2(rect.position.x + rect.size.x, first_y), trim_color, 1.0)
			draw_line(Vector2(rect.position.x, second_y), Vector2(rect.position.x + rect.size.x, second_y), trim_color, 1.0)


func _get_passage_draw_rect(fallback_rect: Rect2) -> Rect2:
	if passage_size == Vector2.ZERO:
		return fallback_rect
	return Rect2(passage_offset - passage_size * 0.5, passage_size)


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
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)
	var shape := RectangleShape2D.new()
	shape.size = door_size
	_collision_shape.shape = shape


func _add_or_update_gate_collision() -> void:
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
	if _gate_body == null or _gate_collision_shape == null:
		return
	_gate_body.collision_layer = 32 if value else 0
	_gate_body.collision_mask = 0
	_gate_collision_shape.disabled = not value
