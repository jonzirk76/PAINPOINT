extends CharacterBody2D
class_name EnemyEntity

signal health_changed(enemy, old_value: int, new_value: int)
signal health_depleted(enemy)
signal death_animation_finished(enemy)
signal shot_ready(enemy, origin: Vector2, direction: Vector2, shot_config: Dictionary)

const BASIC_ENEMY_TEXTURE := preload("res://art/characters/basic_enemy_chaser.svg")
const FAST_ENEMY_TEXTURE := preload("res://art/characters/fast_enemy_runner.svg")
const TANK_ENEMY_TEXTURE := preload("res://art/characters/tank_enemy_brute.svg")
const SHOOTER_ENEMY_TEXTURE := preload("res://art/characters/shooter_enemy_orbiter.svg")
const BOSS_ENEMY_TEXTURE := preload("res://art/characters/boss_enemy_overlord.svg")
const PATH_REPATH_BASE_SECONDS := 0.1
const PATH_REPATH_STAGGER_SECONDS := 0.015
const PATH_CACHE_TARGET_MOVE_SQUARED := 48.0 * 48.0
const PATH_CACHE_SELF_MOVE_SQUARED := 36.0 * 36.0

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
@export var wall_rects: Array[Rect2] = []
@export var void_rects: Array[Rect2] = []
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
@export var projectile_shield_radius_bonus: float = 20.0
@export var boss_special_cooldown: float = 5.4
@export var boss_special_telegraph_seconds: float = 0.72
@export var boss_minigun_duration: float = 0.86
@export var boss_minigun_shot_interval: float = 0.065
@export var boss_minigun_sweep_degrees: float = 82.0

var health: int = max_health
var playable_rects: Array[Rect2] = []
var target_position: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _crowd_separation_velocity: Vector2 = Vector2.ZERO
var _hit_flash_remaining: float = 0.0
var _is_dying: bool = false
var _death_elapsed: float = 0.0
var _death_duration: float = 0.34
var _shot_cooldown_remaining: float = 0.0
var _strafe_sign: float = 1.0
var _visual_kind: String = "basic"
var _visual_direction: Vector2 = Vector2.RIGHT
var _projectile_shield_remaining: float = 0.0
var _projectile_shield_block_flash_remaining: float = 0.0
var _birth_remaining: float = 0.0
var _birth_duration: float = 0.36
var _boss_special_timer: float = 0.0
var _boss_special_telegraph_remaining: float = 0.0
var _boss_special_telegraph_duration: float = 0.72
var _boss_special_kind: String = ""
var _boss_special_sequence_index: int = 0
var _boss_minigun_remaining: float = 0.0
var _boss_minigun_elapsed: float = 0.0
var _boss_minigun_next_shot_remaining: float = 0.0
var _boss_minigun_base_direction: Vector2 = Vector2.RIGHT
var _path_blocker_rects: Array[Rect2] = []
var _cached_steering_target: Vector2 = Vector2.INF
var _path_cache_target_position: Vector2 = Vector2.INF
var _path_cache_enemy_position: Vector2 = Vector2.INF
var _path_repath_remaining: float = 0.0
var _path_repath_interval: float = PATH_REPATH_BASE_SECONDS


func _init() -> void:
	_configure_collision_identity()


func _ready() -> void:
	health = max_health
	_configure_collision_identity()
	_configure_path_cache_timing()
	_add_collision()
	queue_redraw()


func _configure_collision_identity() -> void:
	collision_layer = 2
	collision_mask = 97
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
	_visual_kind = _get_visual_kind(profile)
	health = max_health
	_shot_cooldown_remaining = shot_cooldown * 0.65
	if behavior_kind == "boss":
		_boss_special_timer = boss_special_cooldown * 0.55
		_boss_special_sequence_index = 0


