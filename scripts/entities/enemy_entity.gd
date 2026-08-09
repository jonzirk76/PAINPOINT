extends CharacterBody2D
class_name EnemyEntity

signal health_changed(enemy, old_value: int, new_value: int)
signal health_depleted(enemy)
signal death_animation_finished(enemy)
signal shot_ready(enemy, origin: Vector2, direction: Vector2, shot_config: Dictionary)
signal repair_ready(enemy, repair_target, amount: int)
signal spawn_ready(enemy, spawn_position: Vector2)
signal commissar_execution_ready(commissar, target)
signal commissar_execution_interrupted(commissar, target)

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
const ENEMY_COLLISION_LAYER := 2
const AGENT_BOSS_COLLISION_LAYER := 128
const STANDARD_ENEMY_COLLISION_MASK := 97
const AGENT_BOSS_COLLISION_MASK := 96
const AGENT_ACTION_SLOW := "slow_pressure"
const AGENT_ACTION_NORMAL := "normal"
const AGENT_ACTION_SPECIAL := "special"
const AGENT_SPECIAL_STAGE_MOVE := "move"
const AGENT_SPECIAL_STAGE_TELEPORT_CAST := "teleport_cast"
const AGENT_SPECIAL_STAGE_TELEGRAPH := "telegraph"
const AGENT_SPECIAL_STAGE_STREAM := "stream"
const AGENT_HE_RETICLE_MIN_RADIUS := 26.0
const AGENT_HE_RETICLE_MAX_RADIUS := 88.0
const BEHAVIOR_REPAIR_DRONE := "repair_drone"
const BEHAVIOR_SHIELD_DRONE := "shield_drone"
const BEHAVIOR_POWER_ARMOR := "power_armor"
const BEHAVIOR_CYBER_SOLDIER := "cyber_soldier"
const BEHAVIOR_BOSS := "boss"
const BEHAVIOR_SHOOTER := "shooter"
const BEHAVIOR_CHASER := "chaser"
const BEHAVIOR_COMMISSAR := "commissar"
const MIN_KNOCKBACK_WEIGHT := 0.5

enum HordeCommandState {
	INDEPENDENT,
	COORDINATED,
	ORPHANED,
	ROGUE
}

@export var max_health: int = 3
@export var speed: float = 85.0
## [Description] Multiplies this enemy's movement speed after it survives the loss of its general.
@export_range(1.0, 3.0, 0.05) var orphaned_speed_multiplier: float = 1.25
@export var contact_damage: int = 1
@export var contact_radius: float = 34.0
@export var contact_cooldown: float = 0.75
@export var score_value: int = 10
@export var body_radius: float = 18.0
## Controls this enemy's influence in soft crowd separation; zero-weight enemies yield without pushing others.
@export_range(0.0, 100.0, 0.1) var crowd_weight: float = 1.0
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
## Controls how far repair drones can restore allied enemies.
@export var repair_radius: float = 220.0
## Controls how much health one repair pulse restores.
@export var repair_amount: int = 1
## Controls the delay between repair pulses.
@export var repair_cooldown: float = 1.25
## Controls the health ratio below which repair drones consider an ally worth repairing.
@export_range(0.0, 1.0, 0.01) var repair_target_health_ratio: float = 0.92
## Controls the cooldown between non-boss special attack or reposition phases.
@export var special_cooldown: float = 3.0
## Controls the warning duration before non-boss special attacks fire.
@export var special_telegraph_seconds: float = 0.46
## Selects the primary non-boss special attack pattern for elite enemies.
@export var special_attack_kind: String = ""
## Selects the occasional secondary explosive attack for elite enemies.
@export var secondary_attack_kind: String = ""
## Selects the special movement phase used by tactical enemies.
@export var special_movement_kind: String = ""
## Controls how long minigun-style special streams last.
@export var special_minigun_duration: float = 0.82
## Controls the delay between individual minigun special bullets.
@export var special_minigun_shot_interval: float = 0.065
## Controls the total sweep angle of minigun special streams.
@export var special_minigun_sweep_degrees: float = 76.0
## Controls the fewest shots fired during autocannon special bursts.
@export var special_autocannon_min_shots: int = 2
## Controls the most shots fired during autocannon special bursts.
@export var special_autocannon_max_shots: int = 4
## Controls the delay between individual autocannon special shots.
@export var special_autocannon_shot_interval: float = 0.28
@export var projectile_shield_radius_bonus: float = 20.0
@export var boss_special_cooldown: float = 5.4
@export var boss_special_telegraph_seconds: float = 0.72
@export var boss_minigun_duration: float = 0.86
@export var boss_minigun_shot_interval: float = 0.065
@export var boss_minigun_sweep_degrees: float = 82.0
@export var agent_program: AgentBossProgram = null
## [Description] Configures veteran and support-corps behavior when this entity is a Commissar.
@export var commissar_program: CommissarProgram = null

var health: int = max_health
var playable_rects: Array[Rect2] = []
var target_position: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _crowd_separation_velocity: Vector2 = Vector2.ZERO
var _room_spatial_domain = null
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
var _burn_remaining: float = 0.0
var _burn_damage_per_second: float = 0.0
var _burn_damage_remainder: float = 0.0
var _slow_remaining: float = 0.0
var _slow_multiplier: float = 1.0
var _lightning_charge_remaining: float = 0.0
var _lightning_charge_stacks: int = 0
var _lightning_charge_max_stacks: int = 0
var _repair_target: Node2D = null
var _repair_cooldown_remaining: float = 0.0
var _repair_beam_remaining: float = 0.0
var _behavior_special_timer: float = 0.0
var _behavior_pattern_index: int = 0
var _behavior_burst_shots_remaining: int = 0
var _behavior_burst_interval_remaining: float = 0.0
var _behavior_burst_base_direction: Vector2 = Vector2.RIGHT
var _behavior_burst_config: Dictionary = {}
var _behavior_reposition_target: Vector2 = Vector2.INF
var _behavior_reposition_recovery_remaining: float = 0.0
var _behavior_reposition_attack_pending: bool = false
var _behavior_dash_steps_remaining: int = 0
var _boss_special_timer: float = 0.0
var _boss_special_telegraph_remaining: float = 0.0
var _boss_special_telegraph_duration: float = 0.72
var _boss_special_kind: String = ""
var _boss_special_sequence_index: int = 0
var _boss_minigun_remaining: float = 0.0
var _boss_minigun_elapsed: float = 0.0
var _boss_minigun_next_shot_remaining: float = 0.0
var _boss_minigun_base_direction: Vector2 = Vector2.RIGHT
var _boss_minigun_start_side: int = 1
var _boss_autocannon_side_sign: int = 1
var _boss_autocannon_shots_remaining: int = 0
var _boss_autocannon_next_shot_remaining: float = 0.0
var _path_blocker_rects: Array[Rect2] = []
var _cached_steering_target: Vector2 = Vector2.INF
var _path_cache_target_position: Vector2 = Vector2.INF
var _path_cache_enemy_position: Vector2 = Vector2.INF
var _path_repath_remaining: float = 0.0
var _path_repath_interval: float = PATH_REPATH_BASE_SECONDS
var _agent_rng := RandomNumberGenerator.new()
var _agent_action_kind: String = ""
var _agent_action_remaining: float = 0.0
var _agent_intro_pending: bool = false
var _agent_intro_remaining: float = 0.0
var _agent_next_shot_remaining: float = 0.0
var _agent_burst_interval_remaining: float = 0.0
var _agent_burst_shots_remaining: int = 0
var _agent_burst_base_direction: Vector2 = Vector2.RIGHT
var _agent_action_direction: Vector2 = Vector2.RIGHT
var _agent_tactical_target: Vector2 = Vector2.INF
var _agent_zigzag_sign: float = 1.0
var _agent_high_explosive_cooldown_remaining: float = 0.0
var _agent_high_explosive_roll_pending: bool = false
var _agent_high_explosive_windup_kind: String = ""
var _agent_high_explosive_windup_remaining: float = 0.0
var _agent_high_explosive_windup_duration: float = 0.0
var _agent_high_explosive_windup_direction: Vector2 = Vector2.RIGHT
var _agent_high_explosive_windup_target: Vector2 = Vector2.INF
var _agent_mine_sequence_remaining: int = 0
var _agent_mine_sequence_interval_remaining: float = 0.0
var _agent_mine_sequence_direction: Vector2 = Vector2.RIGHT
var _agent_special_cooldown_remaining: float = 0.0
var _agent_special_chain_count: int = 0
var _agent_special_attack_emitted: bool = false
var _agent_special_stage: String = ""
var _agent_special_telegraph_remaining: float = 0.0
var _agent_special_telegraph_duration: float = 0.58
var _agent_teleport_target: Vector2 = Vector2.INF
var _agent_teleport_cast_remaining: float = 0.0
var _agent_teleport_cast_duration: float = 0.0
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
var _collision_shape: CollisionShape2D = null
var _collision_add_deferred: bool = false
var spawn_profile: EnemySpawnProfile = null
var legion_id: int = 0
var general_id: int = 0
var horde_command_state: HordeCommandState = HordeCommandState.INDEPENDENT
var _spawn_timer: float = 0.0
var _spawn_active: bool = true
var _tactical_target_position: Vector2 = Vector2.INF
var _panic_source_position: Vector2 = Vector2.INF
var _commissar_shield_cooldown_remaining: float = 0.0
var _commissar_charge_cooldown_remaining: float = 0.0
var _commissar_charge_telegraph_remaining: float = 0.0
var _commissar_charge_remaining: float = 0.0
var _commissar_charge_direction: Vector2 = Vector2.RIGHT
var _commissar_charge_push_available: bool = false
var _commissar_reposition_target: Vector2 = Vector2.INF
var _commissar_execution_target: Node2D = null
var _commissar_execution_remaining: float = 0.0
var _commissar_execution_duration: float = 0.0


func _init() -> void:
	_configure_collision_identity()
	_add_collision()


func _ready() -> void:
	health = max_health
	_configure_collision_identity()
	_configure_path_cache_timing()
	_add_collision()
	queue_redraw()


func _configure_collision_identity() -> void:
	if _is_agent_boss():
		_set_body_collision_property("collision_layer", AGENT_BOSS_COLLISION_LAYER)
		_set_body_collision_property("collision_mask", AGENT_BOSS_COLLISION_MASK)
	else:
		_set_body_collision_property("collision_layer", ENEMY_COLLISION_LAYER)
		_set_body_collision_property("collision_mask", STANDARD_ENEMY_COLLISION_MASK)
	add_to_group("enemies")


func initialize(profile) -> void:
	if profile == null:
		return
	max_health = profile.max_health
	speed = profile.speed
	orphaned_speed_multiplier = max(float(profile.orphaned_speed_multiplier), 1.0) if profile.get("orphaned_speed_multiplier") != null else 1.25
	contact_damage = profile.contact_damage
	contact_radius = profile.contact_radius
	contact_cooldown = profile.contact_cooldown
	score_value = profile.score_value
	body_radius = profile.body_radius
	crowd_weight = max(float(profile.crowd_weight), 0.0) if profile.get("crowd_weight") != null else 1.0
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
	repair_radius = profile.repair_radius
	repair_amount = profile.repair_amount
	repair_cooldown = profile.repair_cooldown
	repair_target_health_ratio = profile.repair_target_health_ratio
	special_cooldown = profile.special_cooldown
	special_telegraph_seconds = profile.special_telegraph_seconds
	special_attack_kind = profile.special_attack_kind
	secondary_attack_kind = profile.secondary_attack_kind
	special_movement_kind = profile.special_movement_kind
	special_minigun_duration = profile.special_minigun_duration
	special_minigun_shot_interval = profile.special_minigun_shot_interval
	special_minigun_sweep_degrees = profile.special_minigun_sweep_degrees
	special_autocannon_min_shots = profile.special_autocannon_min_shots
	special_autocannon_max_shots = profile.special_autocannon_max_shots
	special_autocannon_shot_interval = profile.special_autocannon_shot_interval
	agent_program = profile.agent_program as AgentBossProgram if profile.get("agent_program") != null else null
	commissar_program = profile.commissar_program as CommissarProgram if profile.get("commissar_program") != null else null
	spawn_profile = profile.spawn_profile as EnemySpawnProfile if profile.get("spawn_profile") != null else null
	_spawn_timer = max(float(spawn_profile.warmup_seconds), 0.0) if spawn_profile != null else 0.0
	if is_general():
		contact_damage = 0
		contact_radius = 0.0
	if _is_agent_boss():
		contact_damage = 0
		contact_radius = 0.0
		_configure_collision_identity()
	elif _is_non_contact_specialist():
		contact_damage = 0
		contact_radius = 0.0
	_visual_kind = _get_visual_kind(profile)
	health = max_health
	_shot_cooldown_remaining = shot_cooldown * 0.65
	_repair_cooldown_remaining = repair_cooldown * 0.45
	_behavior_special_timer = special_cooldown * 0.55
	_behavior_pattern_index = int(get_instance_id() % 4)
	_behavior_burst_shots_remaining = 0
	_behavior_burst_interval_remaining = 0.0
	_behavior_reposition_target = Vector2.INF
	_behavior_reposition_recovery_remaining = 0.0
	_behavior_reposition_attack_pending = false
	_behavior_dash_steps_remaining = 0
	_panic_source_position = Vector2.INF
	_commissar_shield_cooldown_remaining = 0.0
	_commissar_charge_cooldown_remaining = 0.0
	_commissar_charge_telegraph_remaining = 0.0
	_commissar_charge_remaining = 0.0
	_commissar_charge_push_available = false
	_commissar_reposition_target = Vector2.INF
	_commissar_execution_target = null
	_commissar_execution_remaining = 0.0
	_commissar_execution_duration = 0.0
	if behavior_kind == BEHAVIOR_BOSS:
		_boss_special_timer = boss_special_cooldown * 0.55
		_boss_special_sequence_index = 0
	elif behavior_kind == BEHAVIOR_POWER_ARMOR:
		boss_special_cooldown = max(special_cooldown, 0.2)
		boss_special_telegraph_seconds = max(special_telegraph_seconds, 0.1)
		boss_minigun_duration = max(special_minigun_duration, 0.12)
		boss_minigun_shot_interval = max(special_minigun_shot_interval, 0.025)
		boss_minigun_sweep_degrees = max(special_minigun_sweep_degrees, 0.0)
		_boss_special_timer = boss_special_cooldown * 0.7
		_boss_special_sequence_index = 0
		_boss_minigun_start_side = -1 if int(get_instance_id()) % 2 == 0 else 1
		_boss_autocannon_side_sign = 1 if int(get_instance_id()) % 2 == 0 else -1
		var power_armor_rng_seed: int = int(get_instance_id())
		if power_armor_rng_seed < 0:
			power_armor_rng_seed = -power_armor_rng_seed
		if power_armor_rng_seed <= 0:
			power_armor_rng_seed = 1
		_agent_rng.seed = power_armor_rng_seed
	if _is_agent_boss():
		_configure_agent_boss_state()
	elif behavior_kind == BEHAVIOR_CYBER_SOLDIER:
		_configure_cyber_soldier_state()


func _physics_process(delta: float) -> void:
	_update_projectile_shield(delta)
	_update_status_effects(delta)
	if _hit_flash_remaining > 0.0:
		_hit_flash_remaining = max(_hit_flash_remaining - delta, 0.0)
	if _repair_beam_remaining > 0.0:
		_repair_beam_remaining = max(_repair_beam_remaining - delta, 0.0)
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
	_update_spawn_capability(delta)

	var to_target := target_position - global_position
	var intent_velocity := Vector2.ZERO
	if _is_agent_boss():
		intent_velocity = _update_agent_boss(delta, to_target)
	else:
		match behavior_kind:
			BEHAVIOR_REPAIR_DRONE:
				intent_velocity = _update_repair_drone(delta, to_target)
			BEHAVIOR_SHIELD_DRONE:
				intent_velocity = _update_shield_drone(delta, to_target)
			BEHAVIOR_POWER_ARMOR:
				intent_velocity = _update_power_armor(delta, to_target)
			BEHAVIOR_CYBER_SOLDIER:
				intent_velocity = _update_cyber_soldier(delta, to_target)
			BEHAVIOR_COMMISSAR:
				intent_velocity = _update_commissar(delta, to_target)
			_:
				intent_velocity = _get_ranged_velocity(to_target) if _is_ranged_behavior() else _get_chaser_velocity(to_target)
				var special_active := _update_general_special(delta, to_target) if is_general() else _update_boss_special(delta, to_target)
				if not special_active:
					_try_emit_shot(to_target)
				elif _boss_minigun_remaining > 0.0:
					intent_velocity = Vector2.ZERO
				else:
					intent_velocity *= 0.38
	intent_velocity *= _get_horde_command_speed_multiplier() * _get_status_speed_multiplier()
	velocity = intent_velocity + _knockback_velocity + _crowd_separation_velocity
	_update_agent_visual_state(delta, velocity)
	_update_visual_direction(velocity)
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 520.0 * delta)
	_crowd_separation_velocity = _crowd_separation_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	if _is_ranged_behavior() and get_slide_collision_count() > 0:
		_strafe_sign *= -1.0
		_agent_zigzag_sign *= -1.0
	global_position = _constrain_to_playable(global_position)
	if velocity.length_squared() > 1.0 or _is_ranged_behavior() or _hit_flash_remaining > 0.0 or _repair_beam_remaining > 0.0 or _knockback_velocity.length_squared() > 1.0 or is_projectile_shield_active() or _projectile_shield_block_flash_remaining > 0.0:
		queue_redraw()


