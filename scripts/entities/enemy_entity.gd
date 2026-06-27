extends CharacterBody2D
class_name EnemyEntity

signal health_changed(enemy, old_value: int, new_value: int)
signal health_depleted(enemy)
signal death_animation_finished(enemy)

@export var max_health: int = 3
@export var speed: float = 85.0
@export var contact_damage: int = 1
@export var contact_radius: float = 34.0
@export var contact_cooldown: float = 0.75
@export var score_value: int = 10
@export var body_radius: float = 18.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0

var health: int = max_health
var target_position: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _hit_flash_remaining: float = 0.0
var _is_dying: bool = false
var _death_elapsed: float = 0.0
var _death_duration: float = 0.34


func _ready() -> void:
	health = max_health
	collision_layer = 2
	collision_mask = 1
	add_to_group("enemies")
	_add_collision()
	queue_redraw()


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
	health = max_health


func _physics_process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
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
	var chase_velocity := Vector2.ZERO
	if to_target.length_squared() > 4.0:
		chase_velocity = to_target.normalized() * speed
	velocity = chase_velocity + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	move_and_slide()
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)
	if _hit_flash_remaining > 0.0 or _knockback_velocity.length_squared() > 1.0:
		queue_redraw()


func set_target_position(position: Vector2) -> void:
	target_position = position


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
	var body_color := Color(1.0, 0.27, 0.22)
	if _hit_flash_remaining > 0.0:
		body_color = Color(1.0, 0.92, 0.86)
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius + 2.0, 0.0, TAU, 24, Color(0.22, 0.05, 0.05), 2.0)
	draw_line(Vector2(-body_radius, -body_radius - 8.0), Vector2(-body_radius + body_radius * 2.0 * health_ratio, -body_radius - 8.0), Color(0.4, 1.0, 0.35), 3.0)


func _apply_knockback(packet) -> void:
	if packet.knockback <= 0.0:
		return
	var push_direction: Vector2 = packet.knockback_direction
	if push_direction.length_squared() <= 0.001 and packet.source_position.distance_squared_to(global_position) > 0.001:
		push_direction = (global_position - packet.source_position).normalized()
	if push_direction.length_squared() <= 0.001:
		return
	_knockback_velocity += push_direction.normalized() * packet.knockback
	_knockback_velocity = _knockback_velocity.limit_length(260.0)


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
