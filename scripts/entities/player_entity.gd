extends CharacterBody2D
class_name PlayerEntity

signal health_changed(old_value: int, new_value: int)
signal health_depleted(entity)

const PLAYER_BODY_TEXTURE := preload("res://art/characters/player_body.svg")
const PLAYER_BODY_BACK_TEXTURE := preload("res://art/characters/player_body_back.svg")
const PLAYER_BODY_SIDE_TEXTURE := preload("res://art/characters/player_body_side.svg")
const PLAYER_ARMS_GUN_TEXTURE := preload("res://art/characters/player_arms_gun.svg")
const PLAYER_ARMS_GUN_LEFT_TEXTURE := preload("res://art/characters/player_arms_gun_left.svg")
const PLAYER_RESTING_PISTOL_TEXTURE := preload("res://art/characters/player_resting_pistol.svg")
const PLAYER_RESTING_PISTOL_LEFT_TEXTURE := preload("res://art/characters/player_resting_pistol_left.svg")

@export var speed: float = 260.0
@export var max_health: int = 8
@export var body_radius: float = 17.0
@export var arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
@export var arena_shape: int = 0
@export var shoot_pose_hold_seconds: float = 0.42

var health: int = max_health
var move_vector: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var invulnerable_remaining: float = 0.0
var invulnerable_duration: float = 0.0

var _base_speed: float = 260.0
var _hit_flash_remaining: float = 0.0
var _heal_flash_remaining: float = 0.0
var _parry_pulse_remaining: float = 0.0
var _parry_pulse_duration: float = 0.28
var _perfect_parry_flash_remaining: float = 0.0
var _perfect_parry_flash_duration: float = 0.36
var _parry_ready_flash_remaining: float = 0.0
var _parry_ready_flash_duration: float = 0.42
var _parry_ready: bool = false
var _parry_effect_radius: float = 154.0
var _parry_perfect_radius: float = 42.0
var _ammo_warning_active: bool = false
var _ammo_warning_text: String = ""
var _ammo_warning_ratio: float = 1.0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _death_elapsed: float = 0.0
var _death_duration: float = 0.75
var _is_dead: bool = false
var _walk_cycle: float = 0.0
var _shoot_pose_remaining: float = 0.0
var _last_move_facing_direction: Vector2 = Vector2.RIGHT


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
	var is_walking := move_vector.length_squared() > 0.01 and not _is_dead
	if is_walking:
		_walk_cycle += delta * 12.0
	var was_shooting := _shoot_pose_remaining > 0.0
	if _shoot_pose_remaining > 0.0:
		_shoot_pose_remaining = max(_shoot_pose_remaining - delta, 0.0)
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
	if _heal_flash_remaining > 0.0:
		_heal_flash_remaining = max(_heal_flash_remaining - delta, 0.0)
	if _parry_pulse_remaining > 0.0:
		_parry_pulse_remaining = max(_parry_pulse_remaining - delta, 0.0)
	if _perfect_parry_flash_remaining > 0.0:
		_perfect_parry_flash_remaining = max(_perfect_parry_flash_remaining - delta, 0.0)
	if _parry_ready_flash_remaining > 0.0:
		_parry_ready_flash_remaining = max(_parry_ready_flash_remaining - delta, 0.0)
	if _is_dead:
		_death_elapsed = min(_death_elapsed + delta, _death_duration)
	if is_walking or was_shooting or _shoot_pose_remaining > 0.0 or _ammo_warning_active or _parry_ready or _parry_ready_flash_remaining > 0.0 or _parry_pulse_remaining > 0.0 or _perfect_parry_flash_remaining > 0.0 or _hit_flash_remaining > 0.0 or _heal_flash_remaining > 0.0 or _is_dead:
		queue_redraw()


func _physics_process(delta: float) -> void:
	if _is_dead:
		velocity = Vector2.ZERO
		return
	velocity = move_vector * speed + _knockback_velocity
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 720.0 * delta)
	move_and_slide()
	global_position = ArenaGeometry.constrain_point(global_position, arena_bounds, arena_shape)