func set_target_position(new_target_position: Vector2) -> void:
	var previous_position := target_position
	target_position = new_target_position
	if _is_ranged_behavior() and previous_position.distance_squared_to(target_position) > 1.0:
		queue_redraw()


func is_general() -> bool:
	return spawn_profile != null


func set_legion_identity(new_legion_id: int, new_general_id: int = 0) -> void:
	legion_id = max(new_legion_id, 0)
	general_id = max(new_general_id, 0)
	if general_id > 0 and not is_general():
		horde_command_state = HordeCommandState.COORDINATED
		_panic_source_position = Vector2.INF
	else:
		horde_command_state = HordeCommandState.INDEPENDENT
		_panic_source_position = Vector2.INF


func enter_orphaned_horde_state() -> void:
	if is_general():
		return
	legion_id = 0
	general_id = 0
	horde_command_state = HordeCommandState.ORPHANED
	_panic_source_position = Vector2.INF
	clear_tactical_target_position()


func enter_rogue_horde_state(fear_source_position: Vector2) -> void:
	if is_general():
		return
	horde_command_state = HordeCommandState.ROGUE
	_panic_source_position = fear_source_position
	_repair_target = null
	clear_tactical_target_position()


func is_orphaned_horde_enemy() -> bool:
	return horde_command_state == HordeCommandState.ORPHANED


func is_rogue_horde_enemy() -> bool:
	return horde_command_state == HordeCommandState.ROGUE


func get_horde_command_state() -> HordeCommandState:
	return horde_command_state


func set_spawn_enabled(value: bool) -> void:
	_spawn_active = value


func set_tactical_target_position(new_target_position: Vector2) -> void:
	_tactical_target_position = new_target_position


func clear_tactical_target_position() -> void:
	if _tactical_target_position == Vector2.INF:
		return
	_tactical_target_position = Vector2.INF
	_invalidate_path_cache()


func delay_next_spawn_until(delay_seconds: float) -> void:
	if not is_general():
		return
	_spawn_timer = max(_spawn_timer, max(delay_seconds, 0.0))


func _update_spawn_capability(delta: float) -> void:
	if not _spawn_active or not is_general() or health <= 0 or _is_dying:
		return
	var effective_delta: float = delta * _get_status_speed_multiplier()
	_spawn_timer -= effective_delta
	if _spawn_timer <= float(spawn_profile.projectile_shield_lead_seconds):
		activate_projectile_shield(max(_spawn_timer, 0.0) + float(spawn_profile.projectile_shield_after_spawn_seconds))
	if _spawn_timer > 0.0:
		return
	_spawn_timer = max(float(spawn_profile.spawn_interval), 0.1)
	spawn_ready.emit(self, global_position)


func set_repair_target(target) -> void:
	var repair_target := target as Node2D
	if repair_target == self or repair_target == null or not is_instance_valid(repair_target):
		_repair_target = null
		return
	if not repair_target.is_in_group("enemies") and not repair_target.is_in_group("spawners"):
		_repair_target = null
		return
	if not repair_target.has_method("apply_healing"):
		_repair_target = null
		return
	_repair_target = repair_target


func apply_healing(amount: int) -> bool:
	if amount <= 0 or health <= 0 or _is_dying or is_birth_animation_active() or health >= max_health:
		return false
	var old_health := health
	health = min(health + amount, max_health)
	health_changed.emit(self, old_health, health)
	_hit_flash_remaining = max(_hit_flash_remaining, 0.06)
	queue_redraw()
	return health > old_health


func set_arena_definition(bounds: Rect2, shape: int, walls: Array = [], voids: Array = [], playable_regions: Array = [], spatial_domain = null) -> void:
	arena_bounds = bounds
	arena_shape = shape
	_room_spatial_domain = spatial_domain
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
	if _try_activate_commissar_reactive_shield(packet):
		return false
	if blocks_projectile_damage(packet):
		return false
	if _commissar_execution_target != null:
		var interrupted_target := _commissar_execution_target
		_clear_commissar_execution()
		commissar_execution_interrupted.emit(self, interrupted_target)
	var damage_amount: int = max(int(packet.damage), 0)
	damage_amount = _apply_lightning_charge_damage_multiplier(packet, damage_amount)
	if _should_reduce_shield_pierce_damage(packet):
		damage_amount = max(roundi(float(damage_amount) * clamp(float(packet.shield_damage_multiplier), 0.05, 1.0)), 1)
		_projectile_shield_block_flash_remaining = 0.24
	_apply_knockback(packet)
	_hit_flash_remaining = 0.12
	_apply_damage_amount(damage_amount)
	_apply_status_effects_from_packet(packet)
	return true


func _apply_damage_amount(damage_amount: int) -> void:
	if damage_amount <= 0 or health <= 0 or _is_dying:
		return
	var old_health := health
	health = max(health - damage_amount, 0)
	health_changed.emit(self, old_health, health)
	queue_redraw()
	if health == 0:
		health_depleted.emit(self)
		_play_death_animation()


func _apply_status_effects_from_packet(packet) -> void:
	if packet == null or health <= 0 or _is_dying:
		return
	if float(packet.burn_damage_per_second) > 0.0 and float(packet.burn_duration_seconds) > 0.0:
		_burn_damage_per_second = max(_burn_damage_per_second, float(packet.burn_damage_per_second))
		_burn_remaining = max(_burn_remaining, float(packet.burn_duration_seconds))
	if float(packet.slow_duration_seconds) > 0.0 and float(packet.slow_multiplier) < 1.0:
		_slow_multiplier = min(_slow_multiplier, clamp(float(packet.slow_multiplier), 0.25, 1.0))
		_slow_remaining = max(_slow_remaining, float(packet.slow_duration_seconds))
	if float(packet.lightning_charge_damage_multiplier) > 1.0 and int(packet.lightning_charge_max_stacks) > 0:
		_lightning_charge_max_stacks = max(_lightning_charge_max_stacks, int(packet.lightning_charge_max_stacks))
		_lightning_charge_stacks = clampi(_lightning_charge_stacks + 1, 1, _lightning_charge_max_stacks)
		_lightning_charge_remaining = max(_lightning_charge_remaining, float(packet.lightning_charge_duration_seconds))
	queue_redraw()


func _apply_lightning_charge_damage_multiplier(packet, damage_amount: int) -> int:
	if packet == null or _lightning_charge_remaining <= 0.0 or _lightning_charge_stacks <= 0:
		return damage_amount
	var required_stacks: int = max(int(packet.lightning_charge_required_stacks), 1)
	if _lightning_charge_stacks < required_stacks:
		return damage_amount
	var multiplier: float = max(float(packet.lightning_charge_damage_multiplier), 1.0)
	return max(roundi(float(damage_amount) * multiplier), damage_amount)


func _update_status_effects(delta: float) -> void:
	if health <= 0 or _is_dying or is_birth_animation_active():
		return
	var had_status := _has_active_status_effects()
	if _burn_remaining > 0.0:
		_burn_remaining = max(_burn_remaining - delta, 0.0)
		_burn_damage_remainder += max(_burn_damage_per_second, 0.0) * delta
		var burn_damage: int = floori(_burn_damage_remainder)
		if burn_damage > 0:
			_burn_damage_remainder -= float(burn_damage)
			_hit_flash_remaining = max(_hit_flash_remaining, 0.08)
			_apply_damage_amount(burn_damage)
			if health <= 0 or _is_dying:
				return
		if _burn_remaining <= 0.0:
			_burn_damage_per_second = 0.0
			_burn_damage_remainder = 0.0
	if _slow_remaining > 0.0:
		_slow_remaining = max(_slow_remaining - delta, 0.0)
		if _slow_remaining <= 0.0:
			_slow_multiplier = 1.0
	if _lightning_charge_remaining > 0.0:
		_lightning_charge_remaining = max(_lightning_charge_remaining - delta, 0.0)
		if _lightning_charge_remaining <= 0.0:
			_lightning_charge_stacks = 0
			_lightning_charge_max_stacks = 0
	if had_status or _has_active_status_effects():
		queue_redraw()


func _has_active_status_effects() -> bool:
	return _burn_remaining > 0.0 or _slow_remaining > 0.0 or _lightning_charge_remaining > 0.0


func _get_status_speed_multiplier() -> float:
	if _slow_remaining <= 0.0:
		return 1.0
	var multiplier: float = clamp(_slow_multiplier, 0.25, 1.0)
	if behavior_kind == "boss" or _is_agent_boss():
		multiplier = max(lerp(1.0, multiplier, 0.45), 0.7)
	return multiplier


func _get_horde_command_speed_multiplier() -> float:
	if horde_command_state == HordeCommandState.ORPHANED or horde_command_state == HordeCommandState.ROGUE:
		return max(orphaned_speed_multiplier, 1.0)
	return 1.0


func activate_projectile_shield(duration: float) -> void:
	if duration <= 0.0 or health <= 0 or _is_dying:
		return
	_projectile_shield_remaining = max(_projectile_shield_remaining, duration)
	queue_redraw()


func is_projectile_shield_active() -> bool:
	return (_projectile_shield_remaining > 0.0 or _agent_intro_pending) and health > 0 and not _is_dying


func prepare_agent_boss_intro() -> void:
	if not _is_agent_boss() or health <= 0 or _is_dying:
		return
	_finish_agent_action()
	_agent_intro_pending = true
	_agent_intro_remaining = 0.0
	queue_redraw()


func start_agent_boss_intro(duration: float) -> void:
	if not _is_agent_boss() or health <= 0 or _is_dying:
		return
	_agent_intro_pending = false
	if duration <= 0.0:
		queue_redraw()
		return
	_finish_agent_action()
	_agent_intro_remaining = max(duration, 0.0)
	activate_projectile_shield(_agent_intro_remaining + 0.25)
	queue_redraw()


func blocks_projectile_damage(packet) -> bool:
	if packet == null or not is_projectile_shield_active():
		return false
	if String(packet.projectile_kind) == "hostile":
		return false
	if _is_agent_boss() and _agent_intro_remaining > 0.0:
		_projectile_shield_block_flash_remaining = 0.2
		queue_redraw()
		return true
	if bool(packet.pierces_projectile_shields):
		return false
	_projectile_shield_block_flash_remaining = 0.2
	queue_redraw()
	return true


func is_super_shot_impact_target() -> bool:
	return behavior_kind == "boss" or max_health >= 8 or body_radius >= 27.0 or crowd_weight >= 4.0


func apply_pushback(source_position: Vector2, force: float) -> void:
	if force <= 0.0 or health <= 0 or _is_dying or is_birth_animation_active():
		return
	var push_direction := global_position - source_position
	if push_direction.length_squared() <= 0.001:
		push_direction = Vector2.RIGHT
	var effective_force: float = force * _get_knockback_weight_response()
	_knockback_velocity += push_direction.normalized() * effective_force
	_knockback_velocity = _knockback_velocity.limit_length(max(effective_force, 260.0))
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
	_disable_collision_state()
	queue_redraw()


func _configure_path_cache_timing() -> void:
	_path_repath_interval = PATH_REPATH_BASE_SECONDS + float(get_instance_id() % 7) * PATH_REPATH_STAGGER_SECONDS


func _rebuild_path_blocker_cache() -> void:
	_path_blocker_rects.clear()
	_path_blocker_rects.append_array(wall_rects)
	_path_blocker_rects.append_array(void_rects)
	if _room_spatial_domain != null and _room_spatial_domain.has_method("get_transition_regions"):
		_path_blocker_rects.append_array(_room_spatial_domain.get_transition_regions())


func _constrain_to_playable(candidate_position: Vector2) -> Vector2:
	if _room_spatial_domain != null and _room_spatial_domain.has_method("constrain_operational_position"):
		return _room_spatial_domain.constrain_operational_position(candidate_position, body_radius)
	return ArenaGeometry.constrain_point_to_playable_regions(candidate_position, arena_bounds, arena_shape, playable_rects, [], body_radius)


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
	if _uses_agent_character_art():
		_draw_agent_character_art(draw_color)
	elif is_general():
		_draw_general_character_art(draw_color)
	else:
		_draw_enemy_character_art(draw_color)
	if behavior_kind == BEHAVIOR_REPAIR_DRONE and (is_rogue_horde_enemy() or is_orphaned_horde_enemy()):
		_draw_repair_drone_panic_state()
	if _repair_beam_remaining > 0.0:
		_draw_repair_beam()
	if _has_active_status_effects():
		_draw_status_effects()
	if is_projectile_shield_active() or _projectile_shield_block_flash_remaining > 0.0:
		_draw_projectile_shield()
	if _uses_agent_character_art() and _agent_teleport_cast_remaining > 0.0:
		_draw_agent_teleport_cast()
	if _is_agent_boss() and _agent_high_explosive_windup_remaining > 0.0:
		_draw_agent_high_explosive_windup()
	if _is_agent_boss() and (_agent_special_telegraph_remaining > 0.0 or _agent_charge_remaining > 0.0):
		_draw_agent_special_telegraph()
	elif behavior_kind == BEHAVIOR_COMMISSAR and (_commissar_charge_telegraph_remaining > 0.0 or _commissar_charge_remaining > 0.0):
		_draw_commissar_charge_telegraph()
	elif _boss_special_telegraph_remaining > 0.0:
		_draw_boss_special_telegraph()
	if behavior_kind == BEHAVIOR_COMMISSAR and _commissar_execution_target != null:
		_draw_commissar_execution_telegraph()
	if _is_agent_boss() and _agent_stream_remaining > 0.0:
		_draw_agent_special_stream()
	elif _boss_minigun_remaining > 0.0:
		_draw_boss_minigun_sweep()
	draw_line(Vector2(-body_radius, -body_radius - 8.0), Vector2(-body_radius + body_radius * 2.0 * health_ratio, -body_radius - 8.0), Color(0.4, 1.0, 0.35, birth_alpha), 3.0)
	if _is_ranged_behavior() and not _uses_agent_character_art() and not is_general():
		var aim := (target_position - global_position).normalized()
		if aim.length_squared() <= 0.001:
			aim = Vector2.RIGHT
		var aim_color := Color(accent_color.r, accent_color.g, accent_color.b, birth_alpha)
		if behavior_kind == BEHAVIOR_BOSS or behavior_kind == BEHAVIOR_POWER_ARMOR:
			draw_arc(Vector2.ZERO, body_radius + 7.0, 0.0, TAU, 36, aim_color, 4.0)
		draw_line(Vector2.ZERO, aim * (body_radius + 14.0), aim_color, 3.0)
		draw_circle(aim * (body_radius + 14.0), 3.5, Color(0.06, 0.05, 0.08, birth_alpha))
	if _hit_flash_remaining > 0.0:
		draw_circle(Vector2.ZERO, body_radius * 1.08, Color(1.0, 0.95, 0.82, 0.28))
		draw_arc(Vector2.ZERO, body_radius + 4.0, 0.0, TAU, 28, Color(1.0, 1.0, 1.0, 0.8), 3.0)
	if is_birth_animation_active():
		_draw_birth_animation_overlay()


func _draw_general_character_art(tint: Color) -> void:
	var base_color := Color(body_color.r, body_color.g, body_color.b, tint.a)
	var core_color := Color(
		lerp(body_color.r, accent_color.r, 0.62),
		lerp(body_color.g, accent_color.g, 0.62),
		lerp(body_color.b, accent_color.b, 0.62),
		tint.a
	)
	if _hit_flash_remaining > 0.0:
		base_color = Color(0.96, 0.9, 0.82, tint.a)
		core_color = Color(1.0, 0.58, 1.0, tint.a)
	var base_points := PackedVector2Array([
		Vector2(-body_radius, body_radius * 0.55),
		Vector2(-body_radius * 0.7, -body_radius * 0.6),
		Vector2(0.0, -body_radius),
		Vector2(body_radius * 0.7, -body_radius * 0.6),
		Vector2(body_radius, body_radius * 0.55),
		Vector2(0.0, body_radius)
	])
	draw_colored_polygon(base_points, base_color)
	draw_polyline(_get_closed_points(base_points), Color(0.08, 0.06, 0.1, tint.a), 3.0, true)
	_draw_general_type_details(core_color, tint.a)
	var health_ratio: float = float(health) / float(max(max_health, 1))
	draw_arc(Vector2.ZERO, body_radius * 0.38, 0.0, TAU * health_ratio, 28, Color(accent_color.r, accent_color.g, accent_color.b, tint.a), 4.0)
	var damage_level: float = 1.0 - health_ratio
	var crack_color := Color(0.04, 0.03, 0.05, tint.a)
	if damage_level > 0.22:
		draw_line(Vector2(-body_radius * 0.55, -body_radius * 0.2), Vector2(-body_radius * 0.1, body_radius * 0.18), crack_color, 2.0)
	if damage_level > 0.48:
		draw_line(Vector2(body_radius * 0.52, -body_radius * 0.32), Vector2(body_radius * 0.12, body_radius * 0.4), crack_color, 2.0)
	if damage_level > 0.72:
		draw_line(Vector2(-body_radius * 0.18, -body_radius * 0.72), Vector2(body_radius * 0.42, -body_radius * 0.18), crack_color, 2.0)


