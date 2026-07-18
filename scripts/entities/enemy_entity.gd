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
const AGENT_BODY_TEXTURE := preload("res://art/characters/player_body.svg")
const AGENT_BODY_BACK_TEXTURE := preload("res://art/characters/player_body_back.svg")
const AGENT_BODY_SIDE_TEXTURE := preload("res://art/characters/player_body_side.svg")
const AGENT_ARMS_GUN_TEXTURE := preload("res://art/characters/player_arms_gun.svg")
const AGENT_ARMS_GUN_LEFT_TEXTURE := preload("res://art/characters/player_arms_gun_left.svg")
const AGENT_RESTING_PISTOL_TEXTURE := preload("res://art/characters/player_resting_pistol.svg")
const AGENT_RESTING_PISTOL_LEFT_TEXTURE := preload("res://art/characters/player_resting_pistol_left.svg")
const PATH_REPATH_BASE_SECONDS := 0.1
const PATH_REPATH_STAGGER_SECONDS := 0.015
const PATH_CACHE_TARGET_MOVE_SQUARED := 48.0 * 48.0
const PATH_CACHE_SELF_MOVE_SQUARED := 36.0 * 36.0
const AGENT_ACTION_SLOW := "slow_pressure"
const AGENT_ACTION_NORMAL := "normal"
const AGENT_ACTION_SPECIAL := "special"
const AGENT_SPECIAL_STAGE_MOVE := "move"
const AGENT_SPECIAL_STAGE_TELEGRAPH := "telegraph"
const AGENT_SPECIAL_STAGE_STREAM := "stream"

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
@export var agent_program: AgentBossProgram = null

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
var _agent_rng := RandomNumberGenerator.new()
var _agent_action_kind: String = ""
var _agent_action_remaining: float = 0.0
var _agent_next_shot_remaining: float = 0.0
var _agent_action_direction: Vector2 = Vector2.RIGHT
var _agent_tactical_target: Vector2 = Vector2.INF
var _agent_zigzag_sign: float = 1.0
var _agent_special_stage: String = ""
var _agent_special_telegraph_remaining: float = 0.0
var _agent_special_telegraph_duration: float = 0.58
var _agent_dash_target: Vector2 = Vector2.ZERO
var _agent_dash_steps_remaining: int = 0
var _agent_charge_direction: Vector2 = Vector2.RIGHT
var _agent_charge_remaining: float = 0.0
var _agent_charge_elapsed: float = 0.0
var _agent_charge_special_fired: bool = false
var _agent_stream_kind: String = ""
var _agent_stream_remaining: float = 0.0
var _agent_stream_elapsed: float = 0.0
var _agent_stream_next_shot_remaining: float = 0.0
var _agent_stream_base_direction: Vector2 = Vector2.RIGHT
var _agent_stream_wave_index: int = 0
var _agent_walk_cycle: float = 0.0
var _agent_shoot_pose_remaining: float = 0.0
var _agent_aim_direction: Vector2 = Vector2.RIGHT
var _agent_last_move_facing_direction: Vector2 = Vector2.DOWN


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
	agent_program = profile.agent_program as AgentBossProgram if profile.get("agent_program") != null else null
	_visual_kind = _get_visual_kind(profile)
	health = max_health
	_shot_cooldown_remaining = shot_cooldown * 0.65
	if behavior_kind == "boss":
		_boss_special_timer = boss_special_cooldown * 0.55
		_boss_special_sequence_index = 0
	if _is_agent_boss():
		_configure_agent_boss_state()


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
	var intent_velocity := Vector2.ZERO
	if _is_agent_boss():
		intent_velocity = _update_agent_boss(delta, to_target)
	else:
		intent_velocity = _get_ranged_velocity(to_target) if behavior_kind == "shooter" or behavior_kind == "boss" else _get_chaser_velocity(to_target)
		var special_active := _update_boss_special(delta, to_target)
		if not special_active:
			_try_emit_shot(to_target)
		elif _boss_minigun_remaining > 0.0:
			intent_velocity = Vector2.ZERO
		else:
			intent_velocity *= 0.38
	velocity = intent_velocity + _knockback_velocity + _crowd_separation_velocity
	_update_agent_visual_state(delta, velocity)
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
	if _is_agent_boss():
		_draw_agent_character_art(draw_color)
	else:
		_draw_enemy_character_art(draw_color)
	if is_projectile_shield_active() or _projectile_shield_block_flash_remaining > 0.0:
		_draw_projectile_shield()
	if _is_agent_boss() and (_agent_special_telegraph_remaining > 0.0 or _agent_charge_remaining > 0.0):
		_draw_agent_special_telegraph()
	elif _boss_special_telegraph_remaining > 0.0:
		_draw_boss_special_telegraph()
	if _is_agent_boss() and _agent_stream_remaining > 0.0:
		_draw_agent_special_stream()
	elif _boss_minigun_remaining > 0.0:
		_draw_boss_minigun_sweep()
	draw_line(Vector2(-body_radius, -body_radius - 8.0), Vector2(-body_radius + body_radius * 2.0 * health_ratio, -body_radius - 8.0), Color(0.4, 1.0, 0.35, birth_alpha), 3.0)
	if behavior_kind == "shooter" or (behavior_kind == "boss" and not _is_agent_boss()):
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