func _physics_process(delta: float) -> void:
	_update_projectile_shield(delta)
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
	if _shot_cooldown_remaining > 0.0:
		_shot_cooldown_remaining = max(_shot_cooldown_remaining - delta, 0.0)
	if _path_repath_remaining > 0.0:
		_path_repath_remaining = max(_path_repath_remaining - delta, 0.0)
	if _is_dying:
		_death_elapsed += delta
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 420.0 * delta)
		move_and_slide()
		global_position = _constrain_to_playable(global_position)
		queue_redraw()
		if _death_elapsed >= _death_duration:
			death_animation_finished.emit(self)
			queue_free()
		return
	if _birth_remaining > 0.0:
		_birth_remaining = max(_birth_remaining - delta, 0.0)
		velocity = Vector2.ZERO
		if _birth_remaining <= 0.0:
			_configure_collision_identity()
		queue_redraw()
		return

	var to_target := target_position - global_position
	var intent_velocity := _get_ranged_velocity(to_target) if behavior_kind == "shooter" or behavior_kind == "boss" else _get_chaser_velocity(to_target)
	var special_active := _update_boss_special(delta, to_target)
	if not special_active:
		_try_emit_shot(to_target)
	elif _boss_minigun_remaining > 0.0:
		intent_velocity = Vector2.ZERO
	else:
		intent_velocity *= 0.38
	velocity = intent_velocity + _knockback_velocity + _crowd_separation_velocity
	_update_visual_direction(velocity)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	_crowd_separation_velocity = _crowd_separation_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	if (behavior_kind == "shooter" or behavior_kind == "boss") and get_slide_collision_count() > 0:
		_strafe_sign *= -1.0
	global_position = _constrain_to_playable(global_position)
	if velocity.length_squared() > 1.0 or behavior_kind == "shooter" or behavior_kind == "boss" or _hit_flash_remaining > 0.0 or _knockback_velocity.length_squared() > 1.0 or is_projectile_shield_active() or _projectile_shield_block_flash_remaining > 0.0:
		queue_redraw()


func set_target_position(position: Vector2) -> void:
	var previous_position := target_position
	target_position = position
	if (behavior_kind == "shooter" or behavior_kind == "boss") and previous_position.distance_squared_to(target_position) > 1.0:
		queue_redraw()


func set_arena_definition(bounds: Rect2, shape: int, walls: Array = [], voids: Array = [], playable_regions: Array = []) -> void:
	arena_bounds = bounds
	arena_shape = shape
	wall_rects.clear()
	for wall in walls:
		if wall is Rect2:
			wall_rects.append(wall)
	void_rects.clear()
	for void_rect in voids:
		if void_rect is Rect2:
			void_rects.append(void_rect)
	playable_rects.clear()
	for playable_rect in playable_regions:
		if playable_rect is Rect2:
			playable_rects.append(playable_rect)
	_rebuild_path_blocker_cache()
	_invalidate_path_cache()
	global_position = _constrain_to_playable(global_position)


func take_damage(packet) -> bool:
	if packet == null or health <= 0 or _is_dying or is_birth_animation_active():
		return false
	if blocks_projectile_damage(packet):
		return false
	var damage_amount: int = max(int(packet.damage), 0)
	if _should_reduce_shield_pierce_damage(packet):
		damage_amount = max(roundi(float(damage_amount) * clamp(float(packet.shield_damage_multiplier), 0.05, 1.0)), 1)
		_projectile_shield_block_flash_remaining = 0.24
	_apply_knockback(packet)
	_hit_flash_remaining = 0.12
	var old_health := health
	health = max(health - damage_amount, 0)
	health_changed.emit(self, old_health, health)
	queue_redraw()
	if health == 0:
		health_depleted.emit(self)
		_play_death_animation()
	return true


func activate_projectile_shield(duration: float) -> void:
	if duration <= 0.0 or health <= 0 or _is_dying:
		return
	_projectile_shield_remaining = max(_projectile_shield_remaining, duration)
	queue_redraw()


func is_projectile_shield_active() -> bool:
	return _projectile_shield_remaining > 0.0 and health > 0 and not _is_dying


func blocks_projectile_damage(packet) -> bool:
	if packet == null or not is_projectile_shield_active():
		return false
	if String(packet.projectile_kind) == "hostile":
		return false
	if bool(packet.pierces_projectile_shields):
		return false
	_projectile_shield_block_flash_remaining = 0.2
	queue_redraw()
	return true


func is_super_shot_impact_target() -> bool:
	return behavior_kind == "boss" or max_health >= 8 or body_radius >= 27.0 or knockback_multiplier <= 0.05


