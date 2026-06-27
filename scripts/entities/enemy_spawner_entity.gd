extends StaticBody2D
class_name EnemySpawnerEntity

signal spawn_ready(spawner, spawn_position: Vector2)
signal health_changed(spawner, old_value: int, new_value: int)
signal health_depleted(spawner)

@export var spawn_interval: float = 2.8
@export var warmup_seconds: float = 1.0
@export var active: bool = true
@export var body_radius: float = 32.0
@export var max_health: int = 18
@export var score_value: int = 75

var health: int = max_health
var _timer: float = 0.0
var _hit_flash_remaining: float = 0.0
var _is_destroyed: bool = false
var _collision_shape: CollisionShape2D = null


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	health = max_health
	_configure_collision_identity()
	_add_collision()
	_timer = max(warmup_seconds, 0.0)
	queue_redraw()


func _configure_collision_identity() -> void:
	collision_layer = 16
	collision_mask = 0
	add_to_group("spawners")


func _process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
		queue_redraw()
	if _is_destroyed or not active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		spawn_ready.emit(self, global_position)
		queue_redraw()


func set_enabled(value: bool) -> void:
	active = value and not _is_destroyed


func initialize(spawner_health: int, interval: float, radius: float) -> void:
	max_health = spawner_health
	health = max_health
	spawn_interval = interval
	body_radius = radius


func take_damage(packet) -> void:
	if packet == null or health <= 0 or _is_destroyed:
		return
	var old_health := health
	health = max(health - max(packet.damage, 0), 0)
	_hit_flash_remaining = 0.18
	health_changed.emit(self, old_health, health)
	queue_redraw()
	if health == 0:
		_is_destroyed = true
		active = false
		collision_layer = 0
		collision_mask = 0
		remove_from_group("spawners")
		health_depleted.emit(self)


func _draw() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	var base_color := Color(0.34, 0.28, 0.38)
	var core_color := Color(0.72, 0.24, 0.92)
	if _hit_flash_remaining > 0.0:
		base_color = Color(0.96, 0.9, 0.82)
		core_color = Color(1.0, 0.58, 1.0)
	var base_points := PackedVector2Array([
		Vector2(-body_radius, body_radius * 0.55),
		Vector2(-body_radius * 0.7, -body_radius * 0.6),
		Vector2(0.0, -body_radius),
		Vector2(body_radius * 0.7, -body_radius * 0.6),
		Vector2(body_radius, body_radius * 0.55),
		Vector2(0.0, body_radius)
	])
	draw_colored_polygon(base_points, base_color)
	draw_polyline(_closed_points(base_points), Color(0.08, 0.06, 0.1), 3.0, true)
	draw_rect(Rect2(Vector2(-body_radius * 0.42, -body_radius * 0.38), Vector2(body_radius * 0.84, body_radius * 0.78)), Color(0.16, 0.12, 0.18), true)
	draw_circle(Vector2.ZERO, body_radius * 0.28, core_color)
	draw_arc(Vector2.ZERO, body_radius * 0.38, 0.0, TAU * health_ratio, 28, Color(0.52, 1.0, 0.42), 4.0)
	var damage_level := 1.0 - health_ratio
	if damage_level > 0.22:
		draw_line(Vector2(-body_radius * 0.55, -body_radius * 0.2), Vector2(-body_radius * 0.1, body_radius * 0.18), Color(0.04, 0.03, 0.05), 2.0)
	if damage_level > 0.48:
		draw_line(Vector2(body_radius * 0.52, -body_radius * 0.32), Vector2(body_radius * 0.12, body_radius * 0.4), Color(0.04, 0.03, 0.05), 2.0)
	if damage_level > 0.72:
		draw_line(Vector2(-body_radius * 0.18, -body_radius * 0.72), Vector2(body_radius * 0.42, -body_radius * 0.18), Color(0.04, 0.03, 0.05), 2.0)
	draw_line(Vector2(-body_radius * 0.65, body_radius + 8.0), Vector2(-body_radius * 0.65 + body_radius * 1.3 * health_ratio, body_radius + 8.0), Color(0.45, 1.0, 0.35), 4.0)


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape


func _closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed
