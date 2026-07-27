extends Node
class_name SpawnerManager

const WALL_OCCLUSION_LAYERS := preload("res://scripts/arena/wall_occlusion_layers.gd")

signal spawn_requested(spawn_position: Vector2, profile)
signal spawn_proposed(proposal: Dictionary)
signal spawner_count_changed(count: int)
signal spawner_destroyed(spawner, score_value: int)
signal hostile_shot_requested(origin: Vector2, direction: Vector2, shot_config: Dictionary)

@export var spawner_scene: PackedScene = preload("res://scenes/entities/enemy_spawner_entity.tscn")
@export var default_enemy_profile: Resource = preload("res://resources/enemies/basic_enemy.tres")
@export var default_spawner_profile: Resource = preload("res://resources/spawners/basic_spawner.tres")
@export var max_active_enemies: int = 18
@export var default_spawner_health: int = 18
@export var default_spawn_interval: float = 2.8
@export var default_spawner_radius: float = 32.0
@export var initial_spawn_batch_multiplier: int = 2
@export var spawn_player_bias_fan_degrees: float = 112.0
@export var initial_spawn_player_bias_fan_degrees: float = 136.0
@export var pressure_damage_distance: float = 165.0
@export var pressure_damage_bonus: int = 1
@export var floor_one_spawn_interval_multiplier: float = 1.35
@export var spawn_interval_floor_step: float = 0.08
@export var minimum_floor_spawn_interval_multiplier: float = 0.72
@export var minimum_scaled_spawn_interval: float = 1.15
## Controls how strongly spawner structures push away from overlapping spawner structures.
@export var spawner_separation_force: float = 92.0
## Adds extra spacing between spawner body radii when resolving spawner overlap.
@export var spawner_separation_padding: float = 16.0
## Controls how long newly-instantiated room spawners use the teleport-in materialization visual.
@export var spawner_birth_animation_seconds: float = 0.42

const SPAWNER_PLACEMENT_SCRIPT := preload("res://scripts/resources/spawner_placement.gd")

var enabled: bool = false
var _spawner_layer: Node = null
var _spawners: Array = []
var _current_enemy_count: int = 0
var _level_definition = null
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _wall_rects: Array[Rect2] = []
var _level_wall_rects: Array[Rect2] = []
var _void_rects: Array[Rect2] = []
var _playable_rects: Array[Rect2] = []
var _spawn_exclusion_rects: Array[Rect2] = []
var _player_provider: Callable
var _initial_spawns_pending: bool = false
var _initial_spawn_delay_remaining: float = 0.0
var _preloaded_initial_spawn_activation_pending: bool = false
var _perspective_room_id: String = ""
var _spawn_room_id: String = ""
var _spawn_generation: int = 0


func initialize(context: Dictionary) -> void:
	_spawner_layer = context.get("spawner_layer", null)
	_player_provider = context.get("player_position_provider", Callable())


func set_spawn_context(room_id: String, generation: int) -> void:
	_spawn_room_id = room_id
	_spawn_generation = generation


func reset_run(level_definition = null) -> void:
	_level_definition = level_definition
	set_arena_definition(level_definition)
	clear_spawners()
	var placements: Array = _get_spawner_placements()
	max_active_enemies = _get_max_active_enemies()
	for index in range(placements.size()):
		_spawn_spawner(placements[index], index)
	_initial_spawns_pending = not _spawners.is_empty()
	_initial_spawn_delay_remaining = 0.0
	_preloaded_initial_spawn_activation_pending = false
	spawner_count_changed.emit(_spawners.size())


func clear_spawners() -> void:
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	_spawners.clear()
	_initial_spawns_pending = false
	_initial_spawn_delay_remaining = 0.0
	_preloaded_initial_spawn_activation_pending = false
	spawner_count_changed.emit(0)


func set_enabled(value: bool) -> void:
	enabled = value
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.set_enabled(value)
	if enabled and _preloaded_initial_spawn_activation_pending:
		_activate_preloaded_initial_spawn_sequence()
	elif enabled and _initial_spawns_pending:
		_begin_initial_spawn_sequence()