func _draw_agent_character_art(tint: Color) -> void:
	_draw_agent_walk_feet(tint.a)
	var body_tint: Color = _get_agent_body_tint(tint)
	var visual_radius: float = body_radius * 2.35
	var facing: Vector2 = _get_agent_visual_facing_direction()
	var weapon_aim: Vector2 = _agent_aim_direction.normalized()
	if weapon_aim.length_squared() <= 0.001:
		weapon_aim = facing
	var weapon_texture: Texture2D = AGENT_ARMS_GUN_TEXTURE
	var resting_texture: Texture2D = AGENT_RESTING_PISTOL_TEXTURE
	var body_texture: Texture2D = AGENT_BODY_TEXTURE
	var body_scale: Vector2 = Vector2.ONE
	var is_side_facing: bool = abs(facing.x) >= abs(facing.y)
	var is_back_facing: bool = not is_side_facing and facing.y < 0.0
	var is_shooting := _agent_shoot_pose_remaining > 0.0 or _agent_special_telegraph_remaining > 0.0 or _agent_stream_remaining > 0.0
	var weapon_rotation := weapon_aim.angle()
	var resting_rotation: float = _get_agent_side_resting_pistol_rotation(facing)
	if is_side_facing:
		body_texture = AGENT_BODY_SIDE_TEXTURE
		body_scale = Vector2(-1.0, 1.0) if facing.x < 0.0 else Vector2.ONE
	elif is_back_facing:
		body_texture = AGENT_BODY_BACK_TEXTURE
	if facing.x < -0.001:
		resting_texture = AGENT_RESTING_PISTOL_LEFT_TEXTURE
		resting_rotation = -resting_rotation
	if weapon_aim.x < -0.001:
		weapon_texture = AGENT_ARMS_GUN_LEFT_TEXTURE
		weapon_rotation = (-weapon_aim).angle()
	if is_back_facing:
		if is_shooting:
			_draw_agent_centered_texture(resting_texture, visual_radius, resting_rotation, body_tint)
			_draw_agent_centered_texture(weapon_texture, visual_radius, weapon_rotation, body_tint)
		else:
			_draw_agent_vertical_resting_pistols(visual_radius, facing, body_tint)
		_draw_agent_centered_texture(body_texture, visual_radius, 0.0, body_tint, body_scale)
	else:
		_draw_agent_centered_texture(body_texture, visual_radius, 0.0, body_tint, body_scale)
		if is_shooting or is_side_facing:
			_draw_agent_centered_texture(resting_texture, visual_radius, resting_rotation, body_tint)
		else:
			_draw_agent_vertical_resting_pistols(visual_radius, facing, body_tint)
		if is_shooting:
			_draw_agent_centered_texture(weapon_texture, visual_radius, weapon_rotation, body_tint)
	var accent: Color = _get_agent_accent_color(tint.a)
	draw_arc(Vector2.ZERO, body_radius + 8.0, 0.0, TAU, 42, accent, 3.2)


func _get_agent_body_tint(base_tint: Color) -> Color:
	if _hit_flash_remaining > 0.0:
		return Color(1.0, 0.96, 0.74, base_tint.a)
	if agent_program != null:
		var color: Color = agent_program.body_modulate
		return Color(color.r, color.g, color.b, base_tint.a)
	return base_tint


func _get_agent_accent_color(alpha: float = 1.0) -> Color:
	if agent_program == null:
		return Color(accent_color.r, accent_color.g, accent_color.b, alpha)
	var color: Color = agent_program.accent_color
	return Color(color.r, color.g, color.b, alpha)


func _get_agent_shadow_color(alpha: float = 1.0) -> Color:
	if agent_program == null:
		return Color(0.05, 0.04, 0.08, alpha)
	var color: Color = agent_program.shadow_color
	return Color(color.r, color.g, color.b, alpha)


func _get_agent_visual_facing_direction() -> Vector2:
	if (_agent_shoot_pose_remaining > 0.0 or _agent_special_telegraph_remaining > 0.0 or _agent_stream_remaining > 0.0) and _agent_aim_direction.length_squared() > 0.001:
		return _agent_aim_direction.normalized()
	if velocity.length_squared() > 1.0:
		return velocity.normalized()
	if _agent_last_move_facing_direction.length_squared() > 0.001:
		return _agent_last_move_facing_direction.normalized()
	return Vector2.DOWN


func _get_agent_side_resting_pistol_rotation(facing: Vector2) -> float:
	var is_walking := velocity.length_squared() > 1.0
	var base_tilt: float = clamp(facing.y * (0.16 if is_walking else 0.08), -0.16, 0.16)
	if is_walking:
		base_tilt += sin(_agent_walk_cycle) * 0.028
	return base_tilt


func _draw_agent_vertical_resting_pistols(visual_radius: float, facing: Vector2, tint: Color) -> void:
	var is_walking := velocity.length_squared() > 1.0
	var forward_tilt: float = clamp(facing.y * 0.08, -0.08, 0.08)
	var walk_swing: float = sin(_agent_walk_cycle) * 0.052 if is_walking else 0.018
	_draw_agent_centered_texture(AGENT_RESTING_PISTOL_TEXTURE, visual_radius, forward_tilt + walk_swing, tint)
	_draw_agent_centered_texture(AGENT_RESTING_PISTOL_LEFT_TEXTURE, visual_radius, -forward_tilt + walk_swing, tint)


func _draw_agent_walk_feet(alpha: float) -> void:
	var is_walking := velocity.length_squared() > 1.0
	var stride_direction := velocity.normalized() if is_walking else Vector2.RIGHT
	if stride_direction.length_squared() <= 0.001:
		stride_direction = Vector2.RIGHT
	var foot_anchor := Vector2.DOWN * body_radius * 1.04
	var side := Vector2.RIGHT
	var stride: float = sin(_agent_walk_cycle) * body_radius * 0.2 if is_walking else 0.0
	var lift: float = abs(sin(_agent_walk_cycle)) * 0.2 if is_walking else 0.0
	var left_center: Vector2 = foot_anchor - side * body_radius * 0.38 + stride_direction * stride
	var right_center: Vector2 = foot_anchor + side * body_radius * 0.38 - stride_direction * stride
	var left_scale := Vector2(body_radius * 0.32, body_radius * (0.62 + lift))
	var right_scale := Vector2(body_radius * 0.32, body_radius * (0.62 + (0.2 - lift if is_walking else 0.0)))
	_draw_agent_oval(left_center + Vector2.DOWN * body_radius * 0.04, 0.0, left_scale, _get_agent_shadow_color(alpha))
	_draw_agent_oval(right_center + Vector2.DOWN * body_radius * 0.04, 0.0, right_scale, _get_agent_shadow_color(alpha))
	_draw_agent_oval(left_center - Vector2.DOWN * body_radius * 0.08, 0.0, left_scale * Vector2(0.62, 0.56), _get_agent_accent_color(alpha * 0.72))
	_draw_agent_oval(right_center - Vector2.DOWN * body_radius * 0.08, 0.0, right_scale * Vector2(0.62, 0.56), _get_agent_accent_color(alpha * 0.72))