func apply_pushback(source_position: Vector2, force: float) -> void:
	if force <= 0.0 or health <= 0 or _is_dying or is_birth_animation_active():
		return
	var push_direction := global_position - source_position
	if push_direction.length_squared() <= 0.001:
		push_direction = Vector2.RIGHT
	_knockback_velocity += push_direction.normalized() * force
	_knockback_velocity = _knockback_velocity.limit_length(max(force, 260.0))
	queue_redraw()


func apply_crowd_separation(push_vector: Vector2) -> void:
	if health <= 0 or _is_dying or is_birth_animation_active() or push_vector.length_squared() <= 0.001:
		return
	_crowd_separation_velocity += push_vector
	_crowd_separation_velocity = _crowd_separation_velocity.limit_length(150.0)


func play_birth_animation(duration: float = 0.36) -> void:
	if health <= 0 or _is_dying:
		return
	_birth_duration = max(duration, 0.08)
	_birth_remaining = _birth_duration
	collision_layer = 0
	collision_mask = 0
	queue_redraw()


func _configure_path_cache_timing() -> void:
	_path_repath_interval = PATH_REPATH_BASE_SECONDS + float(get_instance_id() % 7) * PATH_REPATH_STAGGER_SECONDS


func _rebuild_path_blocker_cache() -> void:
	_path_blocker_rects.clear()
	_path_blocker_rects.append_array(wall_rects)
	_path_blocker_rects.append_array(void_rects)


func _constrain_to_playable(position: Vector2) -> Vector2:
	return ArenaGeometry.constrain_point_to_playable_regions(position, arena_bounds, arena_shape, playable_rects, [], body_radius)


func _invalidate_path_cache() -> void:
	_cached_steering_target = Vector2.INF
	_path_cache_target_position = Vector2.INF
	_path_cache_enemy_position = Vector2.INF
	_path_repath_remaining = 0.0


func is_birth_animation_active() -> bool:
	return _birth_remaining > 0.0 and health > 0 and not _is_dying


func _get_birth_fade_alpha() -> float:
	if not is_birth_animation_active():
		return 1.0
	var progress: float = 1.0 - clamp(_birth_remaining / max(_birth_duration, 0.001), 0.0, 1.0)
	return clamp(0.08 + pow(progress, 0.45) * 0.92, 0.08, 1.0)


func _draw() -> void:
	if _is_dying:
		_draw_death_animation()
		return
	if is_birth_animation_active():
		_draw_birth_animation_underlay()
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(health) / float(max_health)
	var birth_alpha := _get_birth_fade_alpha()
	var draw_color := Color(1.0, 1.0, 1.0, birth_alpha)
	if _hit_flash_remaining > 0.0:
		draw_color = Color(1.0, 0.92, 0.86, birth_alpha)
	_draw_enemy_character_art(draw_color)
	if is_projectile_shield_active() or _projectile_shield_block_flash_remaining > 0.0:
		_draw_projectile_shield()
	if _boss_special_telegraph_remaining > 0.0:
		_draw_boss_special_telegraph()
	if _boss_minigun_remaining > 0.0:
		_draw_boss_minigun_sweep()
	draw_line(Vector2(-body_radius, -body_radius - 8.0), Vector2(-body_radius + body_radius * 2.0 * health_ratio, -body_radius - 8.0), Color(0.4, 1.0, 0.35, birth_alpha), 3.0)
	if behavior_kind == "shooter" or behavior_kind == "boss":
		var aim := (target_position - global_position).normalized()
		if aim.length_squared() <= 0.001:
			aim = Vector2.RIGHT
		var aim_color := Color(accent_color.r, accent_color.g, accent_color.b, birth_alpha)
		if behavior_kind == "boss":
			draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 36, aim_color, 4.0)
		draw_line(Vector2.ZERO, aim * (body_radius + 14.0), aim_color, 3.0)
		draw_circle(aim * (body_radius + 14.0), 3.5, Color(0.06, 0.05, 0.08, birth_alpha))
	if _hit_flash_remaining > 0.0:
		draw_circle(Vector2.ZERO, body_radius * 1.08, Color(1.0, 0.95, 0.82, 0.28))
		draw_arc(Vector2.ZERO, body_radius + 4.0, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.8), 3.0)
	if is_birth_animation_active():
		_draw_birth_animation_overlay()


