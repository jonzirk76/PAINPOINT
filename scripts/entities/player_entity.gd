extends CharacterBody2D
class_name PlayerEntity

signal health_changed(old_value: int, new_value: int)
signal health_depleted(entity)

@export var speed: float = 260.0
@export var max_health: int = 8
@export var body_radius: float = 17.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0

var health: int = max_health
var move_vector: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var invulnerable_remaining: float = 0.0
var invulnerable_duration: float = 0.0

var _base_speed: float = 260.0
var _hit_flash_remaining: float = 0.0
var _heal_flash_remaining: float = 0.0
var _death_elapsed: float = 0.0
var _death_duration: float = 0.75
var _is_dead: bool = false


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	_base_speed = speed
	health = max_health
	_configure_collision_identity()
	_add_collision()
	queue_redraw()


func _configure_collision_identity() -> void:
	collision_layer = 1
	collision_mask = 34
	add_to_group("player")


func _process(delta: float) -> void:
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
	if _heal_flash_remaining > 0.0:
		_heal_flash_remaining = max(_heal_flash_remaining - delta, 0.0)
	if _is_dead:
		_death_elapsed = min(_death_elapsed + delta, _death_duration)
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return
	velocity = move_vector * speed
	move_and_slide()
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)


func set_move_vector(vector: Vector2) -> void:
	move_vector = vector.limit_length(1.0)


func set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	aim_direction = direction.normalized()
	queue_redraw()


func set_speed_multiplier(multiplier: float) -> void:
	speed = _base_speed * max(multiplier, 0.1)


func set_arena_bounds(bounds: Rect2) -> void:
	arena_bounds = bounds
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)


func set_arena_definition(bounds: Rect2, shape: int) -> void:
	arena_bounds = bounds
	arena_shape = shape
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)


func get_fire_origin() -> Vector2:
	var desired_origin := global_position + aim_direction * (body_radius + 8.0)
	return ArenaGeometry.constrain_point(desired_origin, arena_bounds, arena_shape)


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0 or _is_dead:
		return
	var old_health := health
	health = max(health - amount, 0)
	health_changed.emit(old_health, health)
	queue_redraw()
	if health == 0:
		health_depleted.emit(self)


func heal(amount: int) -> void:
	if amount <= 0 or health <= 0 or _is_dead:
		return
	var old_health := health
	health = min(health + amount, max_health)
	if health == old_health:
		return
	_heal_flash_remaining = 0.24
	health_changed.emit(old_health, health)
	queue_redraw()


func play_hit_response() -> void:
	if _is_dead:
		return
	_hit_flash_remaining = 0.18
	queue_redraw()


func set_invulnerability_state(remaining: float, duration: float) -> void:
	invulnerable_remaining = max(remaining, 0.0)
	invulnerable_duration = max(duration, 0.0)
	if _is_dead:
		modulate.a = 1.0
	elif invulnerable_remaining > 0.0:
		var flicker := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.04)
		modulate.a = lerp(0.34, 0.72, flicker)
	else:
		modulate.a = 1.0
	queue_redraw()


func play_death_animation() -> void:
	if _is_dead:
		return
	_is_dead = true
	move_vector = Vector2.ZERO
	velocity = Vector2.ZERO
	invulnerable_remaining = 0.0
	modulate.a = 1.0
	collision_layer = 0
	collision_mask = 0
	queue_redraw()


func reset_health() -> void:
	var old_health := health
	health = max_health
	_is_dead = false
	_death_elapsed = 0.0
	_hit_flash_remaining = 0.0
	_heal_flash_remaining = 0.0
	_configure_collision_identity()
	set_invulnerability_state(0.0, 0.0)
	health_changed.emit(old_health, health)
	queue_redraw()


func _draw() -> void:
	if _is_dead:
		_draw_death_animation()
		return
	var body_color := Color(0.28, 0.66, 1.0)
	if _hit_flash_remaining > 0.0:
		body_color = Color(1.0, 0.96, 0.72)
	draw_circle(Vector2.ZERO, body_radius, body_color)
	draw_arc(Vector2.ZERO, body_radius + 2.0, 0.0, TAU, 32, Color(0.05, 0.12, 0.18), 2.0)
	var nose := aim_direction.normalized() * (body_radius + 11.0)
	draw_line(Vector2.ZERO, nose, Color(1.0, 0.95, 0.35), 4.0)
	if _hit_flash_remaining > 0.0:
		draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0), 4.0)
	if _heal_flash_remaining > 0.0:
		var heal_ratio: float = clamp(_heal_flash_remaining / 0.24, 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 32, Color(0.28, 1.0, 0.45, heal_ratio), 4.0)
	if invulnerable_remaining > 0.0 and invulnerable_duration > 0.0:
		var ratio: float = clamp(invulnerable_remaining / invulnerable_duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius + 10.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 32, Color(0.45, 1.0, 1.0), 3.0)


func _draw_death_animation() -> void:
	var progress: float = clamp(_death_elapsed / _death_duration, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	draw_circle(Vector2.ZERO, body_radius * (1.0 - progress * 0.4), Color(0.28, 0.66, 1.0, alpha))
	draw_arc(Vector2.ZERO, body_radius + progress * 46.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.35, alpha), 5.0)
	draw_arc(Vector2.ZERO, body_radius + 12.0 + progress * 24.0, 0.0, TAU, 40, Color(0.45, 1.0, 1.0, alpha * 0.7), 3.0)
	for index in range(8):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 8.0)
		draw_line(direction * body_radius * 0.35, direction * (body_radius + progress * 58.0), Color(1.0, 0.35, 0.28, alpha), 3.0)


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