func set_enemy_count(count: int) -> void:
	_current_enemy_count = count


func prepare_spawners_for_preload() -> void:
	for spawner_node in _spawners:
		var spawner: EnemySpawnerEntity = spawner_node as EnemySpawnerEntity
		if spawner == null or not is_instance_valid(spawner):
			continue
		var birth_duration: float = max(spawner_birth_animation_seconds, 0.08)
		spawner.play_birth_animation(birth_duration)
		spawner.visible = false
		spawner.velocity = Vector2.ZERO
		spawner.set_meta("preloaded_hidden", true)
		spawner.set_meta("preloaded_birth_duration", birth_duration)
		spawner.set_enabled(false)
		spawner.set_process(false)
		spawner.set_physics_process(false)


func set_spawners_active(value: bool, materialize_preloaded: bool = false) -> void:
	for spawner_node in _spawners:
		var spawner: EnemySpawnerEntity = spawner_node as EnemySpawnerEntity
		if spawner == null or not is_instance_valid(spawner):
			continue
		if value:
			spawner.set_process(true)
			spawner.set_physics_process(true)
			if bool(spawner.get_meta("preloaded_hidden", false)):
				spawner.visible = true
				spawner.remove_meta("preloaded_hidden")
				if materialize_preloaded:
					spawner.play_birth_animation(float(spawner.get_meta("preloaded_birth_duration", max(spawner_birth_animation_seconds, 0.08))))
				if spawner.has_meta("preloaded_birth_duration"):
					spawner.remove_meta("preloaded_birth_duration")
		elif bool(spawner.get_meta("preloaded_hidden", false)):
			spawner.visible = false
			spawner.velocity = Vector2.ZERO
			spawner.set_process(false)
			spawner.set_physics_process(false)


func consume_initial_spawn_requests() -> Array[Dictionary]:
	var requests: Array[Dictionary] = []
	if not _initial_spawns_pending or _get_initial_spawn_batch_multiplier() <= 0:
		_initial_spawns_pending = false
		_initial_spawn_delay_remaining = 0.0
		return requests
	var projected_enemy_count: int = _current_enemy_count
	for spawner_index in range(_spawners.size()):
		var spawner: EnemySpawnerEntity = _spawners[spawner_index] as EnemySpawnerEntity
		if spawner == null or not is_instance_valid(spawner):
			continue
		var profile: Resource = spawner.enemy_profile if spawner.enemy_profile != null else default_enemy_profile
		var spawn_count: int = _get_initial_spawn_batch_count(spawner)
		for spawn_index in range(spawn_count):
			if projected_enemy_count >= max_active_enemies:
				_initial_spawns_pending = false
				_initial_spawn_delay_remaining = 0.0
				_preloaded_initial_spawn_activation_pending = not requests.is_empty()
				return requests
			var spawn_position: Vector2 = _get_initial_spawn_position(spawner, spawner_index, spawn_index, spawn_count)
			if spawn_position == Vector2.INF:
				continue
			requests.append(_build_spawn_proposal(
				spawn_position,
				profile,
				spawner,
				spawner_index,
				spawn_index,
				spawn_count,
				true
			))
			projected_enemy_count += 1
	_initial_spawns_pending = false
	_initial_spawn_delay_remaining = 0.0
	_preloaded_initial_spawn_activation_pending = not requests.is_empty()
	return requests


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_perspective_room_id = String(level_definition.get_meta("active_room_id", ""))
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_level_wall_rects = _get_level_collision_rects(level_definition, "active_room_wall_rects", level_definition.wall_rects)
	_wall_rects = _level_wall_rects.duplicate()
	_void_rects = _get_level_collision_rects(level_definition, "active_room_void_rects", level_definition.void_rects)
	_playable_rects = _get_playable_rects(level_definition)
	_spawn_exclusion_rects = _get_level_collision_rects(level_definition, "active_room_spawn_exclusion_rects", [])
	for spawner in _spawners:
		if is_instance_valid(spawner) and spawner.has_method("set_arena_definition"):
			spawner.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_dynamic_wall_rects(extra_wall_rects: Array[Rect2]) -> void:
	_wall_rects = _level_wall_rects.duplicate()
	_wall_rects.append_array(extra_wall_rects)
	for spawner in _spawners:
		if is_instance_valid(spawner) and spawner.has_method("set_arena_definition"):
			spawner.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func _process(delta: float) -> void:
	var player_position := _get_player_position()
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.set_target_position(player_position)
	if enabled:
		_apply_spawner_separation()
	if not enabled or not _initial_spawns_pending:
		return
	_initial_spawn_delay_remaining = max(_initial_spawn_delay_remaining - delta, 0.0)
	if _initial_spawn_delay_remaining <= 0.0:
		_initial_spawns_pending = false
		_emit_initial_spawn_requests()