func _draw_enemy_character_art(tint: Color) -> void:
	var texture := _get_visual_texture()
	if texture == null:
		return
	var visual_radius: float = body_radius * _get_visual_scale()
	var rotation: float = _get_visual_rotation()
	draw_set_transform(Vector2.ZERO, rotation, Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2(-visual_radius, -visual_radius), Vector2(visual_radius * 2.0, visual_radius * 2.0)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _get_visual_texture() -> Texture2D:
	match _visual_kind:
		"fast":
			return FAST_ENEMY_TEXTURE
		"tank":
			return TANK_ENEMY_TEXTURE
		"shooter":
			return SHOOTER_ENEMY_TEXTURE
		"boss":
			return BOSS_ENEMY_TEXTURE
	return BASIC_ENEMY_TEXTURE


func _get_visual_scale() -> float:
	match _visual_kind:
		"fast":
			return 2.0
		"tank":
			return 2.05
		"boss":
			return 1.55
	return 1.9


func _get_visual_rotation() -> float:
	if _visual_direction.length_squared() <= 0.001:
		return 0.0
	return _visual_direction.angle()


func _update_visual_direction(movement: Vector2) -> void:
	if movement.length_squared() <= 1.0:
		return
	_visual_direction = movement.normalized()


func _draw_projectile_shield() -> void:
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.018)
	var block_ratio: float = clamp(_projectile_shield_block_flash_remaining / 0.2, 0.0, 1.0)
	var radius: float = body_radius + projectile_shield_radius_bonus + pulse * 3.0 + block_ratio * 6.0
	draw_circle(Vector2.ZERO, radius, Color(0.42, 0.84, 1.0, 0.12 + block_ratio * 0.16))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(0.64, 1.0, 1.0, 0.72 + block_ratio * 0.25), 5.0 + block_ratio * 2.0)
	draw_arc(Vector2.ZERO, radius * 0.78, -PI * 0.18, TAU - PI * 0.18, 52, Color(1.0, 1.0, 0.82, 0.45 + block_ratio * 0.36), 3.2)
	draw_arc(Vector2.ZERO, radius * 1.12, PI * 0.2, PI * 1.8, 52, Color(0.85, 0.7, 1.0, 0.38 + block_ratio * 0.28), 2.6)


func _draw_birth_animation_underlay() -> void:
	var progress: float = 1.0 - clamp(_birth_remaining / max(_birth_duration, 0.001), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.03)
	var outer_radius: float = body_radius * (2.35 - progress * 0.7)
	draw_circle(Vector2.ZERO, outer_radius, Color(0.35, 0.85, 1.0, 0.1 + pulse * 0.06))
	draw_arc(Vector2.ZERO, outer_radius, progress * TAU, progress * TAU + TAU * 0.78, 36, Color(0.58, 1.0, 1.0, 0.82), 4.0)
	draw_arc(Vector2.ZERO, outer_radius * 0.62, -progress * TAU * 1.3, -progress * TAU * 1.3 + TAU * 0.64, 28, Color(1.0, 0.9, 0.42, 0.68), 3.0)


func _draw_birth_animation_overlay() -> void:
	var progress: float = 1.0 - clamp(_birth_remaining / max(_birth_duration, 0.001), 0.0, 1.0)
	var beam_height: float = body_radius * (2.8 - progress)
	draw_line(Vector2(0.0, -beam_height), Vector2.ZERO, Color(0.72, 1.0, 1.0, 0.65 * (1.0 - progress * 0.4)), 3.0)
	for index in range(5):
		var angle: float = TAU * float(index) / 5.0 + progress * TAU
		var from_point := Vector2.RIGHT.rotated(angle) * body_radius * (0.5 + progress * 0.3)
		var to_point := Vector2.RIGHT.rotated(angle) * body_radius * (1.3 + progress * 0.7)
		draw_line(from_point, to_point, Color(1.0, 1.0, 1.0, 0.58 * (1.0 - progress * 0.35)), 2.0)