func _draw_general_type_details(core_color: Color, alpha: float) -> void:
	var visual_kind: String = String(spawn_profile.visual_kind) if spawn_profile != null else "basic"
	match visual_kind:
		"commissar":
			var aim := (target_position - global_position).normalized()
			if aim.length_squared() <= 0.001:
				aim = Vector2.RIGHT
			draw_rect(Rect2(Vector2(-body_radius * 0.48, -body_radius * 0.32), Vector2(body_radius * 0.96, body_radius * 0.88)), Color(0.07, 0.09, 0.12, alpha), true)
			draw_rect(Rect2(Vector2(-body_radius * 0.64, -body_radius * 0.72), Vector2(body_radius * 1.28, body_radius * 0.28)), Color(0.11, 0.13, 0.17, alpha), true)
			draw_line(Vector2(-body_radius * 0.58, -body_radius * 0.43), Vector2(body_radius * 0.58, -body_radius * 0.43), Color(accent_color.r, accent_color.g, accent_color.b, alpha), 3.0)
			draw_circle(Vector2.ZERO, body_radius * 0.22, core_color)
			draw_line(aim * body_radius * 0.12, aim * (body_radius + 10.0), Color(accent_color.r, accent_color.g, accent_color.b, alpha), 5.0)
		"tank":
			draw_rect(Rect2(Vector2(-body_radius * 0.48, -body_radius * 0.42), Vector2(body_radius * 0.96, body_radius * 0.84)), Color(0.12, 0.08, 0.08, alpha), true)
			draw_rect(Rect2(Vector2(-body_radius * 0.32, -body_radius * 0.3), Vector2(body_radius * 0.64, body_radius * 0.6)), core_color, true)
			draw_line(Vector2(-body_radius * 0.75, body_radius * 0.7), Vector2(body_radius * 0.75, body_radius * 0.7), Color(accent_color.r, accent_color.g, accent_color.b, alpha), 4.0)
		"fast":
			var points := PackedVector2Array([
				Vector2(0.0, -body_radius * 0.52),
				Vector2(body_radius * 0.5, 0.0),
				Vector2(0.0, body_radius * 0.52),
				Vector2(-body_radius * 0.5, 0.0)
			])
			draw_colored_polygon(points, core_color)
			draw_polyline(_get_closed_points(points), Color(accent_color.r, accent_color.g, accent_color.b, alpha), 2.0, true)
		"shooter":
			var aim := (target_position - global_position).normalized()
			if aim.length_squared() <= 0.001:
				aim = Vector2.RIGHT
			draw_circle(Vector2.ZERO, body_radius * 0.31, core_color)
			draw_line(Vector2.ZERO, aim * (body_radius * 0.82), Color(accent_color.r, accent_color.g, accent_color.b, alpha), 7.0)
			draw_circle(aim * (body_radius * 0.82), body_radius * 0.1, Color(0.04, 0.04, 0.07, alpha))
		_:
			draw_rect(Rect2(Vector2(-body_radius * 0.42, -body_radius * 0.38), Vector2(body_radius * 0.84, body_radius * 0.78)), Color(0.16, 0.12, 0.18, alpha), true)
			draw_circle(Vector2.ZERO, body_radius * 0.28, core_color)


func _draw_commissar_charge_telegraph() -> void:
	var direction := _commissar_charge_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	var telegraph_ratio := 1.0
	if _commissar_charge_telegraph_remaining > 0.0 and commissar_program != null:
		telegraph_ratio = 1.0 - clamp(_commissar_charge_telegraph_remaining / max(float(commissar_program.charge_telegraph_seconds), 0.001), 0.0, 1.0)
	var line_length: float = max(float(commissar_program.charge_trigger_distance), 120.0) if commissar_program != null else 160.0
	var color := Color(1.0, 0.22, 0.1, 0.42 + telegraph_ratio * 0.42)
	draw_line(direction * body_radius, direction * line_length, color, 5.0 + telegraph_ratio * 3.0)
	draw_arc(Vector2.ZERO, body_radius + 10.0 + telegraph_ratio * 7.0, direction.angle() - 0.45, direction.angle() + 0.45, 16, color, 4.0)


func _draw_commissar_execution_telegraph() -> void:
	if not is_instance_valid(_commissar_execution_target):
		return
	var target_offset: Vector2 = to_local(_commissar_execution_target.global_position)
	var progress := 1.0 - clamp(_commissar_execution_remaining / max(_commissar_execution_duration, 0.001), 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.04)
	var line_color := Color(1.0, 0.16 + pulse * 0.12, 0.08, 0.48 + progress * 0.4)
	draw_dashed_line(Vector2.ZERO, target_offset, line_color, 4.0, 10.0 - progress * 4.0)
	draw_arc(target_offset, 16.0 + progress * 10.0, 0.0, TAU, 30, line_color, 4.0)


func _draw_repair_drone_panic_state() -> void:
	var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.055)
	var panic_color := Color(1.0, 0.18, 0.12, 0.78 + pulse * 0.2) if is_rogue_horde_enemy() else Color(0.58, 0.84, 1.0, 0.58 + pulse * 0.24)
	var marker_position := Vector2(0.0, -body_radius - 15.0 - pulse * 3.0)
	draw_line(marker_position + Vector2(0.0, -7.0), marker_position + Vector2(0.0, 2.0), panic_color, 3.5)
	draw_circle(marker_position + Vector2(0.0, 7.0), 2.2, panic_color)
	if is_rogue_horde_enemy():
		draw_arc(Vector2.ZERO, body_radius + 6.0 + pulse * 2.0, -PI * 0.15, PI * 1.15, 28, panic_color, 2.5)


func _get_closed_points(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	if not closed.is_empty():
		closed.append(closed[0])
	return closed


func _draw_enemy_character_art(tint: Color) -> void:
	var texture := _get_visual_texture()
	if texture == null:
		return
	var visual_radius: float = body_radius * _get_visual_scale()
	var visual_rotation: float = _get_visual_rotation()
	var body_tint: Color = _get_enemy_body_tint(tint)
	draw_set_transform(Vector2.ZERO, visual_rotation, Vector2.ONE)
	draw_texture_rect(texture, Rect2(Vector2(-visual_radius, -visual_radius), Vector2(visual_radius * 2.0, visual_radius * 2.0)), false, body_tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _get_enemy_body_tint(base_tint: Color) -> Color:
	if _hit_flash_remaining > 0.0 or not _is_non_contact_specialist():
		return base_tint
	return Color(
		lerp(1.0, body_color.r, 0.72),
		lerp(1.0, body_color.g, 0.72),
		lerp(1.0, body_color.b, 0.72),
		base_tint.a
	)


func _draw_status_effects() -> void:
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.035)
	if _burn_remaining > 0.0:
		var burn_ratio: float = clamp(_burn_remaining / 3.5, 0.0, 1.0)
		draw_arc(Vector2.ZERO, body_radius + 5.0 + pulse * 3.0, -PI * 0.28, PI * 1.42, 36, Color(1.0, 0.34, 0.08, 0.48 + burn_ratio * 0.24), 3.0)
		for index in range(4):
			var ember_angle: float = TAU * float(index) / 4.0 + pulse * TAU
			var ember_position := Vector2.RIGHT.rotated(ember_angle) * (body_radius + 2.0 + float(index % 2) * 4.0)
			draw_circle(ember_position, 2.0 + pulse * 1.2, Color(1.0, 0.68, 0.14, 0.42))
	if _slow_remaining > 0.0:
		var slow_ratio: float = clamp(1.0 - _slow_multiplier, 0.0, 1.0)
		draw_circle(Vector2.ZERO, body_radius + 7.0, Color(0.18, 0.62, 1.0, 0.08 + slow_ratio * 0.12))
		draw_arc(Vector2.ZERO, body_radius + 9.0 + pulse * 2.0, PI * 0.12, PI * 1.8, 42, Color(0.48, 0.9, 1.0, 0.42 + slow_ratio * 0.2), 2.6)
	if _lightning_charge_remaining > 0.0 and _lightning_charge_stacks > 0:
		var stack_ratio: float = clamp(float(_lightning_charge_stacks) / float(max(_lightning_charge_max_stacks, 1)), 0.0, 1.0)
		var radius: float = body_radius + 11.0 + stack_ratio * 6.0 + pulse * 2.0
		for index in range(max(_lightning_charge_stacks, 1)):
			var angle_a: float = TAU * float(index) / float(max(_lightning_charge_stacks, 1)) + pulse * TAU * 0.2
			var angle_b: float = angle_a + 0.36 + pulse * 0.08
			draw_line(Vector2.RIGHT.rotated(angle_a) * radius, Vector2.RIGHT.rotated(angle_b) * (radius + 5.0), Color(0.74, 0.48, 1.0, 0.5 + stack_ratio * 0.25), 2.4)
		draw_arc(Vector2.ZERO, radius + 2.0, -PI * 0.5, -PI * 0.5 + TAU * stack_ratio, 38, Color(0.72, 1.0, 1.0, 0.34 + stack_ratio * 0.26), 2.6)


func _draw_repair_beam() -> void:
	var target := _repair_target as Node2D
	if target == null or not is_instance_valid(target):
		return
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.045)
	var target_offset: Vector2 = to_local(target.global_position)
	var beam_color := Color(0.42, 1.0, 0.58, 0.44 + pulse * 0.24)
	draw_line(Vector2.ZERO, target_offset, beam_color, 4.0)
	draw_line(Vector2.ZERO, target_offset, Color(1.0, 1.0, 0.78, 0.32 + pulse * 0.22), 1.8)
	draw_circle(target_offset, 6.0 + pulse * 2.0, Color(0.52, 1.0, 0.66, 0.26 + pulse * 0.18))


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
	var is_shooting: bool = _agent_shoot_pose_remaining > 0.0 or _agent_special_telegraph_remaining > 0.0 or _agent_stream_remaining > 0.0 or _agent_high_explosive_windup_remaining > 0.0 or _agent_teleport_cast_remaining > 0.0
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
	if behavior_kind == BEHAVIOR_CYBER_SOLDIER:
		return Color(body_color.r, body_color.g, body_color.b, base_tint.a)
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
	if (_agent_shoot_pose_remaining > 0.0 or _agent_special_telegraph_remaining > 0.0 or _agent_stream_remaining > 0.0 or _agent_high_explosive_windup_remaining > 0.0 or _agent_teleport_cast_remaining > 0.0) and _agent_aim_direction.length_squared() > 0.001:
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


func _draw_agent_centered_texture(texture: Texture2D, visual_radius: float, texture_rotation: float, tint: Color, texture_scale: Vector2 = Vector2.ONE) -> void:
	if texture == null:
		return
	draw_set_transform(Vector2.ZERO, texture_rotation, texture_scale)
	draw_texture_rect(texture, Rect2(Vector2(-visual_radius, -visual_radius), Vector2(visual_radius * 2.0, visual_radius * 2.0)), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_agent_oval(center: Vector2, oval_rotation: float, oval_scale: Vector2, color: Color) -> void:
	draw_set_transform(center, oval_rotation, oval_scale)
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


func _draw_agent_teleport_cast() -> void:
	if _agent_teleport_target == Vector2.INF:
		return
	var duration: float = max(_agent_teleport_cast_duration, 0.001)
	var progress: float = 1.0 - clamp(_agent_teleport_cast_remaining / duration, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.06)
	var destination: Vector2 = _agent_teleport_target - global_position
	var cast_color: Color = _get_agent_accent_color(0.82)
	draw_circle(Vector2.ZERO, body_radius + 16.0 + progress * 18.0, Color(cast_color.r, cast_color.g, cast_color.b, 0.08 + pulse * 0.08))
	draw_arc(Vector2.ZERO, body_radius + 18.0 + progress * 18.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 54, cast_color, 4.0)
	draw_line(Vector2.ZERO, destination, Color(cast_color.r, cast_color.g, cast_color.b, 0.22 + progress * 0.24), 2.0)
	var marker_radius: float = body_radius + 18.0 + pulse * 5.0
	draw_circle(destination, marker_radius, Color(cast_color.r, cast_color.g, cast_color.b, 0.08 + progress * 0.12))
	draw_arc(destination, marker_radius, progress * TAU, progress * TAU + TAU * 0.86, 60, Color(1.0, 0.94, 0.35, 0.82), 4.0)
	draw_arc(destination, marker_radius + 10.0, -progress * TAU, -progress * TAU + TAU * 0.64, 50, Color(0.42, 1.0, 1.0, 0.62), 3.0)
	for index in range(4):
		var direction: Vector2 = Vector2.RIGHT.rotated(TAU * float(index) / 4.0 + progress * TAU * 0.5)
		draw_line(destination + direction * (marker_radius - 7.0), destination + direction * (marker_radius + 11.0), Color(1.0, 1.0, 0.75, 0.68), 2.4)


func _draw_agent_high_explosive_windup() -> void:
	var duration: float = max(_agent_high_explosive_windup_duration, 0.001)
	var progress: float = 1.0 - clamp(_agent_high_explosive_windup_remaining / duration, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.058)
	var aim: Vector2 = _agent_high_explosive_windup_direction.normalized()
	if aim.length_squared() <= 0.001:
		aim = _get_target_direction(target_position - global_position)
	var explosive_color: Color = Color(1.0, 0.45, 0.12, 0.8)
	if _agent_high_explosive_windup_kind == AgentBossProgram.HIGH_EXPLOSIVE_GRENADE:
		explosive_color = Color(1.0, 0.7, 0.18, 0.82)
	elif _agent_high_explosive_windup_kind == AgentBossProgram.HIGH_EXPLOSIVE_MINES:
		explosive_color = Color(1.0, 0.22, 0.12, 0.78)
	var radius: float = body_radius + 16.0 + progress * 14.0 + pulse * 4.0
	draw_circle(Vector2.ZERO, radius, Color(explosive_color.r, explosive_color.g, explosive_color.b, 0.08 + pulse * 0.08))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, explosive_color, 4.0)
	draw_line(Vector2.ZERO, aim * (body_radius + 76.0), Color(1.0, 0.82, 0.22, 0.42 + progress * 0.34), 3.0)
	if _agent_high_explosive_windup_target != Vector2.INF:
		var target_offset: Vector2 = _agent_high_explosive_windup_target - global_position
		var target_radius: float = _get_agent_high_explosive_reticle_radius(_agent_high_explosive_windup_kind)
		_draw_agent_high_explosive_target_reticle(target_offset, target_radius, progress, pulse, explosive_color)
	if _agent_high_explosive_windup_kind == AgentBossProgram.HIGH_EXPLOSIVE_MINES:
		for index in range(3):
			var marker_direction: Vector2 = aim.rotated((float(index) - 1.0) * 0.38)
			draw_circle(marker_direction * (body_radius + 36.0 + progress * 18.0), 5.0 + pulse * 2.0, Color(1.0, 0.26, 0.12, 0.58))


func _get_agent_high_explosive_reticle_radius(explosive_kind: String) -> float:
	var blast_radius: float = body_radius + 22.0
	if agent_program != null:
		match explosive_kind:
			AgentBossProgram.HIGH_EXPLOSIVE_GRENADE:
				blast_radius = max(float(agent_program.high_explosive_grenade_radius), 44.0)
			AgentBossProgram.HIGH_EXPLOSIVE_MINES:
				blast_radius = max(float(agent_program.high_explosive_mine_blast_radius), 38.0)
			_:
				blast_radius = max(float(agent_program.high_explosive_rocket_radius), 48.0)
	return clamp(blast_radius, AGENT_HE_RETICLE_MIN_RADIUS, AGENT_HE_RETICLE_MAX_RADIUS)


func _draw_agent_high_explosive_target_reticle(center: Vector2, reticle_radius: float, progress: float, pulse: float, reticle_color: Color) -> void:
	var radius: float = clamp(reticle_radius, AGENT_HE_RETICLE_MIN_RADIUS, AGENT_HE_RETICLE_MAX_RADIUS)
	var inner_radius: float = max(radius * 0.42, 12.0)
	var rotation_offset: float = progress * TAU
	draw_circle(center, radius, Color(reticle_color.r, reticle_color.g, reticle_color.b, 0.045 + pulse * 0.035))
	draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 58, Color(reticle_color.r, reticle_color.g, reticle_color.b, 0.78), 3.2)
	draw_arc(center, inner_radius, rotation_offset, rotation_offset + TAU * 0.52, 34, Color(1.0, 0.94, 0.28, 0.68), 2.2)
	draw_line(center + Vector2.LEFT * radius, center + Vector2.LEFT * inner_radius, Color(1.0, 0.94, 0.28, 0.58), 2.0)
	draw_line(center + Vector2.RIGHT * inner_radius, center + Vector2.RIGHT * radius, Color(1.0, 0.94, 0.28, 0.58), 2.0)
	draw_line(center + Vector2.UP * radius, center + Vector2.UP * inner_radius, Color(1.0, 0.94, 0.28, 0.58), 2.0)
	draw_line(center + Vector2.DOWN * inner_radius, center + Vector2.DOWN * radius, Color(1.0, 0.94, 0.28, 0.58), 2.0)