func _spawn_spawner(placement, index: int) -> void:
	var profile = default_spawner_profile
	var spawn_position := Vector2.ZERO
	var warmup := 1.0 + float(index) * 0.55
	if placement != null:
		profile = placement.profile if placement.profile != null else default_spawner_profile
		spawn_position = placement.position
		warmup = placement.warmup_seconds
	var spawner = spawner_scene.instantiate()
	WALL_OCCLUSION_LAYERS.mark_entity_tree(spawner, _perspective_room_id)
	spawner.warmup_seconds = warmup
	if profile != null and spawner.has_method("initialize_from_profile"):
		spawner.initialize_from_profile(profile)
		spawner.spawn_interval = _scale_spawn_interval_for_floor(float(spawner.spawn_interval))
	else:
		spawner.initialize(_get_spawner_health(), _get_spawn_interval(), _get_spawner_radius())
	spawner.global_position = _constrain_spawn_position(spawn_position, float(spawner.body_radius))
	spawner.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)
	spawner.spawn_ready.connect(_on_spawner_spawn_ready)
	spawner.health_depleted.connect(_on_spawner_health_depleted)
	spawner.shot_ready.connect(_on_spawner_shot_ready)
	if spawner_birth_animation_seconds > 0.0 and spawner.has_method("play_birth_animation"):
		spawner.play_birth_animation(spawner_birth_animation_seconds)
	_spawners.append(spawner)
	_add_child_safely(_get_spawner_parent(), spawner)


func _on_spawner_spawn_ready(_spawner, _spawn_position: Vector2) -> void:
	if not enabled or _current_enemy_count >= max_active_enemies:
		return
	var profile = _spawner.enemy_profile if _spawner != null and _spawner.enemy_profile != null else default_enemy_profile
	var batch_count := _get_spawner_spawn_batch_count(_spawner)
	var projected_enemy_count := _current_enemy_count
	for spawn_index in range(batch_count):
		if projected_enemy_count >= max_active_enemies:
			return
		var batch_position := _get_spawn_position_around_spawner(_spawner, spawn_index, batch_count)
		if batch_position == Vector2.INF:
			continue
		spawn_proposed.emit(_build_spawn_proposal(
			batch_position,
			profile,
			_spawner,
			_spawners.find(_spawner),
			spawn_index,
			batch_count,
			false
		))
		spawn_requested.emit(batch_position, profile)
		projected_enemy_count += 1


func _get_spawner_parent() -> Node:
	return _spawner_layer if _spawner_layer != null else self


func _add_child_safely(parent: Node, child: Node) -> void:
	if parent == null or child == null or child.get_parent() != null:
		return
	if parent.is_inside_tree() and Engine.is_in_physics_frame():
		parent.call_deferred("add_child", child)
		return
	parent.add_child(child)