func _draw_boss_special_telegraph() -> void:
	var progress: float = 1.0 - clamp(_boss_special_telegraph_remaining / max(_boss_special_telegraph_duration, 0.001), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.045)
	var aim := (target_position - global_position).normalized()
	if aim.length_squared() <= 0.001:
		aim = Vector2.RIGHT
	var telegraph_color := Color(1.0, 0.92, 0.28, 0.78)
	if _boss_special_kind == "rocket":
		telegraph_color = Color(1.0, 0.32, 0.12, 0.86)
	var radius: float = body_radius + 16.0 + progress * 18.0 + pulse * 4.0
	draw_circle(Vector2.ZERO, radius, Color(telegraph_color.r, telegraph_color.g, telegraph_color.b, 0.09 + pulse * 0.08))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 54, telegraph_color, 5.0)
	if _boss_special_kind == "minigun":
		var sweep_direction := aim.rotated(sin(progress * PI * 4.0) * 0.55)
		var side := sweep_direction.orthogonal()
		draw_line(side * -body_radius * 1.1, sweep_direction * (body_radius + 82.0), Color(1.0, 0.96, 0.58, 0.75), 4.0)
		draw_line(side * body_radius * 1.1, sweep_direction * (body_radius + 82.0), Color(0.54, 1.0, 1.0, 0.45), 3.0)
	else:
		draw_line(Vector2.ZERO, aim * (body_radius + 92.0), Color(1.0, 0.42, 0.18, 0.85), 5.0)
		draw_arc(aim * (body_radius + 78.0), 15.0 + pulse * 6.0, 0.0, TAU, 28, Color(1.0, 0.8, 0.28, 0.78), 3.0)


func _draw_boss_minigun_sweep() -> void:
	var direction := _get_boss_minigun_direction()
	var side := direction.orthogonal()
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.075)
	draw_line(side * -body_radius * 0.9, direction * (body_radius + 96.0), Color(1.0, 0.96, 0.42, 0.72 + pulse * 0.18), 4.0)
	draw_line(side * body_radius * 0.9, direction * (body_radius + 78.0), Color(0.45, 1.0, 1.0, 0.44 + pulse * 0.12), 3.0)
	draw_circle(direction * (body_radius + 34.0), 5.0 + pulse * 2.0, Color(1.0, 0.82, 0.16, 0.74))


func _get_visual_kind(profile) -> String:
	if String(profile.behavior_kind) == "boss":
		return "boss"
	if String(profile.behavior_kind) == "shooter":
		return "shooter"
	if float(profile.knockback_multiplier) <= 0.0 or int(profile.max_health) >= 8 or float(profile.body_radius) >= 26.0:
		return "tank"
	if float(profile.speed) >= 120.0 or float(profile.body_radius) <= 14.0:
		return "fast"
	return "basic"


func _apply_knockback(packet) -> void:
	var effective_knockback: float = packet.knockback * max(knockback_multiplier, 0.0)
	if _should_reduce_shield_pierce_damage(packet):
		effective_knockback *= clamp(float(packet.shield_knockback_multiplier), 0.0, 1.0)
	if effective_knockback <= 0.0:
		return
	var push_direction: Vector2 = packet.knockback_direction
	if push_direction.length_squared() <= 0.001 and packet.source_position.distance_squared_to(global_position) > 0.001:
		push_direction = (global_position - packet.source_position).normalized()
	if push_direction.length_squared() <= 0.001:
		return
	_knockback_velocity += push_direction.normalized() * effective_knockback
	_knockback_velocity = _knockback_velocity.limit_length(260.0)


func _should_reduce_shield_pierce_damage(packet) -> bool:
	if packet == null or not is_projectile_shield_active():
		return false
	return bool(packet.pierces_projectile_shields) and String(packet.projectile_kind) != "hostile"