func _draw_agent_centered_texture(texture: Texture2D, visual_radius: float, rotation: float, tint: Color, scale: Vector2 = Vector2.ONE) -> void:
	if texture == null:
		return
	draw_set_transform(Vector2.ZERO, rotation, scale)
	draw_texture_rect(texture, Rect2(Vector2(-visual_radius, -visual_radius), Vector2(visual_radius * 2.0, visual_radius * 2.0)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_agent_oval(center: Vector2, rotation: float, scale: Vector2, color: Color) -> void:
	draw_set_transform(center, rotation, scale)
	draw_circle(Vector2.ZERO, 1.0, color)
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


func _draw_agent_special_telegraph() -> void:
	var duration: float = max(_agent_special_telegraph_duration, 0.001)
	var remaining: float = _agent_special_telegraph_remaining
	if _agent_charge_remaining > 0.0:
		remaining = max(float(agent_program.charge_windup_seconds) - _agent_charge_elapsed, 0.0) if agent_program != null else remaining
	var progress: float = 1.0 - clamp(remaining / duration, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.045)
	var aim: Vector2 = _agent_aim_direction.normalized()
	if aim.length_squared() <= 0.001:
		aim = (target_position - global_position).normalized()
	if aim.length_squared() <= 0.001:
		aim = Vector2.RIGHT
	var telegraph_color: Color = _get_agent_accent_color(0.78)
	var radius: float = body_radius + 14.0 + progress * 16.0 + pulse * 4.0
	draw_circle(Vector2.ZERO, radius, Color(telegraph_color.r, telegraph_color.g, telegraph_color.b, 0.1 + pulse * 0.08))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 52, telegraph_color, 5.0)
	match _get_agent_special_attack_verb():
		AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE:
			var half_sweep: float = deg_to_rad(float(agent_program.minigun_sweep_degrees)) * 0.5 if agent_program != null else PI * 0.42
			draw_line(Vector2.ZERO, aim.rotated(-half_sweep) * (body_radius + 82.0), Color(1.0, 0.96, 0.58, 0.72), 3.5)
			draw_line(Vector2.ZERO, aim.rotated(half_sweep) * (body_radius + 82.0), Color(0.54, 1.0, 1.0, 0.48), 3.5)
		AgentBossProgram.SPECIAL_ATTACK_SPIRAL_CLOCKWISE, AgentBossProgram.SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE:
			draw_arc(Vector2.ZERO, body_radius + 34.0 + pulse * 4.0, progress * TAU, progress * TAU + TAU * 0.78, 56, Color(1.0, 0.9, 0.32, 0.82), 4.0)
			draw_arc(Vector2.ZERO, body_radius + 50.0 + pulse * 4.0, -progress * TAU, -progress * TAU + TAU * 0.58, 56, Color(0.46, 1.0, 1.0, 0.68), 3.0)
		AgentBossProgram.SPECIAL_ATTACK_RING_PULSE:
			for index in range(3):
				var ring_radius: float = body_radius + 30.0 + float(index) * 15.0 + pulse * 3.0
				draw_arc(Vector2.ZERO, ring_radius, progress * TAU + float(index) * 0.24, progress * TAU + float(index) * 0.24 + TAU * 0.72, 64, Color(1.0, 0.86, 0.3, 0.72 - float(index) * 0.12), 3.2)
		AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST:
			for index in range(6):
				var spoke: Vector2 = aim.rotated(TAU * float(index) / 6.0 + progress * TAU)
				draw_line(Vector2.ZERO, spoke * (body_radius + 76.0), Color(0.48, 1.0, 1.0, 0.54), 2.8)
		AgentBossProgram.SPECIAL_ATTACK_ROCKET:
			draw_line(Vector2.ZERO, aim * (body_radius + 96.0), Color(1.0, 0.42, 0.18, 0.86), 5.0)
			draw_arc(aim * (body_radius + 78.0), 14.0 + pulse * 6.0, 0.0, TAU, 28, Color(1.0, 0.8, 0.28, 0.8), 3.0)
		_:
			draw_line(Vector2.ZERO, aim * (body_radius + 76.0), Color(1.0, 0.98, 0.64, 0.74), 4.0)


func _draw_agent_special_stream() -> void:
	var direction: Vector2 = _get_agent_stream_direction()
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.075)
	if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE:
		var side: Vector2 = direction.orthogonal()
		draw_line(side * -body_radius * 0.82, direction * (body_radius + 92.0), Color(1.0, 0.96, 0.42, 0.7 + pulse * 0.18), 4.0)
		draw_line(side * body_radius * 0.82, direction * (body_radius + 76.0), Color(0.45, 1.0, 1.0, 0.42 + pulse * 0.12), 3.0)
	elif _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_RING_PULSE:
		for index in range(3):
			draw_arc(Vector2.ZERO, body_radius + 28.0 + float(index) * 16.0 + pulse * 3.0, direction.angle() + float(index) * 0.3, direction.angle() + float(index) * 0.3 + TAU * 0.82, 54, Color(1.0, 0.86, 0.28, 0.56), 3.0)
	elif _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST:
		for index in range(6):
			var spoke: Vector2 = direction.rotated(TAU * float(index) / 6.0)
			draw_line(Vector2.ZERO, spoke * (body_radius + 84.0), Color(0.45, 1.0, 1.0, 0.52 + pulse * 0.16), 3.0)
	else:
		var radius: float = body_radius + 36.0 + pulse * 4.0
		draw_arc(Vector2.ZERO, radius, direction.angle(), direction.angle() + PI * 1.15, 42, Color(1.0, 0.9, 0.3, 0.72), 4.0)
		draw_arc(Vector2.ZERO, radius + 12.0, direction.angle() - PI * 0.7, direction.angle() + PI * 0.25, 36, Color(0.44, 1.0, 1.0, 0.52), 3.0)
	draw_circle(direction * (body_radius + 33.0), 4.5 + pulse * 2.0, Color(1.0, 0.82, 0.16, 0.74))


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


func _is_agent_boss() -> bool:
	return behavior_kind == "boss" and agent_program != null


func _configure_agent_boss_state() -> void:
	var seed: int = int(agent_program.generation_seed) if agent_program != null and agent_program.get("generation_seed") != null else int(get_instance_id())
	_agent_rng.seed = max(seed, 1)
	_agent_action_kind = ""
	_agent_action_remaining = 0.0
	_agent_next_shot_remaining = 0.0
	_agent_tactical_target = Vector2.INF
	_agent_special_stage = ""
	_agent_special_telegraph_remaining = 0.0
	_agent_stream_remaining = 0.0
	_agent_stream_elapsed = 0.0
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0
	_agent_charge_remaining = 0.0
	_agent_charge_elapsed = 0.0
	_agent_charge_special_fired = false
	_agent_zigzag_sign = -1.0 if _agent_rng.randf() < 0.5 else 1.0
	_agent_last_move_facing_direction = Vector2.DOWN
	_agent_aim_direction = Vector2.RIGHT