func _begin_initial_spawn_sequence() -> void:
	if _get_initial_spawn_batch_multiplier() <= 0:
		_initial_spawns_pending = false
		_initial_spawn_delay_remaining = 0.0
		return
	_initial_spawn_delay_remaining = _get_initial_spawn_shield_delay()
	for spawner in _spawners:
		if not is_instance_valid(spawner):
			continue
		var shield_after_spawn: float = float(spawner.projectile_shield_after_spawn_seconds)
		if spawner.has_method("activate_projectile_shield"):
			spawner.activate_projectile_shield(_initial_spawn_delay_remaining + shield_after_spawn)
		if spawner.has_method("delay_next_spawn_until"):
			spawner.delay_next_spawn_until(_initial_spawn_delay_remaining + float(spawner.spawn_interval))
	if _initial_spawn_delay_remaining <= 0.0:
		_initial_spawns_pending = false
		_emit_initial_spawn_requests()


func _activate_preloaded_initial_spawn_sequence() -> void:
	_preloaded_initial_spawn_activation_pending = false
	for spawner_node in _spawners:
		var spawner: EnemySpawnerEntity = spawner_node as EnemySpawnerEntity
		if spawner == null or not is_instance_valid(spawner):
			continue
		var shield_after_spawn: float = float(spawner.projectile_shield_after_spawn_seconds)
		if spawner.has_method("activate_projectile_shield"):
			spawner.activate_projectile_shield(shield_after_spawn)
		if spawner.has_method("delay_next_spawn_until"):
			spawner.delay_next_spawn_until(float(spawner.spawn_interval))


func _emit_initial_spawn_requests() -> void:
	if _get_initial_spawn_batch_multiplier() <= 0:
		return
	var projected_enemy_count := _current_enemy_count
	for spawner_index in range(_spawners.size()):
		var spawner = _spawners[spawner_index]
		if not is_instance_valid(spawner):
			continue
		var profile = spawner.enemy_profile if spawner.enemy_profile != null else default_enemy_profile
		var spawn_count := _get_initial_spawn_batch_count(spawner)
		for spawn_index in range(spawn_count):
			if projected_enemy_count >= max_active_enemies:
				return
			var spawn_position := _get_initial_spawn_position(spawner, spawner_index, spawn_index, spawn_count)
			if spawn_position == Vector2.INF:
				continue
			spawn_proposed.emit(_build_spawn_proposal(
				spawn_position,
				profile,
				spawner,
				spawner_index,
				spawn_index,
				spawn_count,
				true
			))
			spawn_requested.emit(spawn_position, profile)
			projected_enemy_count += 1


func request_spawn_reroll(proposal: Dictionary) -> void:
	if String(proposal.get("room_id", "")) != _spawn_room_id:
		return
	if int(proposal.get("generation", -1)) != _spawn_generation:
		return
	var retry_count: int = int(proposal.get("retry_count", 0)) + 1
	if retry_count > 3:
		return
	var spawner = proposal.get("source_spawner", null)
	if spawner == null or not is_instance_valid(spawner):
		return
	var spawn_index: int = int(proposal.get("spawn_index", 0))
	var spawn_count: int = max(int(proposal.get("spawn_count", 1)), 1)
	var initial_horde: bool = bool(proposal.get("initial_horde", false))
	var base_distance: float = max(
		float(spawner.body_radius) + (46.0 if initial_horde else 36.0),
		64.0 if initial_horde else 54.0
	)
	var fan_degrees: float = initial_spawn_player_bias_fan_degrees if initial_horde else spawn_player_bias_fan_degrees
	var phase: float = float(proposal.get("spawner_index", 0)) * 0.09 + float(retry_count) * 0.47
	var position: Vector2 = _get_biased_spawn_position(
		spawner,
		spawn_index,
		spawn_count,
		base_distance,
		deg_to_rad(fan_degrees),
		phase
	)
	if position == Vector2.INF:
		return
	var rerolled: Dictionary = proposal.duplicate()
	rerolled["position"] = position
	rerolled["retry_count"] = retry_count
	spawn_proposed.emit(rerolled)