func _update_boss_special(delta: float, to_target: Vector2) -> bool:
	if behavior_kind != "boss" or health <= 0 or _is_dying:
		return false
	if _boss_minigun_remaining > 0.0:
		_update_boss_minigun(delta)
		return true
	if _boss_special_telegraph_remaining > 0.0:
		_boss_special_telegraph_remaining = max(_boss_special_telegraph_remaining - delta, 0.0)
		if _boss_special_telegraph_remaining <= 0.0:
			if _boss_special_kind == "minigun":
				_start_boss_minigun(to_target)
			else:
				_emit_boss_special(to_target)
				_finish_boss_special()
		queue_redraw()
		return true
	_boss_special_timer = max(_boss_special_timer - delta, 0.0)
	if _boss_special_timer > 0.0 or to_target.length_squared() <= 4.0:
		return false
	if _wall_blocks_segment(global_position, target_position):
		return false
	_boss_special_kind = "minigun" if _boss_special_sequence_index % 2 == 0 else "rocket"
	_boss_special_telegraph_duration = max(boss_special_telegraph_seconds, 0.1)
	_boss_special_telegraph_remaining = _boss_special_telegraph_duration
	activate_projectile_shield(_boss_special_telegraph_duration + 0.45)
	queue_redraw()
	return true


func _emit_boss_special(to_target: Vector2) -> void:
	if to_target.length_squared() <= 4.0:
		return
	var shot_direction := to_target.normalized()
	var shot_config := _get_boss_special_shot_config(_boss_special_kind)
	var radius: float = float(shot_config.get("radius", projectile_radius))
	var shot_origin := global_position + shot_direction * (body_radius + radius + 6.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	if _boss_special_kind == "rocket":
		var target_position_at_launch := global_position + to_target
		var target_direction := target_position_at_launch - shot_origin
		if target_direction.length_squared() > 4.0:
			shot_direction = target_direction.normalized()
		var rocket_speed: float = max(float(shot_config.get("speed", projectile_speed)), 1.0)
		shot_config["target_position"] = target_position_at_launch
		shot_config["lifetime"] = max(shot_origin.distance_to(target_position_at_launch) / rocket_speed, 0.08)
		shot_config["exact_lifetime"] = true
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)


func _start_boss_minigun(to_target: Vector2) -> void:
	if to_target.length_squared() <= 4.0:
		_finish_boss_special()
		return
	_boss_minigun_base_direction = to_target.normalized()
	_boss_minigun_elapsed = 0.0
	_boss_minigun_remaining = max(boss_minigun_duration, 0.12)
	_boss_minigun_next_shot_remaining = max(boss_minigun_shot_interval, 0.025)
	_emit_boss_minigun_shot()


func _update_boss_minigun(delta: float) -> void:
	_boss_minigun_elapsed = min(_boss_minigun_elapsed + delta, max(boss_minigun_duration, 0.12))
	_boss_minigun_remaining = max(max(boss_minigun_duration, 0.12) - _boss_minigun_elapsed, 0.0)
	_boss_minigun_next_shot_remaining -= delta
	var interval: float = max(boss_minigun_shot_interval, 0.025)
	var emitted_count := 0
	while _boss_minigun_remaining > 0.0 and _boss_minigun_next_shot_remaining <= 0.0 and emitted_count < 8:
		_emit_boss_minigun_shot()
		_boss_minigun_next_shot_remaining += interval
		emitted_count += 1
	if _boss_minigun_remaining <= 0.0:
		_finish_boss_special()
	queue_redraw()


func _emit_boss_minigun_shot() -> void:
	var shot_direction := _get_boss_minigun_direction()
	var shot_config := _get_boss_special_shot_config("minigun")
	var radius: float = float(shot_config.get("radius", projectile_radius))
	var shot_origin := global_position + shot_direction * (body_radius + radius + 6.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)


func _get_boss_minigun_direction() -> Vector2:
	var duration: float = max(boss_minigun_duration, 0.12)
	var progress: float = clamp(_boss_minigun_elapsed / duration, 0.0, 1.0)
	var half_sweep := deg_to_rad(boss_minigun_sweep_degrees) * 0.5
	return _boss_minigun_base_direction.rotated(lerp(-half_sweep, half_sweep, progress)).normalized()


func _finish_boss_special() -> void:
	_boss_minigun_remaining = 0.0
	_boss_minigun_elapsed = 0.0
	_boss_minigun_next_shot_remaining = 0.0
	_boss_special_timer = boss_special_cooldown
	_boss_special_sequence_index += 1