func _draw_boss_special_telegraph() -> void:
	var progress: float = 1.0 - clamp(_boss_special_telegraph_remaining / max(_boss_special_telegraph_duration, 0.001), 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.045)
	var aim := (target_position - global_position).normalized()
	if aim.length_squared() <= 0.001:
		aim = Vector2.RIGHT
	var telegraph_color := Color(1.0, 0.92, 0.28, 0.78)
	if _boss_special_kind == "rocket":
		telegraph_color = Color(1.0, 0.32, 0.12, 0.86)
	elif _boss_special_kind == "grenade":
		telegraph_color = Color(1.0, 0.62, 0.16, 0.84)
	elif _boss_special_kind == "autocannon":
		telegraph_color = Color(0.52, 1.0, 1.0, 0.82)
	var radius: float = body_radius + 16.0 + progress * 18.0 + pulse * 4.0
	draw_circle(Vector2.ZERO, radius, Color(telegraph_color.r, telegraph_color.g, telegraph_color.b, 0.09 + pulse * 0.08))
	draw_arc(Vector2.ZERO, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 54, telegraph_color, 5.0)
	if _boss_special_kind == "minigun":
		var sweep_direction: Vector2 = _get_boss_minigun_direction_for_progress(aim, progress)
		var side: Vector2 = sweep_direction.orthogonal()
		draw_line(side * -body_radius * 1.1, sweep_direction * (body_radius + 82.0), Color(1.0, 0.96, 0.58, 0.75), 4.0)
		draw_line(side * body_radius * 1.1, sweep_direction * (body_radius + 82.0), Color(0.54, 1.0, 1.0, 0.45), 3.0)
	elif _boss_special_kind == "autocannon":
		var side: Vector2 = aim.orthogonal() * float(_get_boss_autocannon_side_sign())
		var muzzle_offset: Vector2 = side * body_radius * 0.58
		draw_line(muzzle_offset, muzzle_offset + aim * (body_radius + 94.0), Color(0.54, 1.0, 1.0, 0.82), 5.0)
		draw_circle(muzzle_offset + aim * (body_radius + 24.0), 5.0 + pulse * 2.0, Color(1.0, 0.96, 0.58, 0.72))
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
	if String(profile.behavior_kind) == BEHAVIOR_BOSS:
		return "boss"
	if String(profile.behavior_kind) == BEHAVIOR_SHOOTER or String(profile.behavior_kind) == BEHAVIOR_REPAIR_DRONE:
		return "shooter"
	if String(profile.behavior_kind) == BEHAVIOR_SHIELD_DRONE:
		return "fast"
	if String(profile.behavior_kind) == BEHAVIOR_POWER_ARMOR:
		return "tank"
	if float(profile.crowd_weight) >= 4.0 or int(profile.max_health) >= 8 or float(profile.body_radius) >= 26.0:
		return "tank"
	if float(profile.speed) >= 120.0 or float(profile.body_radius) <= 14.0:
		return "fast"
	return "basic"


func _apply_knockback(packet) -> void:
	var effective_knockback: float = packet.knockback * _get_knockback_weight_response()
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


func _get_knockback_weight_response() -> float:
	return 1.0 / max(crowd_weight, MIN_KNOCKBACK_WEIGHT)


func _should_reduce_shield_pierce_damage(packet) -> bool:
	if packet == null or not is_projectile_shield_active():
		return false
	return bool(packet.pierces_projectile_shields) and String(packet.projectile_kind) != "hostile"


func _is_non_contact_specialist() -> bool:
	return behavior_kind == BEHAVIOR_REPAIR_DRONE or behavior_kind == BEHAVIOR_SHIELD_DRONE or behavior_kind == BEHAVIOR_POWER_ARMOR or behavior_kind == BEHAVIOR_CYBER_SOLDIER or behavior_kind == BEHAVIOR_COMMISSAR


func _is_ranged_behavior() -> bool:
	return behavior_kind == BEHAVIOR_SHOOTER or behavior_kind == BEHAVIOR_BOSS or _is_non_contact_specialist()


func _uses_agent_character_art() -> bool:
	return _is_agent_boss() or behavior_kind == BEHAVIOR_CYBER_SOLDIER


func _configure_cyber_soldier_state() -> void:
	_agent_aim_direction = Vector2.RIGHT
	_agent_last_move_facing_direction = Vector2.DOWN
	_agent_walk_cycle = 0.0
	_agent_shoot_pose_remaining = 0.0
	_agent_teleport_target = Vector2.INF
	_agent_teleport_cast_remaining = 0.0
	_agent_teleport_cast_duration = 0.0
	_behavior_reposition_target = Vector2.INF
	_behavior_reposition_recovery_remaining = 0.0
	_behavior_special_timer = max(special_cooldown * 0.78, 0.35)
	_agent_zigzag_sign = -1.0 if int(get_instance_id() % 2) == 0 else 1.0


func _update_repair_drone(delta: float, to_target: Vector2) -> Vector2:
	_repair_cooldown_remaining = max(_repair_cooldown_remaining - delta, 0.0)
	if is_rogue_horde_enemy():
		_repair_target = null
		return _get_panicked_repair_drone_velocity(to_target)
	var has_repair_target := _repair_target_is_valid()
	if has_repair_target:
		var to_repair_target: Vector2 = _repair_target.global_position - global_position
		var repair_distance: float = to_repair_target.length()
		if repair_distance <= repair_radius and not _wall_blocks_segment(global_position, _repair_target.global_position):
			_try_emit_repair_pulse()
			if to_target.length() < preferred_distance * 0.72:
				return _get_slippery_escape_velocity(to_target, speed)
			return to_repair_target.orthogonal().normalized() * _strafe_sign * strafe_speed
		var steering_target := _get_path_steering_target(_repair_target.global_position)
		var to_steering := steering_target - global_position
		var repair_velocity := Vector2.ZERO
		if to_steering.length_squared() > 4.0:
			repair_velocity = to_steering.normalized() * speed
		if to_target.length() < preferred_distance * 0.62:
			repair_velocity += _get_slippery_escape_velocity(to_target, speed * 0.85)
		return repair_velocity.limit_length(speed)
	if is_orphaned_horde_enemy():
		return _get_panicked_repair_drone_velocity(to_target)
	if _tactical_target_position != Vector2.INF:
		var to_order: Vector2 = _tactical_target_position - global_position
		if to_order.length_squared() > 32.0 * 32.0:
			var steering_target: Vector2 = _get_path_steering_target(_tactical_target_position)
			var to_steering: Vector2 = steering_target - global_position
			if to_steering.length_squared() > 4.0:
				var ordered_velocity: Vector2 = to_steering.normalized() * speed
				if to_target.length() < preferred_distance * 0.62:
					ordered_velocity += _get_slippery_escape_velocity(to_target, speed * 0.7)
				return ordered_velocity.limit_length(speed)
	_try_emit_shot(to_target)
	return _get_slippery_ranged_velocity(to_target, speed)


func _get_panicked_repair_drone_velocity(to_target: Vector2) -> Vector2:
	var flee_direction := -_get_target_direction(to_target)
	if _panic_source_position != Vector2.INF:
		var from_fear_source: Vector2 = global_position - _panic_source_position
		if from_fear_source.length_squared() > 4.0:
			flee_direction = (flee_direction + from_fear_source.normalized() * 1.35).normalized()
	var side_sign := -1.0 if int(get_instance_id()) % 2 == 0 else 1.0
	flee_direction = (flee_direction + flee_direction.orthogonal() * side_sign * 0.28).normalized()
	return _get_agent_path_velocity_for_direction(flee_direction, max(preferred_distance, 190.0), speed)


func has_active_repair_target() -> bool:
	return _repair_target_is_valid()


func _repair_target_is_valid() -> bool:
	var target := _repair_target as Node2D
	if target == null or not is_instance_valid(target):
		return false
	if target == self:
		return false
	if not target.is_in_group("enemies") and not target.is_in_group("spawners"):
		return false
	if not target.has_method("apply_healing"):
		return false
	var target_health: int = int(target.get("health"))
	var target_max_health: int = int(target.get("max_health"))
	if target_health <= 0 or target_max_health <= 0 or target_health >= target_max_health:
		return false
	var health_ratio: float = float(target_health) / float(max(target_max_health, 1))
	return health_ratio <= clamp(repair_target_health_ratio, 0.0, 1.0)


func _try_emit_repair_pulse() -> void:
	if _repair_cooldown_remaining > 0.0 or not _repair_target_is_valid():
		return
	repair_ready.emit(self, _repair_target, max(repair_amount, 1))
	_repair_cooldown_remaining = max(repair_cooldown, 0.1)
	_repair_beam_remaining = 0.24
	queue_redraw()


func _update_shield_drone(delta: float, to_target: Vector2) -> Vector2:
	if _behavior_reposition_target != Vector2.INF:
		return _update_shield_drone_dash(to_target)
	if _behavior_reposition_recovery_remaining > 0.0:
		return _update_shield_drone_stationary_fire(delta, to_target)
	if _update_behavior_burst(delta):
		if _behavior_burst_shots_remaining > 0:
			activate_projectile_shield(0.06)
		else:
			_projectile_shield_remaining = 0.0
		return Vector2.ZERO
	_behavior_special_timer = max(_behavior_special_timer - delta, 0.0)
	if _behavior_special_timer <= 0.0:
		if special_movement_kind == "dash" and _try_start_shield_drone_dash(to_target):
			return Vector2.ZERO
		if _has_clear_player_shot(to_target):
			_start_shield_drone_stationary_fire(to_target)
		else:
			_behavior_special_timer = max(special_cooldown * 0.45, 0.3)
	return _get_slippery_ranged_velocity(to_target, speed)


func _try_start_shield_drone_dash(to_target: Vector2) -> bool:
	if to_target.length_squared() <= 4.0:
		return false
	var dash_distance: float = clamp(preferred_distance * 0.68, 150.0, 240.0)
	var target: Vector2 = _pick_shield_drone_dash_target(to_target, dash_distance)
	if target == Vector2.INF:
		return false
	_behavior_reposition_target = target
	_behavior_reposition_attack_pending = false
	_behavior_dash_steps_remaining = _get_shield_drone_dash_count(to_target)
	_behavior_special_timer = max(special_cooldown, 0.28)
	_projectile_shield_remaining = 0.0
	_projectile_shield_block_flash_remaining = 0.0
	_agent_zigzag_sign *= -1.0
	return true


func _update_shield_drone_dash(to_target: Vector2) -> Vector2:
	_projectile_shield_remaining = 0.0
	_projectile_shield_block_flash_remaining = 0.0
	var to_dash: Vector2 = _behavior_reposition_target - global_position
	if to_dash.length_squared() <= 16.0 * 16.0 or _path_blocks_segment(global_position, _behavior_reposition_target, body_radius * 0.55):
		_behavior_dash_steps_remaining -= 1
		if _behavior_dash_steps_remaining > 0:
			_agent_zigzag_sign *= -1.0
			var next_target: Vector2 = _pick_shield_drone_dash_target(to_target, clamp(preferred_distance * 0.68, 150.0, 240.0))
			if next_target != Vector2.INF:
				_behavior_reposition_target = next_target
				return Vector2.ZERO
		_behavior_reposition_target = Vector2.INF
		_behavior_dash_steps_remaining = 0
		_start_shield_drone_stationary_fire(to_target)
		return Vector2.ZERO
	_update_visual_direction(to_dash)
	return to_dash.normalized() * max(speed * 3.1, 420.0)


func _start_shield_drone_stationary_fire(to_target: Vector2) -> void:
	_behavior_reposition_recovery_remaining = _get_shield_drone_stationary_seconds(to_target)
	_behavior_reposition_attack_pending = true
	activate_projectile_shield(max(_behavior_reposition_recovery_remaining, 0.06))
	queue_redraw()


func _update_shield_drone_stationary_fire(delta: float, to_target: Vector2) -> Vector2:
	_behavior_reposition_recovery_remaining = max(_behavior_reposition_recovery_remaining - delta, 0.0)
	if _behavior_reposition_recovery_remaining > 0.0 or _behavior_reposition_attack_pending or _behavior_burst_shots_remaining > 0:
		activate_projectile_shield(max(_behavior_reposition_recovery_remaining, 0.06))
	if _behavior_reposition_attack_pending and _has_clear_player_shot(to_target):
		_emit_shield_drone_attack(to_target)
	if _update_behavior_burst(delta):
		if _behavior_reposition_recovery_remaining > 0.0 or _behavior_burst_shots_remaining > 0:
			activate_projectile_shield(max(_behavior_reposition_recovery_remaining, 0.06))
		else:
			_projectile_shield_remaining = 0.0
		return Vector2.ZERO
	if _behavior_reposition_recovery_remaining <= 0.0:
		_behavior_reposition_attack_pending = false
		_projectile_shield_remaining = 0.0
	return Vector2.ZERO


func _emit_shield_drone_attack(to_target: Vector2) -> void:
	_behavior_reposition_attack_pending = false
	if not _has_clear_player_shot(to_target):
		_behavior_special_timer = max(special_cooldown * 0.45, 0.3)
		return
	if _behavior_pattern_index % 2 == 0:
		_start_behavior_burst(to_target, {
			"count": 3,
			"interval": 0.075,
			"speed": max(projectile_speed * 1.12, 320.0),
			"damage": projectile_damage,
			"radius": max(projectile_radius * 0.78, 4.4),
			"kind": "hostile_burst",
			"lifetime": 1.1
		})
	else:
		var shot_direction: Vector2 = to_target.normalized()
		_emit_enemy_projectile(shot_direction, max(projectile_speed * 1.28, 360.0), projectile_damage, max(projectile_radius * 0.72, 4.2), 1, 0.0, 1.05, "hostile")
	_behavior_pattern_index += 1
	_behavior_special_timer = max(special_cooldown, 0.28)


func _get_shield_drone_dash_count(to_target: Vector2) -> int:
	var distance: float = to_target.length()
	var variant: int = int(abs(int(get_instance_id()) + _behavior_pattern_index)) % 3
	if distance > preferred_distance + distance_band:
		return 2 + int(variant % 2)
	if distance < preferred_distance - distance_band:
		return 1 + int(variant % 2)
	return 1 + variant


func _get_shield_drone_stationary_seconds(to_target: Vector2) -> float:
	var distance: float = to_target.length()
	var variant: float = float(int(abs(int(get_instance_id()) + _behavior_pattern_index * 17)) % 100) / 100.0
	if distance > preferred_distance + distance_band:
		return clamp(max(special_telegraph_seconds, 0.12) + lerp(0.08, 0.2, variant), 0.18, 0.42)
	if distance < preferred_distance - distance_band:
		return clamp(max(special_telegraph_seconds, 0.12) + lerp(0.06, 0.16, variant), 0.16, 0.36)
	return clamp(max(special_telegraph_seconds, 0.12) + lerp(0.22, 0.42, variant), 0.34, 0.68)


func _pick_shield_drone_dash_target(to_target: Vector2, distance: float) -> Vector2:
	var directions: Array[Vector2] = _get_shield_drone_dash_directions(to_target)
	for direction in directions:
		if direction.length_squared() <= 0.001:
			continue
		var candidate: Vector2 = global_position + direction.normalized() * distance
		candidate = _constrain_to_playable(candidate)
		if _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.55):
			return candidate
	for direction in directions:
		if direction.length_squared() <= 0.001:
			continue
		var candidate: Vector2 = global_position + direction.normalized() * distance * 0.55
		candidate = _constrain_to_playable(candidate)
		if _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.55):
			return candidate
	return Vector2.INF


func _get_shield_drone_dash_directions(to_target: Vector2) -> Array[Vector2]:
	var target_direction: Vector2 = _get_target_direction(to_target)
	var side_direction: Vector2 = target_direction.orthogonal() * _agent_zigzag_sign
	var distance: float = to_target.length()
	if distance > preferred_distance + distance_band:
		return [
			target_direction,
			(target_direction + side_direction * 0.55).normalized(),
			(target_direction - side_direction * 0.55).normalized(),
			side_direction,
			-side_direction,
			-target_direction
		]
	if distance < preferred_distance - distance_band:
		return [
			side_direction,
			-side_direction,
			(-target_direction + side_direction * 0.55).normalized(),
			(-target_direction - side_direction * 0.55).normalized(),
			-target_direction,
			target_direction
		]
	return [
		side_direction,
		-side_direction,
		(side_direction + target_direction * 0.35).normalized(),
		(-side_direction + target_direction * 0.35).normalized(),
		target_direction,
		-target_direction
	]