func _build_spawn_proposal(
	position: Vector2,
	profile,
	spawner,
	spawner_index: int,
	spawn_index: int,
	spawn_count: int,
	initial_horde: bool
) -> Dictionary:
	return {
		"position": position,
		"profile": profile,
		"source_spawner": spawner,
		"spawner_index": spawner_index,
		"spawn_index": spawn_index,
		"spawn_count": spawn_count,
		"initial_horde": initial_horde,
		"room_id": _spawn_room_id,
		"generation": _spawn_generation,
		"retry_count": 0
	}


func apply_damage(target: Node, packet) -> bool:
	if target == null or packet == null or not is_instance_valid(target):
		return false
	if not target.is_in_group("spawners") or not target.has_method("take_damage"):
		return false
	if not _spawners.has(target):
		return false
	var damage_packet = packet
	if _should_apply_pressure_damage(target, packet):
		damage_packet = packet.copy_with_damage_bonus(pressure_damage_bonus)
	return bool(target.take_damage(damage_packet))


func apply_healing(target: Node, amount: int) -> bool:
	if target == null or amount <= 0 or not is_instance_valid(target):
		return false
	if not target.is_in_group("spawners") or not _spawners.has(target):
		return false
	if not target.has_method("apply_healing"):
		return false
	return bool(target.apply_healing(amount))


func get_nearby_spawners(origin: Vector2, radius: float, excluded: Array[Node]) -> Array:
	var candidates: Array = []
	var radius_squared := radius * radius
	for spawner in _spawners:
		if not is_instance_valid(spawner) or excluded.has(spawner):
			continue
		if spawner.global_position.distance_squared_to(origin) <= radius_squared:
			candidates.append(spawner)
	return candidates


func get_repairable_spawners(origin: Vector2, radius: float, health_ratio_threshold: float) -> Array:
	var candidates: Array = []
	var effective_radius: float = max(radius, 0.0)
	var radius_squared: float = effective_radius * effective_radius
	var threshold: float = clamp(health_ratio_threshold, 0.0, 1.0)
	for spawner in _spawners:
		if not is_instance_valid(spawner) or not spawner.has_method("apply_healing"):
			continue
		var spawner_health: int = int(spawner.get("health"))
		var spawner_max_health: int = int(spawner.get("max_health"))
		if spawner_health <= 0 or spawner_max_health <= 0 or spawner_health >= spawner_max_health:
			continue
		var health_ratio: float = float(spawner_health) / float(spawner_max_health)
		if health_ratio > threshold:
			continue
		if spawner.global_position.distance_squared_to(origin) > radius_squared:
			continue
		candidates.append(spawner)
	return candidates


func get_spawner_count() -> int:
	return _spawners.size()


func get_spawner_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for spawner in _spawners:
		if is_instance_valid(spawner):
			positions.append(spawner.global_position)
	return positions


func _on_spawner_health_depleted(spawner) -> void:
	if not _spawners.has(spawner):
		return
	_spawners.erase(spawner)
	spawner_destroyed.emit(spawner, spawner.score_value)
	spawner_count_changed.emit(_spawners.size())
	spawner.queue_free()


func _on_spawner_shot_ready(_spawner, origin: Vector2, direction: Vector2, shot_config: Dictionary) -> void:
	if not enabled or direction.length_squared() <= 0.001:
		return
	hostile_shot_requested.emit(origin, direction, shot_config)


func _get_spawner_placements() -> Array:
	if _level_definition != null and not _level_definition.spawner_placements.is_empty():
		return _level_definition.spawner_placements
	var placements: Array = []
	var positions := _get_spawner_positions()
	for index in range(positions.size()):
		var placement = SPAWNER_PLACEMENT_SCRIPT.new()
		placement.position = positions[index]
		placement.profile = default_spawner_profile
		placement.warmup_seconds = 1.0 + float(index) * 0.55
		placements.append(placement)
	return placements


