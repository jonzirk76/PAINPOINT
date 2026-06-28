extends CharacterBody2D
class_name EnemyEntity

signal health_changed(enemy, old_value: int, new_value: int)
signal health_depleted(enemy)
signal death_animation_finished(enemy)
signal shot_ready(enemy, origin: Vector2, direction: Vector2, shot_config: Dictionary)

@export var max_health: int = 3
@export var speed: float = 85.0
@export var contact_damage: int = 1
@export var contact_radius: float = 34.0
@export var contact_cooldown: float = 0.75
@export var score_value: int = 10
@export var body_radius: float = 18.0
@export var knockback_multiplier: float = 1.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0
@export var behavior_kind: String = "chaser"
@export var body_color: Color = Color(1.0, 0.27, 0.22)
@export var accent_color: Color = Color(1.0, 0.72, 0.18)
@export var preferred_distance: float = 280.0
@export var distance_band: float = 70.0
@export var strafe_speed: float = 95.0
@export var shot_cooldown: float = 1.2
@export var projectile_speed: float = 250.0
@export var projectile_damage: int = 1
@export var projectile_radius: float = 7.0
@export var shot_projectile_count: int = 1
@export var shot_spread_degrees: float = 0.0

var health: int = max_health
var target_position: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _hit_flash_remaining: float = 0.0
var _is_dying: bool = false
var _death_elapsed: float = 0.0
var _death_duration: float = 0.34
var _shot_cooldown_remaining: float = 0.0
var _strafe_sign: float = 1.0


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	health = max_health
	_configure_collision_identity()
	_add_collision()
	queue_redraw()


func _configure_collision_identity() -> void:
	collision_layer = 2
	collision_mask = 33
	add_to_group("enemies")


func initialize(profile) -> void:
	if profile == null:
		return
	max_health = profile.max_health
	speed = profile.speed
	contact_damage = profile.contact_damage
	contact_radius = profile.contact_radius
	contact_cooldown = profile.contact_cooldown
	score_value = profile.score_value
	body_radius = profile.body_radius
	knockback_multiplier = profile.knockback_multiplier
	behavior_kind = profile.behavior_kind
	body_color = profile.body_color
	accent_color = profile.accent_color
	preferred_distance = profile.preferred_distance
	distance_band = profile.distance_band
	strafe_speed = profile.strafe_speed
	shot_cooldown = profile.shot_cooldown
	projectile_speed = profile.projectile_speed
	projectile_damage = profile.projectile_damage
	projectile_radius = profile.projectile_radius
	shot_projectile_count = profile.shot_projectile_count
	shot_spread_degrees = profile.shot_spread_degrees
	health = max_health
	_shot_cooldown_remaining = shot_cooldown * 0.65


func _physics_process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
	if _shot_cooldown_remaining > 0.0:
		_shot_cooldown_remaining = max(_shot_cooldown_remaining - delta, 0.0)
	if _is_dying:
		_death_elapsed += delta
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
		move_and_slide()
		global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)
		queue_redraw()
		if _death_elapsed >= _death_duration:
			death_animation_finished.emit(self)
			queue_free()
		return

	var to_target := target_position - global_position
	var intent_velocity := _get_ranged_velocity(to_target) if behavior_kind == "shooter" or behavior_kind == "boss" else _get_chaser_velocity(to_target)
	_try_emit_shot(to_target)
	velocity = intent_velocity + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	move_and_slide()
	if (behavior_kind == "shooter" or behavior_kind == "boss") and get_slide_collision_count() > 0:
		_strafe_sign *= -1.0
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)
	if behavior_kind == "shooter" or behavior_kind == "boss" or _hit_flash_remaining > 0.0 or _knockback_velocity.length_squared() > 1.0:
		queue_redraw()


func set_target_position(position: Vector2) -> void:
	var previous_position := target_position
	target_position = position
	if (behavior_kind == "shooter" or behavior_kind == "boss") and previous_position.distance_squared_to(target_position) > 1.0:
		queue_redraw()


func set_arena_definition(bounds: Rect2, shape: int) -> void:
	arena_bounds = bounds
	arena_shape = shape
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)