func _update_power_armor(delta: float, to_target: Vector2) -> Vector2:
	if _boss_minigun_remaining > 0.0:
		_update_boss_minigun(delta)
		return _get_power_armor_special_velocity(to_target)
	if _boss_autocannon_shots_remaining > 0:
		_update_boss_autocannon(delta, to_target)
		return _get_power_armor_special_velocity(to_target)
	if _boss_special_telegraph_remaining > 0.0:
		_boss_special_telegraph_remaining = max(_boss_special_telegraph_remaining - delta, 0.0)
		if _boss_special_telegraph_remaining <= 0.0:
			if _boss_special_kind == "minigun":
				_start_boss_minigun(to_target)
			elif _boss_special_kind == "autocannon":
				_start_boss_autocannon(to_target)
			else:
				_emit_boss_special(to_target)
				_finish_boss_special()
		queue_redraw()
		return _get_power_armor_special_velocity(to_target)
	_boss_special_timer = max(_boss_special_timer - delta, 0.0)
	if _boss_special_timer <= 0.0 and _has_clear_player_shot(to_target):
		_boss_special_kind = _pick_power_armor_attack_kind()
		if _boss_special_kind == "minigun":
			_prepare_boss_minigun_start_side()
		_boss_special_telegraph_duration = max(special_telegraph_seconds, 0.18)
		_boss_special_telegraph_remaining = _boss_special_telegraph_duration
		queue_redraw()
		return _get_power_armor_special_velocity(to_target)
	if is_general():
		_try_emit_shot(to_target)
	return _get_ranged_velocity(to_target) * 0.72


func _update_commissar(delta: float, to_target: Vector2) -> Vector2:
	if commissar_program == null:
		_try_emit_shot(to_target)
		return _get_ranged_velocity(to_target) * 0.72
	_commissar_shield_cooldown_remaining = max(_commissar_shield_cooldown_remaining - delta, 0.0)
	_commissar_charge_cooldown_remaining = max(_commissar_charge_cooldown_remaining - delta, 0.0)
	if _commissar_execution_target != null:
		return _update_commissar_execution(delta, to_target)
	if _commissar_charge_telegraph_remaining > 0.0:
		_commissar_charge_telegraph_remaining = max(_commissar_charge_telegraph_remaining - delta, 0.0)
		if _commissar_charge_telegraph_remaining <= 0.0:
			_commissar_charge_remaining = max(float(commissar_program.charge_duration), 0.1)
			_commissar_charge_push_available = true
		queue_redraw()
		return Vector2.ZERO
	if _commissar_charge_remaining > 0.0:
		_commissar_charge_remaining = max(_commissar_charge_remaining - delta, 0.0)
		if _commissar_charge_remaining <= 0.0:
			_commissar_charge_push_available = false
			_commissar_charge_cooldown_remaining = max(float(commissar_program.charge_cooldown), 0.1)
		queue_redraw()
		return _commissar_charge_direction * max(float(commissar_program.charge_speed), speed)
	if _commissar_reposition_target != Vector2.INF:
		var to_reposition: Vector2 = _commissar_reposition_target - global_position
		if to_reposition.length_squared() <= 22.0 * 22.0 or _path_blocks_segment(global_position, _commissar_reposition_target, body_radius * 0.55):
			_commissar_reposition_target = Vector2.INF
		else:
			var steering_target: Vector2 = _get_path_steering_target(_commissar_reposition_target)
			var to_steering: Vector2 = steering_target - global_position
			if to_steering.length_squared() > 4.0:
				return to_steering.normalized() * speed * max(float(commissar_program.reposition_speed_multiplier), 1.0)
	if _commissar_charge_cooldown_remaining <= 0.0 and to_target.length() <= max(float(commissar_program.charge_trigger_distance), body_radius * 3.0) and _has_clear_player_shot(to_target):
		_commissar_charge_direction = _get_target_direction(to_target)
		_commissar_charge_telegraph_remaining = max(float(commissar_program.charge_telegraph_seconds), 0.12)
		queue_redraw()
		return Vector2.ZERO
	_try_emit_commissar_heavy_shot(to_target)
	return _get_ranged_velocity(to_target) * 0.72


func _try_emit_commissar_heavy_shot(to_target: Vector2) -> void:
	if commissar_program == null or _shot_cooldown_remaining > 0.0 or not _has_clear_player_shot(to_target):
		return
	if _emit_enemy_projectile(
		to_target.normalized(),
		max(projectile_speed, 1.0),
		projectile_damage,
		projectile_radius,
		1,
		0.0,
		1.25,
		"hostile_commissar",
		max(float(commissar_program.heavy_shot_knockback), 0.0)
	):
		_shot_cooldown_remaining = max(shot_cooldown, 0.1)


func _try_activate_commissar_reactive_shield(packet) -> bool:
	if behavior_kind != BEHAVIOR_COMMISSAR or commissar_program == null or _commissar_execution_target != null:
		return false
	if _commissar_shield_cooldown_remaining > 0.0 or is_projectile_shield_active():
		return false
	if String(packet.projectile_kind).begins_with("hostile"):
		return false
	activate_projectile_shield(max(float(commissar_program.reactive_shield_seconds), 0.08))
	_commissar_shield_cooldown_remaining = max(float(commissar_program.reactive_shield_cooldown), 0.1)
	_commissar_reposition_target = _pick_behavior_reposition_target(target_position - global_position, max(float(commissar_program.reposition_distance), 48.0))
	_projectile_shield_block_flash_remaining = 0.24
	queue_redraw()
	return blocks_projectile_damage(packet)


func start_commissar_execution(target) -> bool:
	var execution_target := target as Node2D
	if behavior_kind != BEHAVIOR_COMMISSAR or commissar_program == null or execution_target == null or not is_instance_valid(execution_target):
		return false
	if health <= 0 or _is_dying or _commissar_execution_target != null:
		return false
	_commissar_execution_target = execution_target
	_commissar_execution_duration = max(float(commissar_program.execution_telegraph_seconds), 0.2)
	_commissar_execution_remaining = _commissar_execution_duration
	_commissar_charge_telegraph_remaining = 0.0
	_commissar_charge_remaining = 0.0
	_commissar_charge_push_available = false
	_commissar_reposition_target = Vector2.INF
	_projectile_shield_remaining = 0.0
	queue_redraw()
	return true


func _update_commissar_execution(delta: float, _to_target: Vector2) -> Vector2:
	if not is_instance_valid(_commissar_execution_target) or not _commissar_execution_target.is_in_group("enemies"):
		_clear_commissar_execution()
		return Vector2.ZERO
	_commissar_execution_remaining = max(_commissar_execution_remaining - delta, 0.0)
	if _commissar_execution_remaining <= 0.0:
		var completed_target := _commissar_execution_target
		_clear_commissar_execution()
		commissar_execution_ready.emit(self, completed_target)
	queue_redraw()
	return Vector2.ZERO


func _clear_commissar_execution() -> void:
	_commissar_execution_target = null
	_commissar_execution_remaining = 0.0
	_commissar_execution_duration = 0.0
	queue_redraw()


func is_commissar_charge_active() -> bool:
	return behavior_kind == BEHAVIOR_COMMISSAR and _commissar_charge_remaining > 0.0 and _commissar_charge_push_available


func consume_commissar_charge_push() -> Dictionary:
	if not is_commissar_charge_active() or commissar_program == null:
		return {}
	_commissar_charge_push_available = false
	_commissar_charge_remaining = 0.0
	_commissar_charge_cooldown_remaining = max(float(commissar_program.charge_cooldown), 0.1)
	return {
		"direction": _commissar_charge_direction,
		"force": max(float(commissar_program.charge_push_force), 0.0)
	}


func execute_for_cowardice() -> void:
	if health <= 0 or _is_dying:
		return
	set_meta("no_defeat_reward", true)
	set_meta("discipline_execution", true)
	_apply_damage_amount(health)


func retreat_from_combat() -> void:
	if health <= 0 or _is_dying:
		return
	set_meta("no_defeat_reward", true)
	set_meta("retreat_visual", true)
	_apply_damage_amount(health)


func _update_general_special(delta: float, to_target: Vector2) -> bool:
	if not is_general() or special_attack_kind.is_empty() or health <= 0 or _is_dying:
		return false
	if _update_behavior_burst(delta):
		return true
	_behavior_special_timer = max(_behavior_special_timer - delta, 0.0)
	if _behavior_special_timer > 0.0 or to_target.length_squared() <= 4.0 or not _has_clear_player_shot(to_target):
		return false
	match special_attack_kind:
		"spread":
			_emit_enemy_projectile(
				to_target.normalized(),
				projectile_speed,
				projectile_damage,
				projectile_radius,
				3,
				max(shot_spread_degrees, 30.0),
				1.2,
				"hostile"
			)
		"rapid":
			_start_behavior_burst(to_target, {
				"count": 4,
				"interval": 0.08,
				"speed": projectile_speed,
				"damage": projectile_damage,
				"radius": projectile_radius,
				"kind": "hostile_burst",
				"lifetime": 1.15
			})
		_:
			return false
	_behavior_special_timer = max(special_cooldown, 0.2)
	return true


func _pick_power_armor_attack_kind() -> String:
	if not secondary_attack_kind.is_empty() and _boss_special_sequence_index % 3 == 2:
		return secondary_attack_kind
	if special_attack_kind.is_empty():
		return "minigun"
	return special_attack_kind


func _get_power_armor_special_velocity(to_target: Vector2) -> Vector2:
	return _get_ranged_velocity(to_target) * 0.28


func _update_cyber_soldier(delta: float, to_target: Vector2) -> Vector2:
	if _agent_shoot_pose_remaining > 0.0:
		_agent_shoot_pose_remaining = max(_agent_shoot_pose_remaining - delta, 0.0)
	if _behavior_reposition_recovery_remaining > 0.0:
		_behavior_reposition_recovery_remaining = max(_behavior_reposition_recovery_remaining - delta, 0.0)
		_agent_aim_at_target(to_target)
		return Vector2.ZERO
	if _agent_teleport_cast_remaining > 0.0:
		_update_cyber_teleport_cast(delta, to_target)
		return Vector2.ZERO
	if _behavior_reposition_target != Vector2.INF:
		return _update_cyber_dash(to_target)
	if _update_behavior_burst(delta):
		_agent_aim_at_target(to_target)
		return _get_ranged_velocity(to_target) * 0.55
	_behavior_special_timer = max(_behavior_special_timer - delta, 0.0)
	if _behavior_special_timer <= 0.0 and _try_start_cyber_reposition(to_target):
		return Vector2.ZERO
	_try_emit_cyber_shot(to_target)
	_agent_aim_at_target(to_target)
	return _get_ranged_velocity(to_target)


func _try_start_cyber_reposition(to_target: Vector2) -> bool:
	if special_movement_kind.is_empty() or to_target.length_squared() <= 4.0:
		_behavior_special_timer = max(special_cooldown, 0.4)
		return false
	var target: Vector2 = _pick_behavior_reposition_target(to_target, max(preferred_distance, 220.0))
	if target == Vector2.INF:
		_behavior_special_timer = max(special_cooldown * 0.5, 0.35)
		return false
	if special_movement_kind == "teleport":
		_agent_teleport_target = target
		_agent_teleport_cast_duration = max(special_telegraph_seconds, 0.12)
		_agent_teleport_cast_remaining = _agent_teleport_cast_duration
		_agent_aim_at_target(to_target)
		queue_redraw()
	else:
		_behavior_reposition_target = target
		_agent_aim_at_target(to_target)
	return true


func _update_cyber_teleport_cast(delta: float, to_target: Vector2) -> void:
	_agent_teleport_cast_remaining = max(_agent_teleport_cast_remaining - delta, 0.0)
	_agent_aim_at_target(to_target)
	if _agent_teleport_cast_remaining > 0.0:
		queue_redraw()
		return
	if _agent_teleport_target != Vector2.INF:
		global_position = _constrain_to_playable(_agent_teleport_target)
	_agent_teleport_target = Vector2.INF
	_agent_teleport_cast_duration = 0.0
	_behavior_reposition_recovery_remaining = 0.24
	_behavior_special_timer = max(special_cooldown, 0.4)
	_invalidate_path_cache()
	queue_redraw()


func _update_cyber_dash(to_target: Vector2) -> Vector2:
	var to_dash: Vector2 = _behavior_reposition_target - global_position
	if to_dash.length_squared() <= 18.0 * 18.0 or _path_blocks_segment(global_position, _behavior_reposition_target, body_radius * 0.55):
		_behavior_reposition_target = Vector2.INF
		_behavior_reposition_recovery_remaining = 0.18
		_behavior_special_timer = max(special_cooldown, 0.4)
		return Vector2.ZERO
	_agent_aim_at_target(to_target)
	return to_dash.normalized() * max(speed * 3.15, 280.0)


func _try_emit_cyber_shot(to_target: Vector2) -> void:
	if _shot_cooldown_remaining > 0.0 or not _has_clear_player_shot(to_target):
		return
	var shot_direction: Vector2 = to_target.normalized()
	match _behavior_pattern_index % 4:
		1:
			_start_behavior_burst(to_target, {
				"count": 3,
				"interval": 0.08,
				"speed": max(projectile_speed * 1.08, 310.0),
				"damage": projectile_damage,
				"radius": max(projectile_radius * 0.82, 4.8),
				"kind": "hostile_assault",
				"lifetime": 1.14
			})
			_shot_cooldown_remaining = max(shot_cooldown * 1.25, 0.28)
		2:
			_emit_enemy_projectile(shot_direction, max(projectile_speed * 1.02, 285.0), projectile_damage, projectile_radius, 3, 30.0, 1.25, "hostile_scatter")
			_shot_cooldown_remaining = max(shot_cooldown * 1.18, 0.3)
		3:
			_emit_enemy_projectile(shot_direction, max(projectile_speed * 1.32, 360.0), projectile_damage, max(projectile_radius * 0.76, 4.4), 1, 0.0, 1.05, "hostile")
			_shot_cooldown_remaining = max(shot_cooldown * 0.62, 0.18)
		_:
			_emit_enemy_projectile(shot_direction, projectile_speed, projectile_damage, projectile_radius, 1, 0.0, 1.2, "hostile")
			_shot_cooldown_remaining = max(shot_cooldown, 0.24)
	_behavior_pattern_index += 1


func _start_behavior_burst(to_target: Vector2, burst_config: Dictionary) -> void:
	if to_target.length_squared() <= 4.0:
		return
	_behavior_burst_shots_remaining = max(int(burst_config.get("count", 3)), 1)
	_behavior_burst_interval_remaining = 0.0
	_behavior_burst_base_direction = to_target.normalized()
	_behavior_burst_config = burst_config.duplicate()
	_update_behavior_burst(0.0)


func _update_behavior_burst(delta: float) -> bool:
	if _behavior_burst_shots_remaining <= 0:
		return false
	_behavior_burst_interval_remaining -= delta
	var was_active := true
	var emitted_count := 0
	while _behavior_burst_shots_remaining > 0 and _behavior_burst_interval_remaining <= 0.0 and emitted_count < 3:
		var jitter: float = float(_behavior_burst_config.get("jitter_degrees", 4.0))
		var direction: Vector2 = _behavior_burst_base_direction.rotated(deg_to_rad(sin(float(_behavior_burst_shots_remaining) * 2.17) * jitter)).normalized()
		_emit_enemy_projectile(
			direction,
			float(_behavior_burst_config.get("speed", projectile_speed)),
			int(_behavior_burst_config.get("damage", projectile_damage)),
			float(_behavior_burst_config.get("radius", projectile_radius)),
			1,
			0.0,
			float(_behavior_burst_config.get("lifetime", 1.1)),
			String(_behavior_burst_config.get("kind", "hostile_burst"))
		)
		_behavior_burst_shots_remaining -= 1
		_behavior_burst_interval_remaining += max(float(_behavior_burst_config.get("interval", 0.08)), 0.025)
		emitted_count += 1
	if _behavior_burst_shots_remaining <= 0:
		_behavior_burst_config.clear()
	return was_active


func _pick_behavior_reposition_target(to_target: Vector2, distance: float) -> Vector2:
	var directions: Array[Vector2] = _get_behavior_reposition_directions(to_target)
	for direction in directions:
		if direction.length_squared() <= 0.001:
			continue
		var candidate: Vector2 = global_position + direction.normalized() * distance
		candidate = _constrain_to_playable(candidate)
		if not _agent_point_is_valid(candidate):
			continue
		if _path_blocks_segment(global_position, candidate, body_radius * 0.55):
			continue
		return candidate
	for direction in directions:
		if direction.length_squared() <= 0.001:
			continue
		var candidate: Vector2 = global_position + direction.normalized() * distance * 0.55
		candidate = _constrain_to_playable(candidate)
		if _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.55):
			return candidate
	return Vector2.INF


func _get_behavior_reposition_directions(to_target: Vector2) -> Array[Vector2]:
	var target_direction: Vector2 = _get_target_direction(to_target)
	var side_direction: Vector2 = target_direction.orthogonal() * _agent_zigzag_sign
	return [
		side_direction,
		-side_direction,
		(side_direction - target_direction * 0.35).normalized(),
		(-side_direction - target_direction * 0.35).normalized(),
		-target_direction,
		target_direction
	]


func _get_slippery_ranged_velocity(to_target: Vector2, movement_speed: float) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	var distance: float = to_target.length()
	var target_direction: Vector2 = to_target / distance
	var preferred_direction := target_direction.orthogonal() * _strafe_sign
	if distance < preferred_distance - distance_band:
		preferred_direction = _get_retreat_or_strafe_direction(target_direction, preferred_distance)
	elif distance > preferred_distance + distance_band and not _wall_blocks_segment(global_position, target_position):
		preferred_direction = (target_direction + preferred_direction * 0.55).normalized()
	return _get_agent_path_velocity_for_direction(preferred_direction, max(preferred_distance * 0.7, 120.0), max(movement_speed, 0.0))