func _get_spawner_positions() -> Array[Vector2]:
	if _level_definition != null and not _level_definition.spawner_positions.is_empty():
		return _level_definition.spawner_positions
	if _level_definition != null and not bool(_level_definition.get("use_default_spawners")):
		return []
	return [
		Vector2(-520.0, -260.0),
		Vector2(520.0, -260.0),
		Vector2(-520.0, 260.0),
		Vector2(520.0, 260.0)
	]


func _get_max_active_enemies() -> int:
	if _level_definition != null:
		return _level_definition.max_active_enemies
	return max_active_enemies


func _get_spawner_health() -> int:
	if _level_definition != null:
		return _level_definition.spawner_health
	return default_spawner_health


func _get_spawn_interval() -> float:
	var interval := default_spawn_interval
	if _level_definition != null:
		interval = _level_definition.spawn_interval
	return _scale_spawn_interval_for_floor(interval)


func _scale_spawn_interval_for_floor(base_interval: float) -> float:
	return max(float(base_interval) * _get_floor_spawn_interval_multiplier(), minimum_scaled_spawn_interval)


func _get_floor_spawn_interval_multiplier() -> float:
	var current_floor := 1
	if _level_definition != null and _level_definition.get("floor_number") != null:
		current_floor = max(int(_level_definition.floor_number), 1)
	var floor_pressure: float = float(current_floor - 1) * spawn_interval_floor_step
	return max(floor_one_spawn_interval_multiplier - floor_pressure, minimum_floor_spawn_interval_multiplier)


func _get_spawner_radius() -> float:
	if _level_definition != null:
		return _level_definition.spawner_radius
	return default_spawner_radius


func _get_spawner_spawn_batch_count(spawner) -> int:
	if spawner != null and is_instance_valid(spawner):
		return max(int(spawner.spawn_batch_count), 1)
	return 1


func _get_initial_spawn_batch_count(spawner) -> int:
	return _get_spawner_spawn_batch_count(spawner) * max(_get_initial_spawn_batch_multiplier(), 0)


func _get_initial_spawn_batch_multiplier() -> int:
	if _level_definition != null:
		var override_value = _level_definition.get("initial_spawn_batch_multiplier_override")
		if override_value != null and int(override_value) >= 0:
			return int(override_value)
	return max(initial_spawn_batch_multiplier, 0)


func _get_initial_spawn_shield_delay() -> float:
	var delay := 0.0
	for spawner in _spawners:
		if is_instance_valid(spawner):
			delay = max(delay, float(spawner.projectile_shield_lead_seconds))
	return delay


func _get_initial_spawn_position(spawner, spawner_index: int, spawn_index: int, spawn_count: int) -> Vector2:
	var distance: float = max(float(spawner.body_radius) + 46.0, 64.0)
	var phase: float = float(spawner_index) * 0.09
	return _get_biased_spawn_position(spawner, spawn_index, spawn_count, distance, deg_to_rad(initial_spawn_player_bias_fan_degrees), phase)


func _get_spawn_position_around_spawner(spawner, spawn_index: int, spawn_count: int) -> Vector2:
	if spawner == null or not is_instance_valid(spawner):
		return Vector2.ZERO
	var distance: float = max(float(spawner.body_radius) + 36.0, 54.0)
	return _get_biased_spawn_position(spawner, spawn_index, spawn_count, distance, deg_to_rad(spawn_player_bias_fan_degrees))