func set_move_vector(vector: Vector2) -> void:
	move_vector = vector.limit_length(1.0)
	if move_vector.length_squared() > 0.01:
		_last_move_facing_direction = move_vector.normalized()
		if _shoot_pose_remaining <= 0.0:
			queue_redraw()


func stop_movement() -> void:
	move_vector = Vector2.ZERO
	velocity = Vector2.ZERO


func set_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	aim_direction = direction.normalized()
	queue_redraw()


func play_shoot_pose(direction: Vector2) -> void:
	if _is_dead or direction.length_squared() <= 0.001:
		return
	aim_direction = direction.normalized()
	_shoot_pose_remaining = max(shoot_pose_hold_seconds, 0.0)
	queue_redraw()


func set_speed_multiplier(multiplier: float) -> void:
	speed = _base_speed * max(multiplier, 0.1)


func set_ammo_warning_state(is_active: bool, text: String, ratio: float) -> void:
	_ammo_warning_active = is_active and not _is_dead
	_ammo_warning_text = text
	_ammo_warning_ratio = clamp(ratio, 0.0, 1.0)
	queue_redraw()


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


func apply_pushback(push_direction: Vector2, force: float) -> void:
	if _is_dead or force <= 0.0:
		return
	var direction := push_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	_knockback_velocity += direction * force
	_knockback_velocity = _knockback_velocity.limit_length(max(force, 360.0))
	queue_redraw()


func play_parry_response(effect_radius: float, perfect_radius: float) -> void:
	if _is_dead:
		return
	_parry_ready = false
	_parry_effect_radius = max(effect_radius, body_radius + 1.0)
	_parry_perfect_radius = clamp(perfect_radius, body_radius + 1.0, _parry_effect_radius)
	_parry_pulse_remaining = _parry_pulse_duration
	queue_redraw()


func play_perfect_parry_response(effect_radius: float, perfect_radius: float) -> void:
	if _is_dead:
		return
	_parry_effect_radius = max(effect_radius, body_radius + 1.0)
	_parry_perfect_radius = clamp(perfect_radius, body_radius + 1.0, _parry_effect_radius)
	_perfect_parry_flash_remaining = _perfect_parry_flash_duration
	queue_redraw()


func set_parry_ready_state(is_ready: bool) -> void:
	_parry_ready = is_ready and not _is_dead
	queue_redraw()


func play_parry_ready_response(effect_radius: float, perfect_radius: float) -> void:
	if _is_dead:
		return
	_parry_effect_radius = max(effect_radius, body_radius + 1.0)
	_parry_perfect_radius = clamp(perfect_radius, body_radius + 1.0, _parry_effect_radius)
	_parry_ready_flash_remaining = _parry_ready_flash_duration
	_parry_ready = true
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
	_knockback_velocity = Vector2.ZERO
	invulnerable_remaining = 0.0
	_parry_ready = false
	_ammo_warning_active = false
	_shoot_pose_remaining = 0.0
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
	_knockback_velocity = Vector2.ZERO
	_parry_pulse_remaining = 0.0
	_perfect_parry_flash_remaining = 0.0
	_parry_ready_flash_remaining = 0.0
	_parry_ready = false
	_ammo_warning_active = false
	_shoot_pose_remaining = 0.0
	_configure_collision_identity()
	set_invulnerability_state(0.0, 0.0)
	health_changed.emit(old_health, health)
	queue_redraw()