func _update_agent_boss(delta: float, to_target: Vector2) -> Vector2:
	if agent_program == null or health <= 0 or _is_dying:
		return Vector2.ZERO
	if _agent_shoot_pose_remaining > 0.0:
		_agent_shoot_pose_remaining = max(_agent_shoot_pose_remaining - delta, 0.0)
	if _agent_stream_remaining > 0.0:
		_update_agent_special_stream(delta)
		return Vector2.ZERO
	if _agent_special_stage == AGENT_SPECIAL_STAGE_TELEGRAPH:
		_agent_special_telegraph_remaining = max(_agent_special_telegraph_remaining - delta, 0.0)
		_agent_aim_at_target(to_target)
		if _agent_special_telegraph_remaining <= 0.0:
			_emit_agent_special_attack(to_target)
			if _agent_stream_remaining <= 0.0:
				_finish_agent_action()
		queue_redraw()
		return Vector2.ZERO
	if _agent_charge_remaining > 0.0:
		return _update_agent_charge(delta, to_target)
	if _agent_special_stage == AGENT_SPECIAL_STAGE_MOVE and _get_agent_special_movement_verb() == AgentBossProgram.SPECIAL_MOVEMENT_DASH_CHAIN:
		return _update_agent_dash_chain(delta, to_target)
	if _agent_action_remaining <= 0.0 or _agent_action_kind.is_empty():
		_start_next_agent_action(to_target)
	_agent_action_remaining = max(_agent_action_remaining - delta, 0.0)
	if _agent_next_shot_remaining > 0.0:
		_agent_next_shot_remaining = max(_agent_next_shot_remaining - delta, 0.0)
	match _agent_action_kind:
		AGENT_ACTION_SLOW:
			_try_emit_agent_standard_shot(to_target, float(agent_program.slow_shot_cooldown), float(agent_program.slow_projectile_speed), projectile_damage, float(agent_program.slow_projectile_radius))
			return _get_agent_slow_velocity(to_target)
		AGENT_ACTION_NORMAL:
			_try_emit_agent_standard_shot(to_target, float(agent_program.normal_shot_cooldown), float(agent_program.normal_projectile_speed), projectile_damage, float(agent_program.normal_projectile_radius))
			return _get_agent_normal_velocity(to_target)
		AGENT_ACTION_SPECIAL:
			return _update_agent_special_movement(delta, to_target)
	return Vector2.ZERO


func _start_next_agent_action(to_target: Vector2) -> void:
	var total_weight: float = float(agent_program.get_total_action_weight()) if agent_program != null and agent_program.has_method("get_total_action_weight") else 1.0
	if total_weight <= 0.0:
		_agent_action_kind = AGENT_ACTION_NORMAL
	else:
		var roll := _agent_rng.randf() * total_weight
		if roll < max(float(agent_program.slow_action_weight), 0.0):
			_agent_action_kind = AGENT_ACTION_SLOW
		elif roll < max(float(agent_program.slow_action_weight), 0.0) + max(float(agent_program.normal_action_weight), 0.0):
			_agent_action_kind = AGENT_ACTION_NORMAL
		else:
			_agent_action_kind = AGENT_ACTION_SPECIAL
	_agent_tactical_target = Vector2.INF
	_agent_special_stage = ""
	_agent_action_direction = _pick_agent_valid_direction(_get_target_direction(to_target), float(agent_program.normal_tactical_distance))
	match _agent_action_kind:
		AGENT_ACTION_SLOW:
			_agent_action_remaining = max(float(agent_program.slow_action_seconds), 0.2)
			_agent_action_direction = _pick_agent_valid_direction(Vector2.RIGHT.rotated(_agent_rng.randf() * TAU), float(agent_program.normal_tactical_distance) * 0.55)
			_agent_next_shot_remaining = min(_agent_next_shot_remaining, 0.08)
		AGENT_ACTION_NORMAL:
			_agent_action_remaining = max(float(agent_program.normal_action_seconds), 0.25)
			_agent_zigzag_sign *= -1.0
			_agent_next_shot_remaining = min(_agent_next_shot_remaining, 0.18)
		AGENT_ACTION_SPECIAL:
			_agent_action_remaining = 5.0
			_start_agent_special_movement(to_target)
	queue_redraw()


func _finish_agent_action() -> void:
	_agent_action_kind = ""
	_agent_action_remaining = 0.0
	_agent_tactical_target = Vector2.INF
	_agent_special_stage = ""
	_agent_special_telegraph_remaining = 0.0
	_agent_dash_steps_remaining = 0
	_agent_charge_remaining = 0.0
	_agent_charge_elapsed = 0.0
	_agent_charge_special_fired = false
	_agent_stream_kind = ""
	_agent_stream_remaining = 0.0
	_agent_stream_elapsed = 0.0
	_agent_stream_next_shot_remaining = 0.0


func _get_agent_slow_velocity(to_target: Vector2) -> Vector2:
	var speed_value: float = max(float(agent_program.slow_move_speed), 0.0)
	if _agent_action_direction.length_squared() <= 0.001:
		_agent_action_direction = _pick_agent_valid_direction(Vector2.RIGHT.rotated(_agent_rng.randf() * TAU), 120.0)
	return _agent_action_direction.normalized() * speed_value


func _get_agent_normal_velocity(to_target: Vector2) -> Vector2:
	var target_direction: Vector2 = _get_target_direction(to_target)
	var speed_value: float = max(float(agent_program.normal_move_speed), 0.0)
	match _get_agent_normal_movement_verb():
		AgentBossProgram.NORMAL_PUSH_FORWARD:
			return _get_agent_path_velocity_for_direction(target_direction, float(agent_program.normal_tactical_distance), speed_value)
		AgentBossProgram.NORMAL_PULL_BACK:
			return _get_agent_path_velocity_for_direction(-target_direction, float(agent_program.normal_tactical_distance), speed_value)
		AgentBossProgram.NORMAL_ZIG_ZAG:
			var zig_direction: Vector2 = (target_direction + target_direction.orthogonal() * _agent_zigzag_sign * 0.9).normalized()
			return _get_agent_path_velocity_for_direction(zig_direction, float(agent_program.normal_tactical_distance), speed_value)
		_:
			var strafe_direction: Vector2 = target_direction.orthogonal() * _strafe_sign
			return _get_agent_path_velocity_for_direction(strafe_direction, float(agent_program.normal_tactical_distance), speed_value)