func _get_boss_special_shot_config(special_kind: String) -> Dictionary:
	if special_kind == "rocket":
		return {
			"speed": max(projectile_speed * 2.5, 640.0),
			"damage": max(projectile_damage + 1, 2),
			"radius": max(projectile_radius * 1.65, 11.5),
			"kind": "rocket",
			"projectile_count": 1,
			"spread_angle_degrees": 0.0,
			"knockback": 540.0,
			"explosion_radius": 72.0,
			"explosion_damage_multiplier": 1.0
		}
	return {
		"speed": projectile_speed * 1.38,
		"damage": projectile_damage,
		"radius": max(projectile_radius * 0.72, 4.8),
		"kind": "hostile_minigun",
		"projectile_count": 1,
		"spread_angle_degrees": 0.0,
		"lifetime": 1.55,
		"knockback": 0.0
	}


func _get_chaser_velocity(to_target: Vector2) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	var steering_target := _get_path_steering_target(target_position)
	var to_steering := steering_target - global_position
	if to_steering.length_squared() <= 4.0:
		return Vector2.ZERO
	return to_steering.normalized() * speed


func _get_ranged_velocity(to_target: Vector2) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	var steering_target := _get_path_steering_target(target_position)
	if steering_target.distance_squared_to(target_position) > 1.0:
		var to_steering := steering_target - global_position
		if to_steering.length_squared() > 4.0:
			return to_steering.normalized() * speed
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
	var shot_origin := global_position + shot_direction * (body_radius + projectile_radius + 4.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return
	var shot_config := {
		"speed": projectile_speed,
		"damage": projectile_damage,
		"radius": projectile_radius,
		"kind": "hostile",
		"projectile_count": max(shot_projectile_count, 1),
		"spread_angle_degrees": shot_spread_degrees
	}
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)
	_shot_cooldown_remaining = shot_cooldown


func _update_projectile_shield(delta: float) -> void:
	var had_visual := _projectile_shield_remaining > 0.0 or _projectile_shield_block_flash_remaining > 0.0
	if _projectile_shield_remaining > 0.0:
		_projectile_shield_remaining = max(_projectile_shield_remaining - delta, 0.0)
	if _projectile_shield_block_flash_remaining > 0.0:
		_projectile_shield_block_flash_remaining = max(_projectile_shield_block_flash_remaining - delta, 0.0)
	if had_visual or _projectile_shield_remaining > 0.0 or _projectile_shield_block_flash_remaining > 0.0:
		queue_redraw()


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


func _wall_blocks_segment(from_position: Vector2, to_position: Vector2) -> bool:
	for wall_rect in wall_rects:
		if _segment_intersects_rect(from_position, to_position, wall_rect.grow(max(projectile_radius, 2.0))):
			return true
	if not is_inside_tree() or from_position.distance_squared_to(to_position) <= 0.001:
		return false
	var world := get_world_2d()
	if world == null:
		return false
	var query := PhysicsRayQueryParameters2D.create(from_position, to_position, 32, [get_rid()])
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := world.direct_space_state.intersect_ray(query)
	return not result.is_empty()


func _get_path_steering_target(final_target: Vector2) -> Vector2:
	var clearance: float = body_radius + 10.0
	if _can_reuse_path_cache(final_target):
		return _cached_steering_target
	var blocking_wall := _get_blocking_wall_rect(global_position, final_target, clearance)
	if blocking_wall.size == Vector2.ZERO:
		_store_path_cache(final_target, final_target)
		return final_target
	var expanded_wall := blocking_wall.grow(body_radius + 28.0)
	var candidates := [
		expanded_wall.position,
		expanded_wall.position + Vector2(expanded_wall.size.x, 0.0),
		expanded_wall.position + expanded_wall.size,
		expanded_wall.position + Vector2(0.0, expanded_wall.size.y)
	]
	var best_target := final_target
	var best_score: float = INF
	for candidate in candidates:
		if not ArenaGeometry.contains_point(candidate, arena_bounds, arena_shape):
			continue
		if _point_inside_wall(candidate, body_radius * 0.75):
			continue
		var score: float = global_position.distance_to(candidate) + candidate.distance_to(final_target)
		if _path_blocks_segment(global_position, candidate, body_radius * 0.35):
			score += 12000.0
		if _path_blocks_segment(candidate, final_target, body_radius * 0.35):
			score += 2400.0
		if score < best_score:
			best_score = score
			best_target = candidate
	_store_path_cache(final_target, best_target)
	return best_target