func _draw() -> void:
	if _is_dead:
		_draw_death_animation()
		return
	_draw_player_character_art()
	if _hit_flash_remaining > 0.0:
		draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 32, Color(1.0, 1.0, 1.0), 4.0)
	if _heal_flash_remaining > 0.0:
		var heal_ratio: float = clamp(_heal_flash_remaining / 0.24, 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 32, Color(0.28, 1.0, 0.45, heal_ratio), 4.0)
	if invulnerable_remaining > 0.0 and invulnerable_duration > 0.0:
		var ratio: float = clamp(invulnerable_remaining / invulnerable_duration, 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius + 10.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 32, Color(0.45, 1.0, 1.0), 3.0)
	if _parry_ready:
		_draw_parry_ready_idle()
	if _parry_ready_flash_remaining > 0.0:
		_draw_parry_ready_flash()
	if _parry_pulse_remaining > 0.0:
		_draw_parry_pulse()
	if _perfect_parry_flash_remaining > 0.0:
		_draw_perfect_parry_flash()
	if _ammo_warning_active:
		_draw_ammo_warning()


func _draw_player_character_art() -> void:
	_draw_player_walk_feet()
	var tint := Color.WHITE
	if _hit_flash_remaining > 0.0:
		tint = Color(1.0, 0.96, 0.74)
	var visual_radius: float = body_radius * 2.35
	var facing := _get_visual_facing_direction()
	var weapon_aim := aim_direction.normalized()
	if weapon_aim.length_squared() <= 0.001:
		weapon_aim = facing
	var weapon_texture: Texture2D = PLAYER_ARMS_GUN_TEXTURE
	var resting_texture: Texture2D = PLAYER_RESTING_PISTOL_TEXTURE
	var body_texture: Texture2D = PLAYER_BODY_TEXTURE
	var body_scale := Vector2.ONE
	var is_side_facing: bool = abs(facing.x) >= abs(facing.y)
	var is_back_facing: bool = not is_side_facing and facing.y < 0.0
	var weapon_rotation := weapon_aim.angle()
	var resting_rotation: float = clamp(facing.y * 0.18, -0.18, 0.18)
	if move_vector.length_squared() > 0.01:
		resting_rotation += sin(_walk_cycle) * 0.035
	if is_side_facing:
		body_texture = PLAYER_BODY_SIDE_TEXTURE
		body_scale = Vector2(-1.0, 1.0) if facing.x < 0.0 else Vector2.ONE
	elif is_back_facing:
		body_texture = PLAYER_BODY_BACK_TEXTURE
	if facing.x < -0.001:
		resting_texture = PLAYER_RESTING_PISTOL_LEFT_TEXTURE
		resting_rotation = -resting_rotation
	if weapon_aim.x < -0.001:
		weapon_texture = PLAYER_ARMS_GUN_LEFT_TEXTURE
		weapon_rotation = (-weapon_aim).angle()
	if is_back_facing:
		_draw_centered_texture(resting_texture, visual_radius, resting_rotation, tint)
		if _is_shoot_pose_active():
			_draw_centered_texture(weapon_texture, visual_radius, weapon_rotation, tint)
		_draw_centered_texture(body_texture, visual_radius, 0.0, tint, body_scale)
	else:
		_draw_centered_texture(body_texture, visual_radius, 0.0, tint, body_scale)
		_draw_centered_texture(resting_texture, visual_radius, resting_rotation, tint)
		if _is_shoot_pose_active():
			_draw_centered_texture(weapon_texture, visual_radius, weapon_rotation, tint)


func _is_shoot_pose_active() -> bool:
	return _shoot_pose_remaining > 0.0


func _get_visual_facing_direction() -> Vector2:
	if _is_shoot_pose_active() and aim_direction.length_squared() > 0.001:
		return aim_direction.normalized()
	if move_vector.length_squared() > 0.01:
		return move_vector.normalized()
	if _last_move_facing_direction.length_squared() > 0.001:
		return _last_move_facing_direction.normalized()
	return Vector2.RIGHT