func _get_agent_path_velocity_for_direction(preferred_direction: Vector2, distance: float, speed_value: float) -> Vector2:
	if preferred_direction.length_squared() <= 0.001 or speed_value <= 0.0:
		return Vector2.ZERO
	if _agent_tactical_target == Vector2.INF or global_position.distance_squared_to(_agent_tactical_target) <= 36.0 * 36.0 or _path_blocks_segment(global_position, _agent_tactical_target, body_radius * 0.55):
		_agent_tactical_target = _pick_agent_tactical_target(preferred_direction.normalized(), max(distance, 48.0))
	if _agent_tactical_target == Vector2.INF:
		return Vector2.ZERO
	var steering_target: Vector2 = _get_path_steering_target(_agent_tactical_target)
	var to_steering: Vector2 = steering_target - global_position
	if to_steering.length_squared() <= 4.0:
		return Vector2.ZERO
	return to_steering.normalized() * speed_value


func _pick_agent_tactical_target(preferred_direction: Vector2, distance: float) -> Vector2:
	var directions: Array[Vector2] = [
		preferred_direction,
		preferred_direction.rotated(PI * 0.22),
		preferred_direction.rotated(-PI * 0.22),
		preferred_direction.rotated(PI * 0.5),
		preferred_direction.rotated(-PI * 0.5),
		preferred_direction.rotated(PI * 0.75),
		preferred_direction.rotated(-PI * 0.75)
	]
	for direction in directions:
		var candidate: Vector2 = global_position + direction.normalized() * distance
		if _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.55):
			return candidate
	for direction in directions:
		var candidate: Vector2 = global_position + direction.normalized() * distance * 0.55
		if _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.55):
			return candidate
	return Vector2.INF


func _pick_agent_valid_direction(preferred_direction: Vector2, distance: float) -> Vector2:
	var target: Vector2 = _pick_agent_tactical_target(preferred_direction.normalized() if preferred_direction.length_squared() > 0.001 else Vector2.RIGHT, distance)
	if target == Vector2.INF:
		return Vector2.ZERO
	return (target - global_position).normalized()


func _agent_point_is_valid(point: Vector2) -> bool:
	if not ArenaGeometry.contains_point(point, arena_bounds, arena_shape):
		return false
	if _point_inside_wall(point, body_radius * 0.85):
		return false
	return true


func _start_agent_special_movement(to_target: Vector2) -> void:
	_agent_special_stage = AGENT_SPECIAL_STAGE_MOVE
	_agent_dash_steps_remaining = max(int(agent_program.dash_count), 1)
	match _get_agent_special_movement_verb():
		AgentBossProgram.SPECIAL_MOVEMENT_TELEPORT_LOS:
			var teleport_target: Vector2 = _pick_agent_los_point(to_target)
			if teleport_target != Vector2.INF:
				global_position = _constrain_to_playable(teleport_target)
				_invalidate_path_cache()
			_start_agent_special_telegraph(to_target)
		AgentBossProgram.SPECIAL_MOVEMENT_CHARGE:
			_start_agent_charge(to_target)
		_:
			_agent_dash_target = _pick_agent_dash_target(to_target)
			if _agent_dash_target == Vector2.INF:
				_start_agent_special_telegraph(to_target)


func _update_agent_special_movement(_delta: float, to_target: Vector2) -> Vector2:
	if _agent_special_stage.is_empty():
		_start_agent_special_movement(to_target)
	return Vector2.ZERO


func _pick_agent_los_point(to_target: Vector2) -> Vector2:
	var preferred_distance: float = clamp(float(agent_program.special_move_distance), 180.0, 420.0)
	var directions: Array[Vector2] = _get_agent_special_move_directions(to_target)
	for direction in directions:
		var candidate: Vector2 = global_position + direction.normalized() * preferred_distance
		candidate = _adjust_agent_special_candidate_distance(candidate)
		candidate = _constrain_to_playable(candidate)
		if _agent_point_is_valid(candidate) and not _wall_blocks_segment(candidate, target_position):
			return candidate
	return Vector2.INF


func _pick_agent_dash_target(to_target: Vector2) -> Vector2:
	var distance: float = max(float(agent_program.special_move_distance), 140.0)
	var directions: Array[Vector2] = _get_agent_special_move_directions(to_target)
	for direction in directions:
		var candidate: Vector2 = global_position + direction.normalized() * distance
		if _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.65):
			return candidate
	return Vector2.INF


func _get_agent_special_move_directions(to_target: Vector2) -> Array[Vector2]:
	var target_direction: Vector2 = _get_target_direction(to_target)
	var side_direction: Vector2 = target_direction.orthogonal() * _agent_zigzag_sign
	match _get_agent_special_reposition_verb():
		AgentBossProgram.SPECIAL_REPOSITION_RETREAT:
			return [
				-target_direction,
				(-target_direction + side_direction * 0.6).normalized(),
				(-target_direction - side_direction * 0.6).normalized(),
				side_direction,
				-side_direction,
				target_direction
			]
		AgentBossProgram.SPECIAL_REPOSITION_STRAFE:
			return [
				side_direction,
				-side_direction,
				(side_direction - target_direction * 0.35).normalized(),
				(-side_direction - target_direction * 0.35).normalized(),
				-target_direction,
				target_direction
			]
		_:
			return [
				target_direction,
				(target_direction + side_direction * 0.6).normalized(),
				(target_direction - side_direction * 0.6).normalized(),
				side_direction,
				-side_direction,
				-target_direction
			]


func _adjust_agent_special_candidate_distance(candidate: Vector2) -> Vector2:
	var from_target: Vector2 = candidate - target_position
	var minimum_distance: float = max(body_radius * 6.0, 135.0)
	if from_target.length_squared() >= minimum_distance * minimum_distance:
		return candidate
	var direction: Vector2 = from_target.normalized()
	if direction.length_squared() <= 0.001:
		direction = -_get_target_direction(target_position - global_position)
	return target_position + direction * minimum_distance