func _can_reuse_path_cache(final_target: Vector2) -> bool:
	if _cached_steering_target == Vector2.INF or _path_repath_remaining <= 0.0:
		return false
	if final_target.distance_squared_to(_path_cache_target_position) > PATH_CACHE_TARGET_MOVE_SQUARED:
		return false
	if global_position.distance_squared_to(_path_cache_enemy_position) > PATH_CACHE_SELF_MOVE_SQUARED:
		return false
	return true


func _store_path_cache(final_target: Vector2, steering_target: Vector2) -> void:
	_cached_steering_target = steering_target
	_path_cache_target_position = final_target
	_path_cache_enemy_position = global_position
	_path_repath_remaining = _path_repath_interval


func _get_blocking_wall_rect(from_position: Vector2, to_position: Vector2, margin: float) -> Rect2:
	var best_rect := Rect2()
	var best_distance := INF
	for blocker_rect in _path_blocker_rects:
		var expanded_blocker := blocker_rect.grow(margin)
		if not _segment_intersects_rect(from_position, to_position, expanded_blocker):
			continue
		var distance := from_position.distance_squared_to(expanded_blocker.get_center())
		if distance < best_distance:
			best_distance = distance
			best_rect = blocker_rect
	return best_rect


func _path_blocks_segment(from_position: Vector2, to_position: Vector2, margin: float) -> bool:
	if from_position.distance_squared_to(to_position) <= 0.001:
		return false
	for blocker_rect in _path_blocker_rects:
		if _segment_intersects_rect(from_position, to_position, blocker_rect.grow(margin)):
			return true
	return false


func _point_inside_wall(point: Vector2, margin: float) -> bool:
	for blocker_rect in _path_blocker_rects:
		if blocker_rect.grow(margin).has_point(point):
			return true
	return false


func _get_path_blocker_rects() -> Array[Rect2]:
	return _path_blocker_rects


func _segment_intersects_rect(from_position: Vector2, to_position: Vector2, rect: Rect2) -> bool:
	var min_x: float = min(from_position.x, to_position.x)
	var max_x: float = max(from_position.x, to_position.x)
	var min_y: float = min(from_position.y, to_position.y)
	var max_y: float = max(from_position.y, to_position.y)
	if rect.position.x > max_x or rect.position.x + rect.size.x < min_x or rect.position.y > max_y or rect.position.y + rect.size.y < min_y:
		return false
	if rect.has_point(from_position) or rect.has_point(to_position):
		return true
	var top_left := rect.position
	var top_right := rect.position + Vector2(rect.size.x, 0.0)
	var bottom_right := rect.position + rect.size
	var bottom_left := rect.position + Vector2(0.0, rect.size.y)
	if _segments_intersect(from_position, to_position, top_left, top_right):
		return true
	if _segments_intersect(from_position, to_position, top_right, bottom_right):
		return true
	if _segments_intersect(from_position, to_position, bottom_right, bottom_left):
		return true
	if _segments_intersect(from_position, to_position, bottom_left, top_left):
		return true
	return false


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var r := b - a
	var s := d - c
	var denominator := r.cross(s)
	var c_to_a := c - a
	if abs(denominator) <= 0.001:
		if abs(c_to_a.cross(r)) > 0.001:
			return false
		var use_x: bool = abs(r.x) >= abs(r.y)
		var a0: float = a.x if use_x else a.y
		var b0: float = b.x if use_x else b.y
		var c0: float = c.x if use_x else c.y
		var d0: float = d.x if use_x else d.y
		return max(min(a0, b0), min(c0, d0)) <= min(max(a0, b0), max(c0, d0))
	var t := c_to_a.cross(s) / denominator
	var u := c_to_a.cross(r) / denominator
	return t >= 0.0 and t <= 1.0 and u >= 0.0 and u <= 1.0