func _draw_player_walk_feet() -> void:
	var is_walking := move_vector.length_squared() > 0.01
	var stride_direction := move_vector.normalized() if is_walking else Vector2.RIGHT
	if stride_direction.length_squared() <= 0.001:
		stride_direction = Vector2.RIGHT
	var foot_anchor := Vector2.DOWN * body_radius * 1.18
	var side := Vector2.RIGHT
	var stride: float = sin(_walk_cycle) * body_radius * 0.26 if is_walking else 0.0
	var lift: float = abs(sin(_walk_cycle)) * 0.22 if is_walking else 0.0
	var left_center: Vector2 = foot_anchor - side * body_radius * 0.42 + stride_direction * stride
	var right_center: Vector2 = foot_anchor + side * body_radius * 0.42 - stride_direction * stride
	var left_scale := Vector2(body_radius * 0.34, body_radius * (0.7 + lift))
	var right_scale := Vector2(body_radius * 0.34, body_radius * (0.7 + (0.22 - lift if is_walking else 0.0)))
	var boot_lift := Vector2.DOWN * body_radius * 0.04
	var upper_lift := Vector2.DOWN * body_radius * 0.1
	_draw_oval(left_center + boot_lift, 0.0, left_scale, Color(0.03, 0.07, 0.13, 1.0))
	_draw_oval(right_center + boot_lift, 0.0, right_scale, Color(0.03, 0.07, 0.13, 1.0))
	_draw_oval(left_center - upper_lift, 0.0, left_scale * Vector2(0.62, 0.58), Color(0.06, 0.3, 0.74, 0.88))
	_draw_oval(right_center - upper_lift, 0.0, right_scale * Vector2(0.62, 0.58), Color(0.07, 0.38, 0.86, 0.88))
	_draw_oval(left_center - Vector2.DOWN * body_radius * 0.18, 0.0, left_scale * Vector2(0.3, 0.22), Color(0.13, 0.82, 1.0, 0.7))
	_draw_oval(right_center - Vector2.DOWN * body_radius * 0.18, 0.0, right_scale * Vector2(0.3, 0.22), Color(0.13, 0.82, 1.0, 0.7))


func _draw_centered_texture(texture: Texture2D, visual_radius: float, rotation: float, tint: Color = Color.WHITE, scale: Vector2 = Vector2.ONE) -> void:
	if texture == null:
		return
	draw_set_transform(Vector2.ZERO, rotation, scale)
	draw_texture_rect(texture, Rect2(Vector2(-visual_radius, -visual_radius), Vector2(visual_radius * 2.0, visual_radius * 2.0)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_oval(center: Vector2, rotation: float, scale: Vector2, color: Color) -> void:
	draw_set_transform(center, rotation, scale)
	draw_circle(Vector2.ZERO, 1.0, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_death_animation() -> void:
	var progress: float = clamp(_death_elapsed / _death_duration, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	draw_circle(Vector2.ZERO, body_radius * (1.0 - progress * 0.4), Color(0.28, 0.66, 1.0, alpha))
	draw_arc(Vector2.ZERO, body_radius + progress * 46.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.35, alpha), 5.0)
	draw_arc(Vector2.ZERO, body_radius + 12.0 + progress * 24.0, 0.0, TAU, 40, Color(0.45, 1.0, 1.0, alpha * 0.7), 3.0)
	for index in range(8):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 8.0)
		draw_line(direction * body_radius * 0.35, direction * (body_radius + progress * 58.0), Color(1.0, 0.35, 0.28, alpha), 3.0)


func _draw_parry_pulse() -> void:
	var progress: float = 1.0 - clamp(_parry_pulse_remaining / _parry_pulse_duration, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	draw_circle(Vector2.ZERO, _parry_effect_radius * (0.18 + progress * 0.82), Color(0.2, 0.94, 1.0, alpha * 0.18))
	draw_arc(Vector2.ZERO, _parry_effect_radius * (0.42 + progress * 0.58), 0.0, TAU, 48, Color(0.36, 1.0, 0.95, alpha), 5.0)
	draw_arc(Vector2.ZERO, _parry_perfect_radius, 0.0, TAU, 32, Color(1.0, 1.0, 0.78, alpha), 4.0)
	for index in range(10):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 10.0 + progress * 0.35)
		draw_line(direction * body_radius * 0.7, direction * _parry_effect_radius * (0.7 + progress * 0.3), Color(0.68, 1.0, 1.0, alpha * 0.8), 2.0 + alpha * 2.0)


func _draw_perfect_parry_flash() -> void:
	var remaining_ratio: float = clamp(_perfect_parry_flash_remaining / _perfect_parry_flash_duration, 0.0, 1.0)
	var progress: float = 1.0 - remaining_ratio
	var alpha: float = remaining_ratio
	var bloom_radius: float = lerp(_parry_perfect_radius * 0.8, _parry_effect_radius * 0.72, progress)
	draw_circle(Vector2.ZERO, bloom_radius, Color(1.0, 1.0, 1.0, alpha * 0.2))
	draw_arc(Vector2.ZERO, bloom_radius, 0.0, TAU, 56, Color(1.0, 1.0, 1.0, alpha), 5.5)
	draw_arc(Vector2.ZERO, bloom_radius * 0.72, -PI * 0.2, TAU - PI * 0.2, 44, Color(1.0, 0.92, 0.36, alpha * 0.95), 4.0)
	for index in range(14):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 14.0 + progress * 0.9)
		draw_line(direction * (body_radius + 5.0), direction * (bloom_radius + 18.0), Color(1.0, 1.0, 0.85, alpha * 0.82), 2.5)


func _draw_parry_ready_idle() -> void:
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.012)
	var alpha: float = 0.34 + pulse * 0.34
	draw_arc(Vector2.ZERO, body_radius + 13.0, 0.0, TAU, 32, Color(0.55, 1.0, 0.95, alpha), 2.5)
	draw_arc(Vector2.ZERO, body_radius + 18.0, PI * 0.15, PI * 1.85, 32, Color(1.0, 1.0, 0.72, alpha * 0.7), 2.0)