func _pick_agent_special_charge_direction(to_target: Vector2, distance: float) -> Vector2:
	var directions: Array[Vector2] = _get_agent_special_move_directions(to_target)
	for direction in directions:
		if direction.length_squared() <= 0.001:
			continue
		var normalized_direction: Vector2 = direction.normalized()
		if not _path_blocks_segment(global_position, global_position + normalized_direction * distance, body_radius * 0.75):
			return normalized_direction
	return _get_target_direction(to_target)


func _update_agent_dash_chain(_delta: float, to_target: Vector2) -> Vector2:
	if _agent_dash_target == Vector2.INF:
		_start_agent_special_telegraph(to_target)
		return Vector2.ZERO
	var to_dash := _agent_dash_target - global_position
	if to_dash.length_squared() <= 22.0 * 22.0 or _path_blocks_segment(global_position, _agent_dash_target, body_radius * 0.55):
		_agent_dash_steps_remaining -= 1
		if _agent_dash_steps_remaining <= 0:
			_start_agent_special_telegraph(to_target)
			return Vector2.ZERO
		_agent_zigzag_sign *= -1.0
		_agent_dash_target = _pick_agent_dash_target(to_target)
		if _agent_dash_target == Vector2.INF:
			_start_agent_special_telegraph(to_target)
			return Vector2.ZERO
		to_dash = _agent_dash_target - global_position
	return to_dash.normalized() * max(float(agent_program.dash_speed), 120.0)


func _start_agent_charge(to_target: Vector2) -> void:
	var distance: float = max(float(agent_program.charge_speed) * float(agent_program.charge_seconds), 120.0)
	var charge_direction: Vector2 = _pick_agent_special_charge_direction(to_target, distance)
	if _path_blocks_segment(global_position, global_position + charge_direction * distance, body_radius * 0.75):
		var setup_target: Vector2 = _pick_agent_los_point(to_target)
		if setup_target != Vector2.INF:
			global_position = _constrain_to_playable(setup_target)
			charge_direction = _pick_agent_special_charge_direction(target_position - global_position, distance)
	_agent_charge_direction = charge_direction
	_agent_charge_remaining = max(float(agent_program.charge_windup_seconds) + float(agent_program.charge_seconds), 0.12)
	_agent_charge_elapsed = 0.0
	_agent_charge_special_fired = false
	_agent_special_telegraph_duration = max(float(agent_program.charge_windup_seconds), 0.08)
	_agent_special_telegraph_remaining = _agent_special_telegraph_duration


func _update_agent_charge(delta: float, to_target: Vector2) -> Vector2:
	_agent_charge_elapsed += delta
	_agent_charge_remaining = max(_agent_charge_remaining - delta, 0.0)
	_agent_aim_at_target(to_target)
	var windup: float = max(float(agent_program.charge_windup_seconds), 0.0)
	if _agent_charge_elapsed <= windup:
		_agent_special_telegraph_remaining = max(windup - _agent_charge_elapsed, 0.0)
		return Vector2.ZERO
	if not _agent_charge_special_fired:
		_emit_agent_special_attack(to_target)
		_agent_charge_special_fired = true
	if _path_blocks_segment(global_position, global_position + _agent_charge_direction * 42.0, body_radius * 0.65):
		_finish_agent_action()
		return Vector2.ZERO
	if _agent_charge_remaining <= 0.0:
		_finish_agent_action()
		return Vector2.ZERO
	return _agent_charge_direction.normalized() * max(float(agent_program.charge_speed), 100.0)


func _start_agent_special_telegraph(to_target: Vector2) -> void:
	_agent_special_stage = AGENT_SPECIAL_STAGE_TELEGRAPH
	_agent_special_telegraph_duration = max(float(agent_program.special_telegraph_seconds), 0.1)
	_agent_special_telegraph_remaining = _agent_special_telegraph_duration
	_agent_aim_at_target(to_target)
	activate_projectile_shield(_agent_special_telegraph_duration + 0.24)
	queue_redraw()


func _emit_agent_special_attack(to_target: Vector2) -> void:
	match _get_agent_special_attack_verb():
		AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE:
			_start_agent_minigun_stream(to_target)
		AgentBossProgram.SPECIAL_ATTACK_SPIRAL_CLOCKWISE, AgentBossProgram.SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE:
			_start_agent_spiral_stream(to_target)
		AgentBossProgram.SPECIAL_ATTACK_RING_PULSE:
			_start_agent_ring_pulse_stream(to_target)
		AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST:
			_start_agent_pinwheel_stream(to_target)
		_:
			_emit_agent_single_special_shot(to_target, _get_agent_special_attack_verb())


func _emit_agent_single_special_shot(to_target: Vector2, attack_verb: String) -> void:
	if to_target.length_squared() <= 4.0:
		return
	var shot_direction: Vector2 = to_target.normalized()
	var shot_config: Dictionary = _get_agent_special_shot_config(attack_verb)
	var radius: float = float(shot_config.get("radius", projectile_radius))
	var shot_origin: Vector2 = global_position + shot_direction * (body_radius + radius + 6.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	if attack_verb == AgentBossProgram.SPECIAL_ATTACK_ROCKET:
		var target_position_at_launch: Vector2 = target_position
		var target_direction: Vector2 = target_position_at_launch - shot_origin
		if target_direction.length_squared() > 4.0:
			shot_direction = target_direction.normalized()
		var rocket_speed: float = max(float(shot_config.get("speed", projectile_speed)), 1.0)
		shot_config["target_position"] = target_position_at_launch
		shot_config["lifetime"] = max(shot_origin.distance_to(target_position_at_launch) / rocket_speed, 0.08)
		shot_config["exact_lifetime"] = true
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)
	_play_agent_shoot_pose(shot_direction)


func _start_agent_minigun_stream(to_target: Vector2) -> void:
	if to_target.length_squared() <= 4.0:
		return
	_agent_stream_kind = AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE
	_agent_stream_base_direction = to_target.normalized()
	_agent_stream_elapsed = 0.0
	_agent_stream_remaining = max(float(agent_program.minigun_duration), 0.16)
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0
	_agent_special_stage = AGENT_SPECIAL_STAGE_STREAM