func take_damage(packet) -> void:
	if packet == null or health <= 0 or _is_dying:
		return
	_apply_knockback(packet)
	_hit_flash_remaining = 0.12
	var old_health := health
	health = max(health - max(packet.damage, 0), 0)
	health_changed.emit(self, old_health, health)
	queue_redraw()
	if health == 0:
		health_depleted.emit(self)
		_play_death_animation()


func _draw() -> void:
	if _is_dying:
		_draw_death_animation()
		return
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	var draw_color := body_color
	if _hit_flash_remaining > 0.0:
		draw_color = Color(1.0, 0.92, 0.86)
	draw_circle(Vector2.ZERO, body_radius, draw_color)
	draw_arc(Vector2.ZERO, body_radius + 2.0, 0.0, TAU, 24, Color(0.22, 0.05, 0.05), 2.0)
	draw_line(Vector2(-body_radius, -body_radius - 8.0), Vector2(-body_radius + body_radius * 2.0 * health_ratio, -body_radius - 8.0), Color(0.4, 1.0, 0.35), 3.0)
	if behavior_kind == "shooter" or behavior_kind == "boss":
		var aim := (target_position - global_position).normalized()
		if aim.length_squared() <= 0.001:
			aim = Vector2.RIGHT
		if behavior_kind == "boss":
			draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 36, accent_color, 4.0)
			draw_circle(-aim * body_radius * 0.22, body_radius * 0.25, Color(0.05, 0.04, 0.06))
		draw_line(Vector2.ZERO, aim * (body_radius + 14.0), accent_color, 5.0)
		draw_circle(aim * (body_radius + 14.0), 4.5, Color(0.06, 0.05, 0.08))
	else:
		draw_circle(Vector2.ZERO, body_radius * 0.34, accent_color)


func _apply_knockback(packet) -> void:
	var effective_knockback: float = packet.knockback * max(knockback_multiplier, 0.0)
	if effective_knockback <= 0.0:
		return
	var push_direction: Vector2 = packet.knockback_direction
	if push_direction.length_squared() <= 0.001 and packet.source_position.distance_squared_to(global_position) > 0.001:
		push_direction = (global_position - packet.source_position).normalized()
	if push_direction.length_squared() <= 0.001:
		return
	_knockback_velocity += push_direction.normalized() * effective_knockback
	_knockback_velocity = _knockback_velocity.limit_length(260.0)


func _get_chaser_velocity(to_target: Vector2) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	return to_target.normalized() * speed


func _get_ranged_velocity(to_target: Vector2) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	var distance := to_target.length()
	var direction := to_target / distance
	var radial_velocity := Vector2.ZERO
	if distance > preferred_distance + distance_band:
		radial_velocity = direction * speed
	elif distance < preferred_distance - distance_band:
		radial_velocity = -direction * speed
	var strafe_velocity := direction.orthogonal() * _strafe_sign * strafe_speed
	return radial_velocity + strafe_velocity


func _try_emit_shot(to_target: Vector2) -> void:
	if behavior_kind != "shooter" and behavior_kind != "boss":
		return
	if _shot_cooldown_remaining > 0.0 or to_target.length_squared() <= 4.0:
		return
	var shot_direction := to_target.normalized()
	var shot_config := {
		"speed": projectile_speed,
		"damage": projectile_damage,
		"radius": projectile_radius,
		"kind": "hostile",
		"projectile_count": max(shot_projectile_count, 1),
		"spread_angle_degrees": shot_spread_degrees
	}
	shot_ready.emit(self, global_position + shot_direction * (body_radius + projectile_radius + 4.0), shot_direction, shot_config)
	_shot_cooldown_remaining = shot_cooldown


func _play_death_animation() -> void:
	if _is_dying:
		return
	_is_dying = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_hit_flash_remaining = 0.0
	queue_redraw()


func _draw_death_animation() -> void:
	var progress: float = clamp(_death_elapsed / _death_duration, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	draw_circle(Vector2.ZERO, body_radius * (1.0 - progress * 0.65), Color(1.0, 0.27, 0.22, alpha))
	draw_arc(Vector2.ZERO, body_radius + progress * 34.0, 0.0, TAU, 28, Color(1.0, 0.72, 0.18, alpha), 4.0)
	for index in range(6):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 6.0)
		draw_line(direction * body_radius * 0.25, direction * (body_radius + progress * 42.0), Color(1.0, 0.18, 0.1, alpha), 3.0)


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