func _get_biased_spawn_position(spawner, spawn_index: int, spawn_count: int, base_distance: float, fan_radians: float, phase: float = 0.0) -> Vector2:
	if spawner == null or not is_instance_valid(spawner):
		return Vector2.ZERO
	var bias_direction: Vector2 = _get_spawn_bias_direction(spawner)
	var count: int = max(spawn_count, 1)
	var fan_offset: float = _get_spawn_fan_offset(spawn_index, count, fan_radians) + phase
	var radial_stagger: float = _get_spawn_radial_stagger(spawn_index, count)
	for attempt in range(14):
		var side_step: float = 0.0
		if attempt > 0:
			var side_sign: float = -1.0 if attempt % 2 == 1 else 1.0
			side_step = side_sign * floor(float(attempt + 1) * 0.5) * 0.24
		var distance: float = max(base_distance + radial_stagger + floor(float(attempt) / 4.0) * 18.0, float(spawner.body_radius) + 28.0)
		var angle: float = bias_direction.angle() + fan_offset + side_step
		var candidate: Vector2 = _constrain_spawn_position(spawner.global_position + Vector2.RIGHT.rotated(angle) * distance, 24.0)
		if _spawn_position_is_valid(candidate, 24.0):
			return candidate
	var fallback_origin: Vector2 = spawner.global_position + Vector2.RIGHT.rotated(
		bias_direction.angle() + fan_offset
	) * base_distance
	return _find_safe_interior_spawn_position(fallback_origin, 24.0)


func _get_spawn_bias_direction(spawner) -> Vector2:
	if spawner == null or not is_instance_valid(spawner):
		return Vector2.RIGHT
	var to_player: Vector2 = _get_player_position() - spawner.global_position
	if to_player.length_squared() <= 0.001:
		return Vector2.RIGHT
	return to_player.normalized()


func _get_spawn_fan_offset(spawn_index: int, spawn_count: int, fan_radians: float) -> float:
	if spawn_count <= 1:
		return 0.0
	var ratio: float = clamp(float(spawn_index) / float(max(spawn_count - 1, 1)), 0.0, 1.0)
	return lerp(-fan_radians * 0.5, fan_radians * 0.5, ratio)


func _get_spawn_radial_stagger(spawn_index: int, spawn_count: int) -> float:
	if spawn_count <= 2:
		return 0.0
	return (float(spawn_index % 3) - 1.0) * 10.0


func _spawn_position_is_valid(position: Vector2, clearance: float) -> bool:
	if position == Vector2.INF:
		return false
	var reconstrained: Vector2 = _constrain_spawn_position(position, clearance)
	if reconstrained.distance_squared_to(position) > 0.25:
		return false
	return _position_is_clear_of_walls(position, clearance)


func _find_safe_interior_spawn_position(origin: Vector2, clearance: float) -> Vector2:
	var candidates: Array[Vector2] = []
	var search_rects: Array[Rect2] = _playable_rects.duplicate()
	if search_rects.is_empty():
		search_rects.append(_arena_bounds)
	for playable_rect in search_rects:
		var safe_rect: Rect2 = playable_rect.grow(-clearance)
		if safe_rect.size.x <= 1.0 or safe_rect.size.y <= 1.0:
			continue
		for y_ratio in [0.2, 0.5, 0.8]:
			for x_ratio in [0.2, 0.5, 0.8]:
				candidates.append(Vector2(
					lerp(safe_rect.position.x, safe_rect.end.x, float(x_ratio)),
					lerp(safe_rect.position.y, safe_rect.end.y, float(y_ratio))
				))
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		return a.distance_squared_to(origin) < b.distance_squared_to(origin)
	)
	for candidate in candidates:
		if _spawn_position_is_valid(candidate, clearance):
			return candidate
	return Vector2.INF


func _position_is_clear_of_walls(position: Vector2, clearance: float = 24.0) -> bool:
	if _level_definition == null:
		return true
	for wall_rect in _wall_rects:
		if wall_rect.grow(clearance).has_point(position):
			return false
	for void_rect in _void_rects:
		if void_rect.grow(clearance).has_point(position):
			return false
	for exclusion_rect in _spawn_exclusion_rects:
		if exclusion_rect.grow(clearance).has_point(position):
			return false
	return true


func _constrain_spawn_position(position: Vector2, clearance: float) -> Vector2:
	var blockers: Array[Rect2] = []
	blockers.append_array(_wall_rects)
	blockers.append_array(_void_rects)
	blockers.append_array(_spawn_exclusion_rects)
	return ArenaGeometry.constrain_point_to_playable_regions(position, _arena_bounds, _arena_shape, _playable_rects, blockers, clearance)