func _start_agent_spiral_stream(to_target: Vector2) -> void:
	_agent_stream_kind = _get_agent_special_attack_verb()
	_agent_stream_base_direction = _get_target_direction(to_target)
	_agent_stream_elapsed = 0.0
	_agent_stream_remaining = max(float(agent_program.spiral_duration), 0.2)
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0
	_agent_special_stage = AGENT_SPECIAL_STAGE_STREAM


func _start_agent_ring_pulse_stream(to_target: Vector2) -> void:
	_agent_stream_kind = AgentBossProgram.SPECIAL_ATTACK_RING_PULSE
	_agent_stream_base_direction = _get_target_direction(to_target)
	_agent_stream_elapsed = 0.0
	var wave_count: int = clampi(int(agent_program.pulse_wave_count), 1, 5)
	var interval: float = max(float(agent_program.pulse_wave_interval), 0.05)
	_agent_stream_remaining = max(interval * float(wave_count), interval)
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0
	_agent_special_stage = AGENT_SPECIAL_STAGE_STREAM


func _start_agent_pinwheel_stream(to_target: Vector2) -> void:
	_agent_stream_kind = AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST
	_agent_stream_base_direction = _get_target_direction(to_target)
	_agent_stream_elapsed = 0.0
	var wave_count: int = clampi(int(agent_program.pinwheel_wave_count), 2, 10)
	var interval: float = max(float(agent_program.pinwheel_wave_interval), 0.04)
	_agent_stream_remaining = max(interval * float(wave_count), interval)
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0
	_agent_special_stage = AGENT_SPECIAL_STAGE_STREAM


func _update_agent_special_stream(delta: float) -> void:
	_agent_stream_elapsed += delta
	_agent_stream_remaining = max(_agent_stream_remaining - delta, 0.0)
	_agent_stream_next_shot_remaining -= delta
	if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_RING_PULSE:
		_update_agent_ring_pulse_stream()
		return
	if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST:
		_update_agent_pinwheel_stream()
		return
	var interval: float = max(float(agent_program.minigun_shot_interval), 0.025)
	if _agent_stream_kind != AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE:
		interval = max(float(agent_program.spiral_shot_interval), 0.035)
	var emitted_count := 0
	while _agent_stream_remaining > 0.0 and _agent_stream_next_shot_remaining <= 0.0 and emitted_count < 8:
		var direction: Vector2 = _get_agent_stream_direction()
		var shot_config: Dictionary = _get_agent_special_shot_config(_agent_stream_kind)
		var radius: float = float(shot_config.get("radius", projectile_radius))
		var shot_origin: Vector2 = global_position + direction * (body_radius + radius + 6.0)
		if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
			shot_origin = global_position
		shot_ready.emit(self, shot_origin, direction, shot_config)
		_play_agent_shoot_pose(direction)
		_agent_stream_next_shot_remaining += interval
		emitted_count += 1
	if _agent_stream_remaining <= 0.0:
		_finish_agent_action()
	queue_redraw()


func _update_agent_ring_pulse_stream() -> void:
	var interval: float = max(float(agent_program.pulse_wave_interval), 0.05)
	var wave_count: int = clampi(int(agent_program.pulse_wave_count), 1, 5)
	var emitted_waves := 0
	while _agent_stream_next_shot_remaining <= 0.0 and _agent_stream_wave_index < wave_count and emitted_waves < wave_count:
		_emit_agent_ring_pulse_wave(_agent_stream_wave_index)
		_agent_stream_wave_index += 1
		_agent_stream_next_shot_remaining += interval
		emitted_waves += 1
	if _agent_stream_wave_index >= wave_count:
		_agent_stream_remaining = 0.0
	if _agent_stream_remaining <= 0.0:
		_finish_agent_action()
	queue_redraw()


func _update_agent_pinwheel_stream() -> void:
	var interval: float = max(float(agent_program.pinwheel_wave_interval), 0.04)
	var wave_count: int = clampi(int(agent_program.pinwheel_wave_count), 2, 10)
	var emitted_waves := 0
	while _agent_stream_next_shot_remaining <= 0.0 and _agent_stream_wave_index < wave_count and emitted_waves < wave_count:
		_emit_agent_pinwheel_wave(_agent_stream_wave_index)
		_agent_stream_wave_index += 1
		_agent_stream_next_shot_remaining += interval
		emitted_waves += 1
	if _agent_stream_wave_index >= wave_count:
		_agent_stream_remaining = 0.0
	if _agent_stream_remaining <= 0.0:
		_finish_agent_action()
	queue_redraw()


func _emit_agent_ring_pulse_wave(wave_index: int) -> void:
	var shot_count: int = clampi(int(agent_program.pulse_shots_per_wave), 8, 36)
	var step: float = TAU / float(shot_count)
	var base_angle: float = _agent_stream_base_direction.angle() + deg_to_rad(float(agent_program.pulse_wave_rotation_degrees)) * float(wave_index)
	if wave_index % 2 == 1:
		base_angle += step * 0.5
	var shot_config: Dictionary = _get_agent_special_shot_config(AgentBossProgram.SPECIAL_ATTACK_RING_PULSE)
	for shot_index in range(shot_count):
		var direction: Vector2 = Vector2.RIGHT.rotated(base_angle + step * float(shot_index)).normalized()
		_emit_agent_pattern_projectile(direction, shot_config)
	_play_agent_shoot_pose(_agent_stream_base_direction)


func _emit_agent_pinwheel_wave(wave_index: int) -> void:
	var spoke_count: int = clampi(int(agent_program.pinwheel_spoke_count), 3, 10)
	var step: float = TAU / float(spoke_count)
	var base_angle: float = _agent_stream_base_direction.angle() + deg_to_rad(float(agent_program.pinwheel_rotation_degrees)) * float(wave_index)
	var shot_config: Dictionary = _get_agent_special_shot_config(AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST)
	for spoke_index in range(spoke_count):
		var direction: Vector2 = Vector2.RIGHT.rotated(base_angle + step * float(spoke_index)).normalized()
		_emit_agent_pattern_projectile(direction, shot_config)
	_play_agent_shoot_pose(_agent_stream_base_direction)


