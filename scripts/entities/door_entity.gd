extends Area2D
class_name DoorEntity

signal entered(door)

@export var door_size: Vector2 = Vector2(88.0, 28.0)

var direction: String = "north"
var target_room_id: String = ""
var unlocked: bool = false
var _collision_shape: CollisionShape2D = null
var _armed: bool = false


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	_configure_collision_identity()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()


func initialize(door_direction: String, target_id: String, center_position: Vector2, size: Vector2, is_unlocked: bool) -> void:
	direction = door_direction
	target_room_id = target_id
	global_position = center_position
	door_size = size
	unlocked = is_unlocked
	_armed = false
	_add_or_update_collision()
	set_physics_process(unlocked)
	queue_redraw()


func set_unlocked(value: bool) -> void:
	unlocked = value
	if not unlocked:
		_armed = false
	set_physics_process(unlocked and not _armed)
	queue_redraw()


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
	if unlocked and body.is_in_group("player"):
		_refresh_armed_state()


func _physics_process(_delta: float) -> void:
	if unlocked and not _armed:
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
	var fill_color := Color(0.34, 0.42, 0.48, 0.9)
	var trim_color := Color(0.84, 0.94, 1.0, 1.0)
	if unlocked:
		fill_color = Color(0.1, 0.56, 0.38, 0.9)
		trim_color = Color(0.42, 1.0, 0.72, 1.0)
	var rect := Rect2(-door_size * 0.5, door_size)
	draw_rect(rect, fill_color, true)
	draw_rect(rect, trim_color, false, 3.0)
	if not unlocked:
		draw_line(rect.position + Vector2(8.0, 8.0), rect.position + rect.size - Vector2(8.0, 8.0), trim_color, 3.0)
		draw_line(rect.position + Vector2(rect.size.x - 8.0, 8.0), rect.position + Vector2(8.0, rect.size.y - 8.0), trim_color, 3.0)


func _add_or_update_collision() -> void:
	if _collision_shape == null:
		_collision_shape = CollisionShape2D.new()
		_collision_shape.name = "CollisionShape2D"
		add_child(_collision_shape)
	var shape := RectangleShape2D.new()
	shape.size = door_size
	_collision_shape.shape = shape