func _get_slippery_escape_velocity(to_target: Vector2, movement_speed: float) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	var target_direction: Vector2 = to_target.normalized()
	var escape_direction := _get_retreat_or_strafe_direction(target_direction, max(preferred_distance, 120.0))
	return _get_agent_path_velocity_for_direction(escape_direction, max(preferred_distance, 120.0), max(movement_speed, 0.0))


func _has_clear_player_shot(to_target: Vector2) -> bool:
	if to_target.length_squared() <= 4.0:
		return false
	var shot_direction: Vector2 = to_target.normalized()
	var shot_origin := global_position + shot_direction * (body_radius + projectile_radius + 4.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return false
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return false
	return true


func _emit_enemy_projectile(shot_direction: Vector2, shot_speed: float, damage: int, radius: float, projectile_count: int, spread_degrees: float, lifetime: float, kind: String, knockback: float = 0.0) -> bool:
	if shot_direction.length_squared() <= 0.001:
		return false
	var normalized_direction: Vector2 = shot_direction.normalized()
	var shot_radius: float = max(radius, 1.0)
	var shot_origin := global_position + normalized_direction * (body_radius + shot_radius + 4.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return false
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return false
	var shot_config := {
		"speed": max(shot_speed, 1.0),
		"damage": max(damage, 1),
		"radius": shot_radius,
		"kind": kind,
		"projectile_count": max(projectile_count, 1),
		"spread_angle_degrees": max(spread_degrees, 0.0),
		"knockback": max(knockback, 0.0)
	}
	if lifetime > 0.0:
		shot_config["lifetime"] = lifetime
	shot_ready.emit(self, shot_origin, normalized_direction, shot_config)
	if _uses_agent_character_art():
		_play_agent_shoot_pose(normalized_direction)
	return true


func _is_agent_boss() -> bool:
	return behavior_kind == "boss" and agent_program != null


func _configure_agent_boss_state() -> void:
	var generation_seed: int = int(agent_program.generation_seed) if agent_program != null and agent_program.get("generation_seed") != null else int(get_instance_id())
	_agent_rng.seed = max(generation_seed, 1)
	_agent_action_kind = ""
	_agent_action_remaining = 0.0
	_agent_intro_pending = false
	_agent_intro_remaining = 0.0
	_agent_next_shot_remaining = 0.0
	_agent_burst_interval_remaining = 0.0
	_agent_burst_shots_remaining = 0
	_agent_burst_base_direction = Vector2.RIGHT
	_agent_action_direction = Vector2.ZERO
	_agent_tactical_target = Vector2.INF
	_agent_high_explosive_cooldown_remaining = 0.0
	_agent_high_explosive_roll_pending = false
	_clear_agent_high_explosive_windup()
	_agent_mine_sequence_remaining = 0
	_agent_mine_sequence_interval_remaining = 0.0
	_agent_mine_sequence_direction = Vector2.RIGHT
	_agent_special_cooldown_remaining = 0.0
	_agent_special_chain_count = 0
	_agent_special_attack_emitted = false
	_agent_special_stage = ""
	_agent_special_telegraph_remaining = 0.0
	_agent_teleport_target = Vector2.INF
	_agent_teleport_cast_remaining = 0.0
	_agent_teleport_cast_duration = 0.0
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
	if _agent_intro_pending:
		_agent_aim_at_target(to_target)
		queue_redraw()
		return Vector2.ZERO
	if _agent_intro_remaining > 0.0:
		_agent_intro_remaining = max(_agent_intro_remaining - delta, 0.0)
		_agent_aim_at_target(to_target)
		queue_redraw()
		return Vector2.ZERO
	if _agent_high_explosive_cooldown_remaining > 0.0:
		_agent_high_explosive_cooldown_remaining = max(_agent_high_explosive_cooldown_remaining - delta, 0.0)
	if _agent_mine_sequence_interval_remaining > 0.0:
		_agent_mine_sequence_interval_remaining = max(_agent_mine_sequence_interval_remaining - delta, 0.0)
	if _agent_special_cooldown_remaining > 0.0:
		_agent_special_cooldown_remaining = max(_agent_special_cooldown_remaining - delta, 0.0)
	if _agent_shoot_pose_remaining > 0.0:
		_agent_shoot_pose_remaining = max(_agent_shoot_pose_remaining - delta, 0.0)
	if _agent_charge_remaining > 0.0:
		return _update_agent_charge(delta, to_target)
	if _agent_special_stage == AGENT_SPECIAL_STAGE_TELEPORT_CAST:
		_update_agent_teleport_cast(delta, to_target)
		return Vector2.ZERO
	if _agent_stream_remaining > 0.0:
		_update_agent_special_stream(delta)
		return Vector2.ZERO
	if _agent_special_stage == AGENT_SPECIAL_STAGE_TELEGRAPH:
		_agent_special_telegraph_remaining = max(_agent_special_telegraph_remaining - delta, 0.0)
		_agent_aim_at_target(to_target)
		if _agent_special_telegraph_remaining <= 0.0:
			_emit_agent_special_attack(to_target)
			if _agent_stream_remaining <= 0.0:
				_finish_agent_special_action()
		queue_redraw()
		return Vector2.ZERO
	if _agent_special_stage == AGENT_SPECIAL_STAGE_MOVE and _get_agent_special_movement_verb() == AgentBossProgram.SPECIAL_MOVEMENT_DASH_CHAIN:
		return _update_agent_dash_chain(delta, to_target)
	if _agent_action_remaining <= 0.0 or _agent_action_kind.is_empty():
		_start_next_agent_action(to_target)
	_agent_action_remaining = max(_agent_action_remaining - delta, 0.0)
	if _agent_next_shot_remaining > 0.0:
		_agent_next_shot_remaining = max(_agent_next_shot_remaining - delta, 0.0)
	if _agent_burst_interval_remaining > 0.0:
		_agent_burst_interval_remaining = max(_agent_burst_interval_remaining - delta, 0.0)
	match _agent_action_kind:
		AGENT_ACTION_SLOW:
			_update_agent_slow_pressure_shots(to_target)
			return _get_agent_slow_velocity(to_target)
		AGENT_ACTION_NORMAL:
			var high_explosive_busy: bool = _update_agent_normal_high_explosive(delta, to_target)
			if not high_explosive_busy:
				_try_emit_agent_standard_shot(to_target, float(agent_program.normal_shot_cooldown), float(agent_program.normal_projectile_speed), projectile_damage, float(agent_program.normal_projectile_radius))
			return _get_agent_normal_velocity(to_target)
		AGENT_ACTION_SPECIAL:
			return _update_agent_special_movement(delta, to_target)
	return Vector2.ZERO


func _start_next_agent_action(to_target: Vector2) -> void:
	var slow_weight: float = max(float(agent_program.slow_action_weight), 0.0)
	var normal_weight: float = max(float(agent_program.normal_action_weight), 0.0)
	var special_weight: float = max(float(agent_program.special_action_weight), 0.0) if _agent_special_cooldown_remaining <= 0.0 else 0.0
	var total_weight: float = slow_weight + normal_weight + special_weight
	if total_weight <= 0.0:
		_agent_action_kind = AGENT_ACTION_NORMAL
	else:
		var roll: float = _agent_rng.randf() * total_weight
		if roll < slow_weight:
			_agent_action_kind = AGENT_ACTION_SLOW
		elif roll < slow_weight + normal_weight:
			_agent_action_kind = AGENT_ACTION_NORMAL
		else:
			_agent_action_kind = AGENT_ACTION_SPECIAL
	_agent_tactical_target = Vector2.INF
	_agent_special_stage = ""
	_agent_action_direction = _pick_agent_valid_direction(_get_target_direction(to_target), float(agent_program.normal_tactical_distance))
	match _agent_action_kind:
		AGENT_ACTION_SLOW:
			_agent_special_chain_count = 0
			_agent_high_explosive_roll_pending = false
			_clear_agent_mine_sequence()
			_clear_agent_high_explosive_windup()
			_agent_action_remaining = max(float(agent_program.slow_action_seconds), 0.2)
			_agent_action_direction = _pick_agent_valid_direction(_get_agent_slow_personality_direction(to_target), float(agent_program.normal_tactical_distance) * 0.55)
			_agent_next_shot_remaining = min(_agent_next_shot_remaining, 0.08)
		AGENT_ACTION_NORMAL:
			_agent_special_chain_count = 0
			_clear_agent_slow_fire_state()
			_clear_agent_high_explosive_windup()
			_agent_high_explosive_roll_pending = true
			_agent_action_remaining = max(float(agent_program.normal_action_seconds), 0.25)
			_agent_zigzag_sign *= -1.0
			_agent_action_direction = _get_agent_normal_preferred_direction(to_target)
			_agent_next_shot_remaining = min(_agent_next_shot_remaining, 0.18)
		AGENT_ACTION_SPECIAL:
			_clear_agent_slow_fire_state()
			_agent_high_explosive_roll_pending = false
			_clear_agent_mine_sequence()
			_clear_agent_high_explosive_windup()
			_agent_action_remaining = 5.0
			_start_agent_special_movement(to_target)
	queue_redraw()


func _finish_agent_action() -> void:
	_agent_action_kind = ""
	_agent_action_remaining = 0.0
	_agent_action_direction = Vector2.ZERO
	_agent_tactical_target = Vector2.INF
	_clear_agent_slow_fire_state()
	_agent_high_explosive_roll_pending = false
	_clear_agent_mine_sequence()
	_clear_agent_high_explosive_windup()
	_agent_special_stage = ""
	_agent_special_telegraph_remaining = 0.0
	_agent_teleport_target = Vector2.INF
	_agent_teleport_cast_remaining = 0.0
	_agent_teleport_cast_duration = 0.0
	_agent_dash_steps_remaining = 0
	_agent_charge_remaining = 0.0
	_agent_charge_elapsed = 0.0
	_agent_charge_special_fired = false
	_agent_stream_kind = ""
	_agent_stream_remaining = 0.0
	_agent_stream_elapsed = 0.0
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0
	_agent_special_attack_emitted = false


func _finish_agent_special_action() -> void:
	var completed_chain_count: int = clampi(_agent_special_chain_count, 1, max(int(agent_program.max_special_chain_count), 1))
	if _agent_special_attack_emitted and _should_chain_agent_special(completed_chain_count):
		_clear_agent_special_action_state()
		_agent_action_kind = AGENT_ACTION_SPECIAL
		_agent_action_remaining = 5.0
		_start_agent_special_movement(target_position - global_position)
		return
	_agent_special_cooldown_remaining = _get_agent_special_cooldown_seconds(completed_chain_count)
	_agent_special_chain_count = 0
	_finish_agent_action()


func _should_chain_agent_special(completed_chain_count: int) -> bool:
	var max_chain_count: int = max(int(agent_program.max_special_chain_count), 1)
	if completed_chain_count >= max_chain_count:
		return false
	var chance: float = clamp(float(agent_program.special_chain_chance) - float(completed_chain_count - 1) * float(agent_program.special_chain_chance_decay), 0.0, 1.0)
	return _agent_rng.randf() < chance


func _get_agent_special_cooldown_seconds(completed_chain_count: int) -> float:
	var chain_count: int = max(completed_chain_count, 1)
	var base_cooldown: float = max(float(agent_program.special_base_cooldown_seconds), 0.0)
	var chain_bonus: float = max(float(agent_program.special_chain_cooldown_bonus_seconds), 0.0)
	return base_cooldown + chain_bonus * float(chain_count - 1)


func _clear_agent_special_action_state() -> void:
	_agent_tactical_target = Vector2.INF
	_agent_special_stage = ""
	_agent_special_telegraph_remaining = 0.0
	_agent_teleport_target = Vector2.INF
	_agent_teleport_cast_remaining = 0.0
	_agent_teleport_cast_duration = 0.0
	_agent_dash_steps_remaining = 0
	_agent_charge_remaining = 0.0
	_agent_charge_elapsed = 0.0
	_agent_charge_special_fired = false
	_clear_agent_stream_state()
	_agent_special_attack_emitted = false


func _clear_agent_slow_fire_state() -> void:
	_agent_burst_interval_remaining = 0.0
	_agent_burst_shots_remaining = 0
	_agent_burst_base_direction = Vector2.RIGHT


func _clear_agent_mine_sequence() -> void:
	_agent_mine_sequence_remaining = 0
	_agent_mine_sequence_interval_remaining = 0.0
	_agent_mine_sequence_direction = Vector2.RIGHT


func _clear_agent_high_explosive_windup() -> void:
	_agent_high_explosive_windup_kind = ""
	_agent_high_explosive_windup_remaining = 0.0
	_agent_high_explosive_windup_duration = 0.0
	_agent_high_explosive_windup_direction = Vector2.RIGHT
	_agent_high_explosive_windup_target = Vector2.INF


func _update_agent_normal_high_explosive(delta: float, to_target: Vector2) -> bool:
	if _agent_high_explosive_windup_remaining > 0.0:
		return _update_agent_high_explosive_windup(delta, to_target)
	if _agent_mine_sequence_remaining > 0:
		_try_emit_next_agent_mine()
		return true
	if not _agent_high_explosive_roll_pending or _agent_high_explosive_cooldown_remaining > 0.0:
		return false
	_agent_high_explosive_roll_pending = false
	if _agent_rng.randf() > clamp(float(agent_program.high_explosive_action_chance), 0.0, 1.0):
		return false
	_start_agent_high_explosive_windup(to_target)
	return true


func _start_agent_high_explosive_windup(to_target: Vector2) -> void:
	var direction: Vector2 = _get_target_direction(to_target)
	_agent_high_explosive_windup_kind = _get_agent_high_explosive_verb()
	_agent_high_explosive_windup_duration = max(float(agent_program.high_explosive_windup_seconds), 0.08)
	if _agent_high_explosive_windup_kind == AgentBossProgram.HIGH_EXPLOSIVE_ROCKET:
		_agent_high_explosive_windup_duration *= max(float(agent_program.high_explosive_rocket_windup_multiplier), 0.1)
	_agent_high_explosive_windup_remaining = _agent_high_explosive_windup_duration
	_agent_high_explosive_windup_direction = direction
	_agent_high_explosive_windup_target = target_position
	_agent_aim_at_target(to_target)
	queue_redraw()


func _update_agent_high_explosive_windup(delta: float, to_target: Vector2) -> bool:
	_agent_high_explosive_windup_remaining = max(_agent_high_explosive_windup_remaining - delta, 0.0)
	_agent_aim_at_target(to_target)
	if to_target.length_squared() > 4.0:
		_agent_high_explosive_windup_direction = to_target.normalized()
		_agent_high_explosive_windup_target = target_position
	if _agent_high_explosive_windup_remaining > 0.0:
		queue_redraw()
		return true
	var emitted: bool = _try_emit_agent_high_explosive(to_target)
	_clear_agent_high_explosive_windup()
	if emitted:
		_agent_high_explosive_cooldown_remaining = max(float(agent_program.high_explosive_cooldown_seconds), 0.1)
	return emitted


func _try_emit_agent_high_explosive(to_target: Vector2) -> bool:
	match _get_agent_high_explosive_verb():
		AgentBossProgram.HIGH_EXPLOSIVE_GRENADE:
			return _emit_agent_grenade(to_target)
		AgentBossProgram.HIGH_EXPLOSIVE_MINES:
			return _start_agent_mine_sequence(to_target)
		_:
			return _emit_agent_high_explosive_rocket(to_target)


func _emit_agent_high_explosive_rocket(to_target: Vector2) -> bool:
	if to_target.length_squared() <= 4.0:
		return false
	var shot_direction: Vector2 = to_target.normalized()
	var shot_radius: float = max(projectile_radius * 1.55, 10.5)
	var shot_origin: Vector2 = _get_agent_projectile_spawn_origin(shot_direction, shot_radius, 4.0)
	if shot_origin == Vector2.INF:
		return false
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return false
	var rocket_speed: float = max(float(agent_program.high_explosive_rocket_speed), 260.0)
	var target_position_at_launch: Vector2 = target_position
	var target_direction: Vector2 = target_position_at_launch - shot_origin
	if target_direction.length_squared() > 4.0:
		shot_direction = target_direction.normalized()
	var shot_config: Dictionary = {
		"speed": rocket_speed,
		"damage": max(projectile_damage + 1, 2),
		"radius": shot_radius,
		"kind": "rocket",
		"projectile_count": 1,
		"spread_angle_degrees": 0.0,
		"knockback": 520.0,
		"explosion_radius": max(float(agent_program.high_explosive_rocket_radius), 48.0),
		"explosion_damage_multiplier": 1.0,
		"target_position": target_position_at_launch,
		"show_target_reticle": true,
		"target_reticle_radius": max(float(agent_program.high_explosive_rocket_radius), 48.0),
		"lifetime": max(shot_origin.distance_to(target_position_at_launch) / rocket_speed, 0.08),
		"exact_lifetime": true
	}
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)
	_play_agent_shoot_pose(shot_direction)
	return true


func _emit_agent_grenade(to_target: Vector2) -> bool:
	if to_target.length_squared() <= 4.0:
		return false
	var shot_direction: Vector2 = to_target.normalized()
	var shot_radius: float = max(projectile_radius * 1.28, 9.0)
	var shot_origin: Vector2 = _get_agent_projectile_spawn_origin(shot_direction, shot_radius, 3.0)
	if shot_origin == Vector2.INF:
		return false
	var target_position_at_launch: Vector2 = _constrain_to_playable(target_position)
	var distance: float = max(shot_origin.distance_to(target_position_at_launch), 48.0)
	var base_speed: float = max(float(agent_program.high_explosive_grenade_speed), 120.0)
	var air_seconds: float = clamp(distance / base_speed, 0.42, max(float(agent_program.high_explosive_grenade_max_air_seconds), 0.45))
	var shot_speed: float = distance / air_seconds
	var target_direction: Vector2 = target_position_at_launch - shot_origin
	if target_direction.length_squared() > 4.0:
		shot_direction = target_direction.normalized()
	var shot_config: Dictionary = {
		"speed": shot_speed,
		"damage": max(projectile_damage, 1),
		"radius": shot_radius,
		"kind": "agent_grenade",
		"projectile_count": 1,
		"spread_angle_degrees": 0.0,
		"knockback": 390.0,
		"explosion_radius": max(float(agent_program.high_explosive_grenade_radius), 44.0),
		"explosion_damage_multiplier": 1.0,
		"target_position": target_position_at_launch,
		"show_target_reticle": true,
		"target_reticle_radius": max(float(agent_program.high_explosive_grenade_radius), 44.0),
		"lifetime": air_seconds,
		"exact_lifetime": true
	}
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)
	_play_agent_shoot_pose(shot_direction)
	return true