func _draw_parry_ready_flash() -> void:
	var remaining_ratio: float = clamp(_parry_ready_flash_remaining / _parry_ready_flash_duration, 0.0, 1.0)
	var progress: float = 1.0 - remaining_ratio
	var alpha: float = remaining_ratio
	var outer_radius: float = lerp(_parry_perfect_radius * 1.45, body_radius + 12.0, progress)
	var inner_radius: float = lerp(_parry_perfect_radius * 0.92, body_radius + 4.0, progress)
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 40, Color(0.42, 1.0, 0.95, alpha), 4.0)
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 32, Color(1.0, 1.0, 0.7, alpha * 0.9), 3.0)
	for index in range(8):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 8.0 - progress * 0.4)
		draw_line(direction * outer_radius, direction * (body_radius + 7.0), Color(0.75, 1.0, 1.0, alpha * 0.75), 2.0)


func _draw_ammo_warning() -> void:
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.02)
	var urgency: float = 1.0 - _ammo_warning_ratio
	var alpha: float = 0.42 + pulse * 0.45
	var warning_color := Color(1.0, lerp(0.18, 0.78, _ammo_warning_ratio), 0.08, alpha)
	var radius: float = body_radius + 26.0 + pulse * 5.0
	draw_arc(Vector2.ZERO, radius, -PI * 0.15, TAU - PI * 0.15, 44, warning_color, 3.0 + urgency * 2.0)
	draw_arc(Vector2.ZERO, body_radius + 21.0, -PI / 2.0, -PI / 2.0 + TAU * _ammo_warning_ratio, 36, Color(1.0, 0.92, 0.16, 0.88), 4.0)
	var font := ThemeDB.fallback_font
	if font != null and not _ammo_warning_text.is_empty():
		draw_string(font, Vector2(-42.0, -body_radius - 38.0), _ammo_warning_text, HORIZONTAL_ALIGNMENT_CENTER, 84.0, 14, Color(1.0, 0.96, 0.72, alpha))


func _add_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