func _get_playable_rects(level_definition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition == null:
		return rects
	if level_definition.has_meta("active_room_playable_rects"):
		var active_rects_value: Variant = level_definition.get_meta("active_room_playable_rects")
		if active_rects_value is Array:
			for active_rect in active_rects_value:
				if active_rect is Rect2:
					rects.append(active_rect)
			if not rects.is_empty():
				return rects
	if level_definition.has_meta("active_room_id") and level_definition.has_meta("active_room_bounds"):
		var active_room_id := String(level_definition.get_meta("active_room_id", ""))
		var active_room_bounds_value: Variant = level_definition.get_meta("active_room_bounds")
		if not active_room_id.is_empty() and active_room_bounds_value is Rect2:
			var active_room_bounds: Rect2 = active_room_bounds_value
			if active_room_bounds.size != Vector2.ZERO:
				rects.append(active_room_bounds)
				return rects
	if not level_definition.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level_definition.arena_bounds, level_definition.get_meta("footprint_cells")))
	return rects


func _get_level_collision_rects(level_definition, meta_key: String, fallback: Array[Rect2]) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition != null and level_definition.has_meta(meta_key):
		var meta_value: Variant = level_definition.get_meta(meta_key)
		if meta_value is Array:
			for rect in meta_value:
				if rect is Rect2:
					rects.append(rect)
			if not rects.is_empty():
				return rects
	rects.append_array(fallback)
	return rects


func _apply_spawner_separation() -> void:
	if spawner_separation_force <= 0.0 or _spawners.size() < 2:
		return
	var valid_spawners: Array = []
	var pushes: Array[Vector2] = []
	for spawner in _spawners:
		if is_instance_valid(spawner) and spawner.has_method("apply_crowd_separation"):
			valid_spawners.append(spawner)
			pushes.append(Vector2.ZERO)
	for first_index in range(valid_spawners.size()):
		for second_index in range(first_index + 1, valid_spawners.size()):
			_apply_spawner_separation_pair(first_index, second_index, valid_spawners, pushes)
	for index in range(valid_spawners.size()):
		if pushes[index].length_squared() > 0.001:
			valid_spawners[index].apply_crowd_separation(pushes[index])


func _apply_spawner_separation_pair(first_index: int, second_index: int, valid_spawners: Array, pushes: Array[Vector2]) -> void:
	var first = valid_spawners[first_index]
	var second = valid_spawners[second_index]
	var separation: Vector2 = first.global_position - second.global_position
	var desired_distance: float = float(first.body_radius) + float(second.body_radius) + spawner_separation_padding
	var distance_squared: float = separation.length_squared()
	if distance_squared > desired_distance * desired_distance:
		return
	var direction: Vector2 = Vector2.RIGHT.rotated(float((first.get_instance_id() + second.get_instance_id()) % 628) * 0.01)
	var distance := 0.0
	if distance_squared > 0.001:
		distance = sqrt(distance_squared)
		direction = separation / distance
	var strength: float = (1.0 - clamp(distance / desired_distance, 0.0, 1.0)) * spawner_separation_force
	pushes[first_index] += direction * strength
	pushes[second_index] -= direction * strength


func _should_apply_pressure_damage(target: Node, packet) -> bool:
	if pressure_damage_bonus <= 0 or pressure_damage_distance <= 0.0:
		return false
	if not packet.has_method("copy_with_damage_bonus"):
		return false
	var source_position: Vector2 = packet.source_position
	if source_position.distance_squared_to(target.global_position) <= 0.001:
		return false
	var pressure_distance: float = pressure_damage_distance + float(target.body_radius)
	return source_position.distance_squared_to(target.global_position) <= pressure_distance * pressure_distance


func _get_player_position() -> Vector2:
	if _player_provider.is_valid():
		return _player_provider.call()
	return Vector2.ZERO