func _emit_agent_pattern_projectile(direction: Vector2, shot_config: Dictionary) -> void:
	if direction.length_squared() <= 0.001:
		return
	var radius: float = float(shot_config.get("radius", projectile_radius))
	var shot_origin: Vector2 = global_position + direction * (body_radius + radius + 6.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	shot_ready.emit(self, shot_origin, direction, shot_config.duplicate())


func _get_agent_stream_direction() -> Vector2:
	if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE:
		var duration: float = max(float(agent_program.minigun_duration), 0.16)
		var progress: float = clamp(_agent_stream_elapsed / duration, 0.0, 1.0)
		var start_angle: float = deg_to_rad(float(agent_program.minigun_sweep_degrees)) * 0.5 * float(sign(int(agent_program.minigun_start_side)))
		var phase: float = progress * 2.0
		var angle: float = lerp(start_angle, -start_angle, phase) if phase <= 1.0 else lerp(-start_angle, start_angle, phase - 1.0)
		return _agent_stream_base_direction.rotated(angle).normalized()
	if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_RING_PULSE:
		return _agent_stream_base_direction.rotated(deg_to_rad(float(agent_program.pulse_wave_rotation_degrees)) * float(max(_agent_stream_wave_index, 0))).normalized()
	if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST:
		return _agent_stream_base_direction.rotated(deg_to_rad(float(agent_program.pinwheel_rotation_degrees)) * float(max(_agent_stream_wave_index, 0))).normalized()
	var spiral_duration: float = max(float(agent_program.spiral_duration), 0.2)
	var spiral_progress: float = clamp(_agent_stream_elapsed / spiral_duration, 0.0, 1.0)
	var spiral_sign: float = 1.0 if _agent_stream_kind == AgentBossProgram.SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE else -1.0
	return _agent_stream_base_direction.rotated(spiral_sign * TAU * float(agent_program.spiral_rotations) * spiral_progress).normalized()


func _get_agent_special_shot_config(attack_verb: String) -> Dictionary:
	match attack_verb:
		AgentBossProgram.SPECIAL_ATTACK_ROCKET:
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
		AgentBossProgram.SPECIAL_ATTACK_MINIGUN_SWEEP_TWICE:
			return {
				"speed": projectile_speed * 1.45,
				"damage": projectile_damage,
				"radius": max(projectile_radius * 0.72, 4.8),
				"kind": "hostile_minigun",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"lifetime": 1.45,
				"knockback": 0.0
			}
		AgentBossProgram.SPECIAL_ATTACK_SPIRAL_CLOCKWISE, AgentBossProgram.SPECIAL_ATTACK_SPIRAL_COUNTER_CLOCKWISE:
			return {
				"speed": max(projectile_speed * 1.18, projectile_speed + 48.0),
				"damage": projectile_damage,
				"radius": max(projectile_radius * 0.82, 5.8),
				"kind": "hostile_spiral",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"lifetime": 1.45,
				"knockback": 0.0
			}
		AgentBossProgram.SPECIAL_ATTACK_RING_PULSE:
			return {
				"speed": max(projectile_speed * 0.95, 245.0),
				"damage": projectile_damage,
				"radius": max(projectile_radius * 0.72, 5.0),
				"kind": "hostile_pulse",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"lifetime": 1.5,
				"knockback": 0.0
			}
		AgentBossProgram.SPECIAL_ATTACK_PINWHEEL_BURST:
			return {
				"speed": max(projectile_speed * 1.12, projectile_speed + 32.0),
				"damage": projectile_damage,
				"radius": max(projectile_radius * 0.76, 5.4),
				"kind": "hostile_pinwheel",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"lifetime": 1.45,
				"knockback": 0.0
			}
		_:
			return {
				"speed": max(float(agent_program.slow_projectile_speed), projectile_speed * 1.3),
				"damage": projectile_damage,
				"radius": max(float(agent_program.slow_projectile_radius), 4.5),
				"kind": "hostile",
				"projectile_count": 1,
				"spread_angle_degrees": 0.0,
				"lifetime": 1.35,
				"knockback": 0.0
			}


func _try_emit_agent_standard_shot(to_target: Vector2, cooldown: float, shot_speed: float, damage: int, radius: float) -> void:
	if _agent_next_shot_remaining > 0.0 or to_target.length_squared() <= 4.0:
		return
	var shot_direction: Vector2 = to_target.normalized()
	var shot_origin: Vector2 = global_position + shot_direction * (body_radius + radius + 5.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return
	var shot_config: Dictionary = {
		"speed": shot_speed,
		"damage": max(damage, 1),
		"radius": radius,
		"kind": "hostile",
		"projectile_count": 1,
		"spread_angle_degrees": 0.0
	}
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)
	_agent_next_shot_remaining = max(cooldown, 0.05)
	_play_agent_shoot_pose(shot_direction)


func _get_agent_normal_movement_verb() -> String:
	return String(agent_program.normal_movement_verb) if agent_program != null else AgentBossProgram.NORMAL_STRAFE


func _get_agent_special_movement_verb() -> String:
	return String(agent_program.special_movement_verb) if agent_program != null else AgentBossProgram.SPECIAL_MOVEMENT_TELEPORT_LOS


func _get_agent_special_reposition_verb() -> String:
	return String(agent_program.special_reposition_verb) if agent_program != null else AgentBossProgram.SPECIAL_REPOSITION_APPROACH


func _get_agent_special_attack_verb() -> String:
	return String(agent_program.special_attack_verb) if agent_program != null else AgentBossProgram.SPECIAL_ATTACK_RING_PULSE


func _get_target_direction(to_target: Vector2) -> Vector2:
	if to_target.length_squared() > 0.001:
		return to_target.normalized()
	if target_position.distance_squared_to(global_position) > 0.001:
		return (target_position - global_position).normalized()
	return Vector2.RIGHT


func _agent_aim_at_target(to_target: Vector2) -> void:
	var aim: Vector2 = _get_target_direction(to_target)
	if aim.length_squared() > 0.001:
		_agent_aim_direction = aim


func _play_agent_shoot_pose(direction: Vector2) -> void:
	if direction.length_squared() <= 0.001:
		return
	_agent_aim_direction = direction.normalized()
	_agent_shoot_pose_remaining = max(float(agent_program.shoot_pose_hold_seconds), 0.0) if agent_program != null else 0.42
	queue_redraw()


func _update_agent_visual_state(delta: float, movement: Vector2) -> void:
	if not _is_agent_boss():
		return
	if movement.length_squared() > 1.0:
		_agent_walk_cycle += delta * 9.0
		_agent_last_move_facing_direction = movement.normalized()


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
