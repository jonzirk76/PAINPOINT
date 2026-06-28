extends StaticBody2D
class_name EnemySpawnerEntity

signal spawn_ready(spawner, spawn_position: Vector2)
signal health_changed(spawner, old_value: int, new_value: int)
signal health_depleted(spawner)
signal shot_ready(spawner, origin: Vector2, direction: Vector2, shot_config: Dictionary)

@export var spawn_interval: float = 2.8
@export var warmup_seconds: float = 1.0
@export var active: bool = true
@export var body_radius: float = 32.0
@export var max_health: int = 18
@export var score_value: int = 75
@export var base_color: Color = Color(0.34, 0.28, 0.38)
@export var core_color: Color = Color(0.72, 0.24, 0.92)
@export var accent_color: Color = Color(0.52, 1.0, 0.42)
@export var shape_kind: String = "basic"
@export var shoots_projectiles: bool = false
@export var shot_cooldown: float = 1.8
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 1
@export var projectile_radius: float = 7.0

var health: int = max_health
var enemy_profile: Resource = null
var target_position: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _shot_timer: float = 0.0
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
	if shoots_projectiles:
		_shot_timer -= delta
		if _shot_timer <= 0.0:
			_shot_timer = shot_cooldown
			_try_emit_shot()


func set_enabled(value: bool) -> void:
	active = value and not _is_destroyed


func initialize(spawner_health: int, interval: float, radius: float) -> void:
	max_health = spawner_health
	health = max_health
	spawn_interval = interval
	body_radius = radius
	_shot_timer = shot_cooldown * 0.5


func initialize_from_profile(profile) -> void:
	if profile == null:
		return
	enemy_profile = profile.enemy_profile
	max_health = profile.max_health
	health = max_health
	spawn_interval = profile.spawn_interval
	body_radius = profile.body_radius
	score_value = profile.score_value
	base_color = profile.base_color
	core_color = profile.core_color
	accent_color = profile.accent_color
	shape_kind = profile.shape_kind
	shoots_projectiles = profile.shoots_projectiles
	shot_cooldown = profile.shot_cooldown
	projectile_speed = profile.projectile_speed
	projectile_damage = profile.projectile_damage
	projectile_radius = profile.projectile_radius
	_shot_timer = shot_cooldown * 0.5


func set_target_position(position: Vector2) -> void:
	target_position = position


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
	var draw_base_color := base_color
	var draw_core_color := core_color
	if _hit_flash_remaining > 0.0:
		draw_base_color = Color(0.96, 0.9, 0.82)
		draw_core_color = Color(1.0, 0.58, 1.0)
	var base_points := PackedVector2Array([
		Vector2(-body_radius, body_radius * 0.55),
		Vector2(-body_radius * 0.7, -body_radius * 0.6),
		Vector2(0.0, -body_radius),
		Vector2(body_radius * 0.7, -body_radius * 0.6),
		Vector2(body_radius, body_radius * 0.55),
		Vector2(0.0, body_radius)
	])
	draw_colored_polygon(base_points, draw_base_color)
	draw_polyline(_closed_points(base_points), Color(0.08, 0.06, 0.1), 3.0, true)
	_draw_type_details(draw_core_color)
	draw_arc(Vector2.ZERO, body_radius * 0.38, 0.0, TAU * health_ratio, 28, accent_color, 4.0)
	var damage_level := 1.0 - health_ratio
	if damage_level > 0.22:
		draw_line(Vector2(-body_radius * 0.55, -body_radius * 0.2), Vector2(-body_radius * 0.1, body_radius * 0.18), Color(0.04, 0.03, 0.05), 2.0)
	if damage_level > 0.48:
		draw_line(Vector2(body_radius * 0.52, -body_radius * 0.32), Vector2(body_radius * 0.12, body_radius * 0.4), Color(0.04, 0.03, 0.05), 2.0)
	if damage_level > 0.72:
		draw_line(Vector2(-body_radius * 0.18, -body_radius * 0.72), Vector2(body_radius * 0.42, -body_radius * 0.18), Color(0.04, 0.03, 0.05), 2.0)
	draw_line(Vector2(-body_radius * 0.65, body_radius + 8.0), Vector2(-body_radius * 0.65 + body_radius * 1.3 * health_ratio, body_radius + 8.0), accent_color, 4.0)


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


func _draw_type_details(draw_core_color: Color) -> void:
	match shape_kind:
		"tank":
			draw_rect(Rect2(Vector2(-body_radius * 0.48, -body_radius * 0.42), Vector2(body_radius * 0.96, body_radius * 0.84)), Color(0.12, 0.08, 0.08), true)
			draw_rect(Rect2(Vector2(-body_radius * 0.32, -body_radius * 0.3), Vector2(body_radius * 0.64, body_radius * 0.6)), draw_core_color, true)
			draw_line(Vector2(-body_radius * 0.75, body_radius * 0.7), Vector2(body_radius * 0.75, body_radius * 0.7), accent_color, 4.0)
		"fast":
			var points := PackedVector2Array([
				Vector2(0.0, -body_radius * 0.52),
				Vector2(body_radius * 0.5, 0.0),
				Vector2(0.0, body_radius * 0.52),
				Vector2(-body_radius * 0.5, 0.0)
			])
			draw_colored_polygon(points, draw_core_color)
			draw_polyline(_closed_points(points), accent_color, 2.0, true)
		"shooter":
			var aim := (target_position - global_position).normalized()
			if aim.length_squared() <= 0.001:
				aim = Vector2.RIGHT
			draw_circle(Vector2.ZERO, body_radius * 0.31, draw_core_color)
			draw_line(Vector2.ZERO, aim * (body_radius * 0.82), accent_color, 7.0)
			draw_circle(aim * (body_radius * 0.82), body_radius * 0.1, Color(0.04, 0.04, 0.07))
		_:
			draw_rect(Rect2(Vector2(-body_radius * 0.42, -body_radius * 0.38), Vector2(body_radius * 0.84, body_radius * 0.78)), Color(0.16, 0.12, 0.18), true)
			draw_circle(Vector2.ZERO, body_radius * 0.28, draw_core_color)


func _try_emit_shot() -> void:
	var to_target := target_position - global_position
	if to_target.length_squared() <= 4.0:
		return
	var shot_direction := to_target.normalized()
	var shot_config := {
		"speed": projectile_speed,
		"damage": projectile_damage,
		"radius": projectile_radius,
		"kind": "hostile"
	}
	shot_ready.emit(self, global_position + shot_direction * (body_radius + projectile_radius + 5.0), shot_direction, shot_config)