func _start_agent_mine_sequence(to_target: Vector2) -> bool:
	_agent_mine_sequence_direction = _get_target_direction(to_target)
	_agent_mine_sequence_remaining = clampi(int(agent_program.high_explosive_mine_count), 1, 5)
	_agent_mine_sequence_interval_remaining = 0.0
	_try_emit_next_agent_mine()
	return true


func _try_emit_next_agent_mine() -> void:
	if _agent_mine_sequence_remaining <= 0 or _agent_mine_sequence_interval_remaining > 0.0:
		return
	var mine_count: int = clampi(int(agent_program.high_explosive_mine_count), 1, 5)
	var mine_index: int = mine_count - _agent_mine_sequence_remaining
	var direction: Vector2 = _get_agent_mine_direction(mine_index)
	var trigger_radius: float = max(float(agent_program.high_explosive_mine_trigger_radius), 8.0)
	var throw_seconds: float = max(float(agent_program.high_explosive_mine_throw_seconds), 0.08)
	var placement_distance: float = max(float(agent_program.high_explosive_mine_throw_distance), body_radius + trigger_radius + 42.0) + float(mine_index) * 8.0
	var mine_position: Vector2 = _pick_agent_mine_position(direction, placement_distance, trigger_radius)
	var shot_radius: float = max(trigger_radius * 0.7, 7.0)
	var shot_origin: Vector2 = _get_agent_projectile_spawn_origin(direction, shot_radius, 3.0)
	if shot_origin == Vector2.INF:
		shot_origin = global_position
	var throw_direction: Vector2 = mine_position - shot_origin
	if throw_direction.length_squared() <= 4.0:
		throw_direction = direction
	var throw_distance: float = max(shot_origin.distance_to(mine_position), 24.0)
	var shot_config: Dictionary = {
		"speed": throw_distance / throw_seconds,
		"damage": max(projectile_damage, 1),
		"radius": trigger_radius,
		"kind": "agent_mine",
		"projectile_count": 1,
		"spread_angle_degrees": 0.0,
		"knockback": 360.0,
		"explosion_radius": max(float(agent_program.high_explosive_mine_blast_radius), trigger_radius + 18.0),
		"explosion_damage_multiplier": 1.0,
		"target_position": mine_position,
		"show_target_reticle": true,
		"target_reticle_radius": max(float(agent_program.high_explosive_mine_blast_radius), trigger_radius + 18.0),
		"arming_seconds": throw_seconds,
		"visual_rotation_offset": _agent_rng.randf_range(-PI, PI),
		"lifetime": throw_seconds + max(float(agent_program.high_explosive_mine_lifetime), 0.5),
		"exact_lifetime": true
	}
	shot_ready.emit(self, shot_origin, throw_direction.normalized(), shot_config)
	_play_agent_shoot_pose(direction)
	_agent_mine_sequence_remaining -= 1
	if _agent_mine_sequence_remaining > 0:
		_agent_mine_sequence_interval_remaining = max(float(agent_program.high_explosive_mine_interval), 0.04)


func _get_agent_mine_direction(mine_index: int) -> Vector2:
	var base_direction: Vector2 = _agent_mine_sequence_direction.normalized()
	if base_direction.length_squared() <= 0.001:
		base_direction = Vector2.RIGHT
	var mine_count: int = clampi(int(agent_program.high_explosive_mine_count), 1, 5)
	var spread: float = deg_to_rad(max(float(agent_program.high_explosive_mine_spread_degrees), 8.0))
	var offset: float = 0.0
	if mine_count > 1:
		var sequence_position: float = (float(mine_index) / float(mine_count - 1)) - 0.5
		offset = sequence_position * spread
	offset += _agent_rng.randf_range(-0.12, 0.12)
	return base_direction.rotated(offset).normalized()


func _pick_agent_mine_position(preferred_direction: Vector2, distance: float, mine_radius: float) -> Vector2:
	var directions: Array[Vector2] = [
		preferred_direction,
		preferred_direction.rotated(0.46),
		preferred_direction.rotated(-0.46),
		preferred_direction.rotated(0.86),
		preferred_direction.rotated(-0.86),
		-preferred_direction
	]
	for direction in directions:
		if direction.length_squared() <= 0.001:
			continue
		var candidate: Vector2 = global_position + direction.normalized() * distance
		candidate = _constrain_to_playable(candidate)
		if ArenaGeometry.contains_point(candidate, arena_bounds, arena_shape) and not _point_inside_wall(candidate, mine_radius * 0.65):
			return candidate
	return global_position


func _update_agent_slow_pressure_shots(to_target: Vector2) -> void:
	match _get_agent_slow_attack_verb():
		AgentBossProgram.SLOW_ATTACK_SHORT_SCATTER:
			_try_emit_agent_spread_shot(
				to_target,
				float(agent_program.slow_short_scatter_cooldown),
				max(float(agent_program.slow_projectile_speed) * 0.82, 210.0),
				projectile_damage,
				float(agent_program.slow_projectile_radius),
				clampi(int(agent_program.slow_short_scatter_projectile_count), 2, 8),
				max(float(agent_program.slow_short_scatter_degrees), 4.0),
				max(float(agent_program.slow_short_scatter_lifetime), 0.2),
				true
			)
		AgentBossProgram.SLOW_ATTACK_WIDE_SCATTER:
			_try_emit_agent_spread_shot(
				to_target,
				float(agent_program.slow_wide_scatter_cooldown),
				max(float(agent_program.slow_projectile_speed) * 0.72, 180.0),
				projectile_damage,
				float(agent_program.slow_projectile_radius) * 0.95,
				clampi(int(agent_program.slow_wide_scatter_projectile_count), 3, 12),
				max(float(agent_program.slow_wide_scatter_degrees), 12.0),
				max(float(agent_program.slow_wide_scatter_lifetime), 0.2),
				false
			)
		AgentBossProgram.SLOW_ATTACK_ASSAULT_BURST:
			_update_agent_assault_burst(to_target)
		_:
			_try_emit_agent_standard_shot(to_target, float(agent_program.slow_shot_cooldown), float(agent_program.slow_projectile_speed), projectile_damage, float(agent_program.slow_projectile_radius))


func _update_agent_assault_burst(to_target: Vector2) -> void:
	if to_target.length_squared() <= 4.0:
		return
	if _agent_burst_shots_remaining <= 0:
		if _agent_next_shot_remaining > 0.0:
			return
		_agent_burst_shots_remaining = clampi(int(agent_program.slow_assault_burst_count), 2, 6)
		_agent_burst_interval_remaining = 0.0
		_agent_burst_base_direction = to_target.normalized()
		_agent_next_shot_remaining = max(float(agent_program.slow_assault_burst_cooldown), 0.12)
	var emitted_count := 0
	while _agent_burst_shots_remaining > 0 and _agent_burst_interval_remaining <= 0.0 and emitted_count < 3:
		var jitter_degrees: float = _agent_rng.randf_range(-4.5, 4.5)
		var shot_direction: Vector2 = _agent_burst_base_direction.rotated(deg_to_rad(jitter_degrees)).normalized()
		_emit_agent_standard_projectile(
			shot_direction,
			max(float(agent_program.slow_projectile_speed) * 0.9, 260.0),
			projectile_damage,
			float(agent_program.slow_projectile_radius) * 0.95,
			1.0,
			1,
			0.0,
			max(float(agent_program.slow_assault_burst_lifetime), 0.2),
			"hostile_assault"
		)
		_agent_burst_shots_remaining -= 1
		_agent_burst_interval_remaining += max(float(agent_program.slow_assault_burst_interval), 0.025)
		emitted_count += 1


func _get_agent_slow_velocity(_to_target: Vector2) -> Vector2:
	var speed_value: float = max(float(agent_program.slow_move_speed), 0.0)
	if _agent_action_direction.length_squared() <= 0.001:
		_agent_action_direction = _pick_agent_valid_direction(Vector2.RIGHT.rotated(_agent_rng.randf() * TAU), 120.0)
	return _agent_action_direction.normalized() * speed_value


func _get_agent_normal_velocity(to_target: Vector2) -> Vector2:
	var speed_value: float = max(float(agent_program.normal_move_speed), 0.0)
	if _agent_action_direction.length_squared() <= 0.001:
		_agent_action_direction = _get_agent_normal_preferred_direction(to_target)
	return _get_agent_path_velocity_for_direction(_agent_action_direction, float(agent_program.normal_tactical_distance), speed_value)


func _get_agent_normal_preferred_direction(to_target: Vector2) -> Vector2:
	var target_direction: Vector2 = _get_target_direction(to_target)
	var personality_direction: Vector2 = _get_agent_normal_personality_direction(to_target)
	if personality_direction != Vector2.INF:
		return personality_direction
	match _get_agent_normal_movement_verb():
		AgentBossProgram.NORMAL_PUSH_FORWARD:
			return target_direction
		AgentBossProgram.NORMAL_PULL_BACK:
			return -target_direction
		AgentBossProgram.NORMAL_ZIG_ZAG:
			var zig_direction: Vector2 = (target_direction + target_direction.orthogonal() * _agent_zigzag_sign * 0.9).normalized()
			return zig_direction
		_:
			var strafe_direction: Vector2 = target_direction.orthogonal() * _strafe_sign
			return strafe_direction


func _get_agent_slow_personality_direction(to_target: Vector2) -> Vector2:
	var target_direction: Vector2 = _get_target_direction(to_target)
	match _get_agent_personality_verb():
		AgentBossProgram.PERSONALITY_HUNTER:
			return target_direction
		AgentBossProgram.PERSONALITY_BULLY:
			return -target_direction
		AgentBossProgram.PERSONALITY_COWARD:
			if _agent_rng.randf() < clamp(float(agent_program.coward_aggression_chance), 0.0, 1.0):
				return target_direction
			return _get_retreat_or_strafe_direction(target_direction, float(agent_program.normal_tactical_distance) * 0.55)
		AgentBossProgram.PERSONALITY_DUELIST:
			return _get_duelist_personality_direction(target_direction)
		_:
			return Vector2.RIGHT.rotated(_agent_rng.randf() * TAU)


func _get_agent_normal_personality_direction(to_target: Vector2) -> Vector2:
	var target_direction: Vector2 = _get_target_direction(to_target)
	match _get_agent_personality_verb():
		AgentBossProgram.PERSONALITY_HUNTER:
			return target_direction
		AgentBossProgram.PERSONALITY_BULLY:
			return target_direction.orthogonal() * _agent_zigzag_sign
		AgentBossProgram.PERSONALITY_COWARD:
			if _agent_rng.randf() < clamp(float(agent_program.coward_aggression_chance), 0.0, 1.0):
				return target_direction
			return _get_retreat_or_strafe_direction(target_direction, float(agent_program.normal_tactical_distance))
		AgentBossProgram.PERSONALITY_DUELIST:
			return _get_duelist_personality_direction(target_direction)
	return Vector2.INF


func _get_retreat_or_strafe_direction(target_direction: Vector2, distance: float) -> Vector2:
	if _agent_direction_has_lane(-target_direction, distance):
		return -target_direction
	var side_direction: Vector2 = target_direction.orthogonal() * _agent_zigzag_sign
	if _agent_direction_has_lane(side_direction, distance):
		return side_direction
	if _agent_direction_has_lane(-side_direction, distance):
		return -side_direction
	return target_direction


func _get_duelist_personality_direction(target_direction: Vector2) -> Vector2:
	var distance_to_target: float = global_position.distance_to(target_position)
	var preferred: float = max(float(agent_program.duelist_preferred_distance), 80.0)
	var band: float = max(float(agent_program.duelist_distance_band), 12.0)
	if _wall_blocks_segment(global_position, target_position):
		return target_direction
	if distance_to_target < preferred - band:
		return -target_direction
	if distance_to_target > preferred + band:
		return target_direction
	return target_direction.orthogonal() * _agent_zigzag_sign


func _agent_direction_has_lane(direction: Vector2, distance: float) -> bool:
	if direction.length_squared() <= 0.001:
		return false
	var normalized_direction: Vector2 = direction.normalized()
	var candidate: Vector2 = global_position + normalized_direction * max(distance, 48.0)
	candidate = _constrain_to_playable(candidate)
	var to_candidate: Vector2 = candidate - global_position
	if to_candidate.length_squared() <= 36.0 * 36.0 or to_candidate.normalized().dot(normalized_direction) < 0.45:
		return false
	return _agent_point_is_valid(candidate) and not _path_blocks_segment(global_position, candidate, body_radius * 0.55)


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
	var max_chain_count: int = max(int(agent_program.max_special_chain_count), 1)
	_agent_special_chain_count = clampi(_agent_special_chain_count + 1, 1, max_chain_count)
	_agent_special_attack_emitted = false
	_agent_special_stage = AGENT_SPECIAL_STAGE_MOVE
	_agent_dash_steps_remaining = max(int(agent_program.dash_count), 1)
	match _get_agent_special_movement_verb():
		AgentBossProgram.SPECIAL_MOVEMENT_TELEPORT_LOS:
			var teleport_target: Vector2 = _pick_agent_los_point(to_target)
			if teleport_target != Vector2.INF:
				_start_agent_teleport_cast(teleport_target, to_target)
			else:
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


func _start_agent_teleport_cast(teleport_target: Vector2, to_target: Vector2) -> void:
	_agent_special_stage = AGENT_SPECIAL_STAGE_TELEPORT_CAST
	_agent_teleport_target = teleport_target
	_agent_teleport_cast_duration = max(float(agent_program.teleport_cast_seconds), 0.08)
	_agent_teleport_cast_remaining = _agent_teleport_cast_duration
	_agent_aim_at_target(to_target)
	activate_projectile_shield(_agent_teleport_cast_duration + 0.12)
	queue_redraw()


func _update_agent_teleport_cast(delta: float, to_target: Vector2) -> void:
	if _agent_teleport_target == Vector2.INF:
		_start_agent_special_telegraph(to_target)
		return
	_agent_teleport_cast_remaining = max(_agent_teleport_cast_remaining - delta, 0.0)
	_agent_aim_at_target(to_target)
	if _agent_teleport_cast_remaining > 0.0:
		queue_redraw()
		return
	global_position = _constrain_to_playable(_agent_teleport_target)
	_agent_teleport_target = Vector2.INF
	_agent_teleport_cast_duration = 0.0
	_invalidate_path_cache()
	_start_agent_special_telegraph(target_position - global_position)


func _pick_agent_los_point(to_target: Vector2) -> Vector2:
	var los_preferred_distance: float = clamp(float(agent_program.special_move_distance), 180.0, 420.0)
	var directions: Array[Vector2] = _get_agent_special_move_directions(to_target)
	for direction in directions:
		var candidate: Vector2 = global_position + direction.normalized() * los_preferred_distance
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
	match _get_agent_personality_special_reposition(to_target):
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


func _get_agent_personality_special_reposition(to_target: Vector2) -> String:
	var target_direction: Vector2 = _get_target_direction(to_target)
	match _get_agent_personality_verb():
		AgentBossProgram.PERSONALITY_HUNTER:
			return AgentBossProgram.SPECIAL_REPOSITION_STRAFE
		AgentBossProgram.PERSONALITY_BULLY:
			return AgentBossProgram.SPECIAL_REPOSITION_APPROACH
		AgentBossProgram.PERSONALITY_COWARD:
			if _agent_rng.randf() < clamp(float(agent_program.coward_aggression_chance), 0.0, 1.0):
				return AgentBossProgram.SPECIAL_REPOSITION_APPROACH
			if _agent_direction_has_lane(-target_direction, float(agent_program.special_move_distance)):
				return AgentBossProgram.SPECIAL_REPOSITION_RETREAT
			return AgentBossProgram.SPECIAL_REPOSITION_STRAFE
		AgentBossProgram.PERSONALITY_DUELIST:
			var distance_to_target: float = global_position.distance_to(target_position)
			var preferred: float = max(float(agent_program.duelist_preferred_distance), 80.0)
			var band: float = max(float(agent_program.duelist_distance_band), 12.0)
			if _wall_blocks_segment(global_position, target_position):
				return AgentBossProgram.SPECIAL_REPOSITION_APPROACH
			if distance_to_target < preferred - band:
				return AgentBossProgram.SPECIAL_REPOSITION_RETREAT
			if distance_to_target > preferred + band:
				return AgentBossProgram.SPECIAL_REPOSITION_APPROACH
			return AgentBossProgram.SPECIAL_REPOSITION_STRAFE
	return _get_agent_special_reposition_verb()


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
	if _agent_stream_remaining > 0.0:
		_update_agent_special_stream(delta)
	if _path_blocks_segment(global_position, global_position + _agent_charge_direction * 42.0, body_radius * 0.65):
		_finish_agent_special_action()
		return Vector2.ZERO
	if _agent_charge_remaining <= 0.0:
		_agent_charge_elapsed = 0.0
		_agent_charge_special_fired = false
		if _agent_stream_remaining > 0.0:
			_agent_special_stage = AGENT_SPECIAL_STAGE_STREAM
		else:
			_finish_agent_special_action()
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
	_agent_special_attack_emitted = true
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
	var shot_origin: Vector2 = _get_agent_projectile_spawn_origin(shot_direction, radius, 3.0)
	if shot_origin == Vector2.INF:
		return
	if _wall_blocks_segment(global_position, target_position):
		return
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
		var shot_origin: Vector2 = _get_agent_projectile_spawn_origin(direction, radius, 3.0)
		if shot_origin != Vector2.INF:
			shot_ready.emit(self, shot_origin, direction, shot_config)
			_play_agent_shoot_pose(direction)
		_agent_stream_next_shot_remaining += interval
		emitted_count += 1
	if _agent_stream_remaining <= 0.0:
		_finish_agent_stream_or_action()
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
		_finish_agent_stream_or_action()
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
		_finish_agent_stream_or_action()
	queue_redraw()


func _finish_agent_stream_or_action() -> void:
	if _agent_charge_remaining > 0.0:
		_clear_agent_stream_state()
		_agent_special_stage = AGENT_SPECIAL_STAGE_MOVE
	else:
		_finish_agent_special_action()


func _clear_agent_stream_state() -> void:
	_agent_stream_kind = ""
	_agent_stream_remaining = 0.0
	_agent_stream_elapsed = 0.0
	_agent_stream_next_shot_remaining = 0.0
	_agent_stream_wave_index = 0


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
	var shot_origin: Vector2 = _get_agent_projectile_spawn_origin(direction, radius, 3.0)
	if shot_origin == Vector2.INF:
		return
	shot_ready.emit(self, shot_origin, direction, shot_config.duplicate())


func _get_agent_projectile_spawn_origin(shot_direction: Vector2, radius: float, clearance: float = 3.0) -> Vector2:
	if shot_direction.length_squared() <= 0.001:
		return Vector2.INF
	var normalized_direction: Vector2 = shot_direction.normalized()
	var shot_radius: float = max(radius, 1.0)
	var spawn_distance: float = body_radius + shot_radius + max(clearance, 0.0)
	var shot_origin: Vector2 = global_position + normalized_direction * spawn_distance
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return Vector2.INF
	if _wall_blocks_segment(global_position, shot_origin):
		return Vector2.INF
	return shot_origin


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
	if _emit_agent_standard_projectile(shot_direction, shot_speed, damage, radius, 1.0, 1, 0.0, 0.0, "hostile"):
		_agent_next_shot_remaining = max(cooldown, 0.05)


func _try_emit_agent_spread_shot(to_target: Vector2, cooldown: float, shot_speed: float, damage: int, radius: float, projectile_count: int, spread_degrees: float, lifetime: float, randomize_pattern: bool) -> void:
	if _agent_next_shot_remaining > 0.0 or to_target.length_squared() <= 4.0:
		return
	var shot_direction: Vector2 = to_target.normalized()
	var final_spread_degrees: float = spread_degrees
	var final_projectile_count: int = projectile_count
	if randomize_pattern:
		final_spread_degrees = max(spread_degrees + _agent_rng.randf_range(-8.0, 10.0), 8.0)
		final_projectile_count = clampi(projectile_count + _agent_rng.randi_range(-1, 1), 2, 9)
		shot_direction = shot_direction.rotated(deg_to_rad(_agent_rng.randf_range(-final_spread_degrees * 0.12, final_spread_degrees * 0.12))).normalized()
	if _emit_agent_standard_projectile(shot_direction, shot_speed, damage, radius, 1.0, final_projectile_count, final_spread_degrees, lifetime, "hostile_scatter"):
		_agent_next_shot_remaining = max(cooldown, 0.05)


func _emit_agent_standard_projectile(shot_direction: Vector2, shot_speed: float, damage: int, radius: float, damage_multiplier: float, projectile_count: int, spread_degrees: float, lifetime: float, kind: String) -> bool:
	if shot_direction.length_squared() <= 0.001:
		return false
	var normalized_direction: Vector2 = shot_direction.normalized()
	var shot_radius: float = max(radius, 1.0)
	var shot_origin: Vector2 = global_position + normalized_direction * (body_radius + shot_radius + 5.0)
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		return false
	if _wall_blocks_segment(global_position, target_position) or _wall_blocks_segment(global_position, shot_origin):
		return false
	var shot_config: Dictionary = {
		"speed": max(shot_speed, 1.0),
		"damage": max(roundi(float(damage) * max(damage_multiplier, 0.1)), 1),
		"radius": shot_radius,
		"kind": kind,
		"projectile_count": max(projectile_count, 1),
		"spread_angle_degrees": max(spread_degrees, 0.0),
		"knockback": 0.0
	}
	if lifetime > 0.0:
		shot_config["lifetime"] = lifetime
	shot_ready.emit(self, shot_origin, normalized_direction, shot_config)
	_play_agent_shoot_pose(normalized_direction)
	return true


func _get_agent_normal_movement_verb() -> String:
	return String(agent_program.normal_movement_verb) if agent_program != null else AgentBossProgram.NORMAL_STRAFE


func _get_agent_personality_verb() -> String:
	return String(agent_program.personality_verb) if agent_program != null else AgentBossProgram.PERSONALITY_HUNTER


func _get_agent_slow_attack_verb() -> String:
	return String(agent_program.slow_attack_verb) if agent_program != null else AgentBossProgram.SLOW_ATTACK_FAST_SINGLE


func _get_agent_high_explosive_verb() -> String:
	return String(agent_program.high_explosive_verb) if agent_program != null else AgentBossProgram.HIGH_EXPLOSIVE_ROCKET


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
	if not _uses_agent_character_art():
		return
	if movement.length_squared() > 1.0:
		_agent_walk_cycle += delta * 9.0
		_agent_last_move_facing_direction = movement.normalized()


func _update_boss_special(delta: float, to_target: Vector2) -> bool:
	if behavior_kind != BEHAVIOR_BOSS or health <= 0 or _is_dying:
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
	if _boss_special_kind == "autocannon":
		shot_origin = _get_boss_autocannon_shot_origin(shot_direction, radius)
		var autocannon_target_position: Vector2 = global_position + to_target
		var autocannon_target_direction: Vector2 = autocannon_target_position - shot_origin
		if autocannon_target_direction.length_squared() > 4.0:
			shot_direction = autocannon_target_direction.normalized()
	if not ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape):
		shot_origin = global_position
	if _boss_special_kind == "rocket" or _boss_special_kind == "grenade":
		var target_position_at_launch := global_position + to_target
		var target_direction := target_position_at_launch - shot_origin
		if target_direction.length_squared() > 4.0:
			shot_direction = target_direction.normalized()
		var rocket_speed: float = max(float(shot_config.get("speed", projectile_speed)), 1.0)
		shot_config["target_position"] = target_position_at_launch
		shot_config["lifetime"] = max(shot_origin.distance_to(target_position_at_launch) / rocket_speed, 0.08)
		shot_config["exact_lifetime"] = true
		if _boss_special_kind == "grenade":
			shot_config["show_target_reticle"] = true
			shot_config["target_reticle_radius"] = float(shot_config.get("explosion_radius", 58.0))
	shot_ready.emit(self, shot_origin, shot_direction, shot_config)
	if _boss_special_kind == "autocannon":
		_boss_autocannon_side_sign *= -1


func _start_boss_minigun(to_target: Vector2) -> void:
	if to_target.length_squared() <= 4.0:
		_finish_boss_special()
		return
	if behavior_kind == BEHAVIOR_POWER_ARMOR:
		_prepare_boss_minigun_start_side()
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


func _start_boss_autocannon(to_target: Vector2) -> void:
	if to_target.length_squared() <= 4.0:
		_finish_boss_special()
		return
	var min_shots: int = clampi(special_autocannon_min_shots, 1, 24)
	var max_shots: int = clampi(special_autocannon_max_shots, min_shots, 24)
	_boss_autocannon_shots_remaining = _agent_rng.randi_range(min_shots, max_shots)
	_boss_autocannon_next_shot_remaining = 0.0
	_update_boss_autocannon(0.0, to_target)


func _update_boss_autocannon(delta: float, to_target: Vector2) -> void:
	_boss_autocannon_next_shot_remaining -= delta
	var interval: float = max(special_autocannon_shot_interval, 0.035)
	var emitted_count: int = 0
	while _boss_autocannon_shots_remaining > 0 and _boss_autocannon_next_shot_remaining <= 0.0 and emitted_count < 4:
		_emit_boss_special(to_target)
		_boss_autocannon_shots_remaining -= 1
		_boss_autocannon_next_shot_remaining += interval
		emitted_count += 1
	if _boss_autocannon_shots_remaining <= 0:
		_finish_boss_special()
	queue_redraw()


func _get_boss_minigun_direction() -> Vector2:
	var duration: float = max(boss_minigun_duration, 0.12)
	var progress: float = clamp(_boss_minigun_elapsed / duration, 0.0, 1.0)
	return _get_boss_minigun_direction_for_progress(_boss_minigun_base_direction, progress)


func _get_boss_minigun_direction_for_progress(base_direction: Vector2, progress: float) -> Vector2:
	if base_direction.length_squared() <= 0.001:
		base_direction = Vector2.RIGHT
	var half_sweep: float = deg_to_rad(boss_minigun_sweep_degrees) * 0.5
	if behavior_kind == BEHAVIOR_POWER_ARMOR:
		var start_angle: float = half_sweep * float(_get_boss_minigun_start_side())
		var phase: float = clamp(progress, 0.0, 1.0) * 2.0
		var angle: float = lerp(start_angle, -start_angle, phase) if phase <= 1.0 else lerp(-start_angle, start_angle, phase - 1.0)
		return base_direction.rotated(angle).normalized()
	return base_direction.rotated(lerp(-half_sweep, half_sweep, progress)).normalized()


func _prepare_boss_minigun_start_side() -> void:
	var parity: int = int(abs(int(get_instance_id())) + _boss_special_sequence_index) % 2
	_boss_minigun_start_side = -1 if parity == 0 else 1


func _get_boss_minigun_start_side() -> int:
	return -1 if _boss_minigun_start_side < 0 else 1


func _get_boss_autocannon_side_sign() -> int:
	return -1 if _boss_autocannon_side_sign < 0 else 1


func _get_boss_autocannon_shot_origin(shot_direction: Vector2, radius: float) -> Vector2:
	var side_offset: Vector2 = shot_direction.orthogonal() * float(_get_boss_autocannon_side_sign()) * body_radius * 0.62
	var forward_offset: Vector2 = shot_direction * (body_radius + radius + 5.0)
	var shot_origin: Vector2 = global_position + side_offset + forward_offset
	if ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape) and not _point_inside_wall(shot_origin, radius * 0.65):
		return shot_origin
	shot_origin = global_position + forward_offset
	if ArenaGeometry.contains_point(shot_origin, arena_bounds, arena_shape) and not _point_inside_wall(shot_origin, radius * 0.65):
		return shot_origin
	return global_position


func _finish_boss_special() -> void:
	_boss_minigun_remaining = 0.0
	_boss_minigun_elapsed = 0.0
	_boss_minigun_next_shot_remaining = 0.0
	_boss_autocannon_shots_remaining = 0
	_boss_autocannon_next_shot_remaining = 0.0
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
	if special_kind == "grenade":
		return {
			"speed": max(projectile_speed * 1.35, 300.0),
			"damage": max(projectile_damage, 1),
			"radius": max(projectile_radius * 1.2, 9.5),
			"kind": "agent_grenade",
			"projectile_count": 1,
			"spread_angle_degrees": 0.0,
			"knockback": 360.0,
			"explosion_radius": 62.0,
			"explosion_damage_multiplier": 1.0
		}
	if special_kind == "autocannon":
		return {
			"speed": max(projectile_speed * 3.0, 720.0),
			"damage": max(projectile_damage + 1, 2),
			"radius": max(projectile_radius * 1.25, 9.0),
			"kind": "hostile_autocannon",
			"projectile_count": 1,
			"spread_angle_degrees": 0.0,
			"lifetime": 1.12,
			"knockback": 230.0
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
	var movement_target: Vector2 = target_position
	if _tactical_target_position != Vector2.INF and global_position.distance_squared_to(_tactical_target_position) > 52.0 * 52.0:
		movement_target = _tactical_target_position
	var steering_target := _get_path_steering_target(movement_target)
	var to_steering := steering_target - global_position
	if to_steering.length_squared() <= 4.0:
		return Vector2.ZERO
	return to_steering.normalized() * speed


func _get_ranged_velocity(to_target: Vector2) -> Vector2:
	if to_target.length_squared() <= 4.0:
		return Vector2.ZERO
	if _tactical_target_position != Vector2.INF and global_position.distance_squared_to(_tactical_target_position) > 42.0 * 42.0:
		var tactical_steering_target := _get_path_steering_target(_tactical_target_position)
		var to_tactical_steering := tactical_steering_target - global_position
		if to_tactical_steering.length_squared() > 4.0:
			return to_tactical_steering.normalized() * speed
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
	if behavior_kind != BEHAVIOR_SHOOTER and behavior_kind != BEHAVIOR_BOSS and behavior_kind != BEHAVIOR_REPAIR_DRONE and not is_general():
		return
	if _shot_cooldown_remaining > 0.0 or to_target.length_squared() <= 4.0:
		return
	var shot_direction := to_target.normalized()
	if _emit_enemy_projectile(shot_direction, projectile_speed, projectile_damage, projectile_radius, shot_projectile_count, shot_spread_degrees, 1.2, "hostile"):
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
	_disable_collision_state()
	velocity = Vector2.ZERO
	_hit_flash_remaining = 0.0
	queue_redraw()


func _draw_death_animation() -> void:
	var progress: float = clamp(_death_elapsed / _death_duration, 0.0, 1.0)
	var alpha: float = 1.0 - progress
	if bool(get_meta("retreat_visual", false)):
		var retreat_direction := -_visual_direction.normalized()
		if retreat_direction.length_squared() <= 0.001:
			retreat_direction = Vector2.RIGHT
		draw_circle(retreat_direction * progress * 38.0, body_radius * (1.0 - progress * 0.5), Color(0.46, 0.82, 1.0, alpha * 0.72))
		for trail_index in range(3):
			var trail_offset := retreat_direction * (-12.0 - float(trail_index) * 10.0 + progress * 38.0)
			draw_circle(trail_offset, max(5.0 - float(trail_index), 2.0), Color(0.38, 0.72, 1.0, alpha * 0.32))
		return
	draw_circle(Vector2.ZERO, body_radius * (1.0 - progress * 0.65), Color(1.0, 0.27, 0.22, alpha))
	draw_arc(Vector2.ZERO, body_radius + progress * 34.0, 0.0, TAU, 28, Color(1.0, 0.72, 0.18, alpha), 4.0)
	for index in range(6):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / 6.0)
		draw_line(direction * body_radius * 0.25, direction * (body_radius + progress * 42.0), Color(1.0, 0.18, 0.1, alpha), 3.0)


func _add_collision() -> void:
	if _collision_shape != null:
		_sync_collision_radius()
		return
	if _is_dying:
		return
	if is_inside_tree() and Engine.is_in_physics_frame():
		if not _collision_add_deferred:
			_collision_add_deferred = true
			call_deferred("_add_collision")
		return
	_collision_add_deferred = false
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = shape
	add_child(collision_shape)
	_collision_shape = collision_shape
	_sync_collision_radius()


func _sync_collision_radius() -> void:
	if _collision_shape == null:
		return
	var shape := _collision_shape.shape as CircleShape2D
	if shape == null:
		shape = CircleShape2D.new()
		_collision_shape.shape = shape
	shape.radius = body_radius


func _disable_collision_state() -> void:
	_collision_add_deferred = false
	_set_body_collision_property("collision_layer", 0)
	_set_body_collision_property("collision_mask", 0)


func _set_body_collision_property(property_name: StringName, value: Variant) -> void:
	if is_inside_tree() and Engine.is_in_physics_frame():
		set_deferred(property_name, value)
		return
	set(property_name, value)


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
