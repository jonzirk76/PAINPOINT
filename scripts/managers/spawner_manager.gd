extends Node
class_name SpawnerManager

signal spawn_requested(spawn_position: Vector2, profile)
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
var _player_provider: Callable
var _initial_spawns_pending: bool = false
var _initial_spawn_delay_remaining: float = 0.0
var _preloaded_initial_spawn_activation_pending: bool = false


func initialize(context: Dictionary) -> void:
	_spawner_layer = context.get("spawner_layer", null)
	_player_provider = context.get("player_position_provider", Callable())


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
	if not _initial_spawns_pending or initial_spawn_batch_multiplier <= 0:
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
			requests.append({"position": spawn_position, "profile": profile})
			projected_enemy_count += 1
	_initial_spawns_pending = false
	_initial_spawn_delay_remaining = 0.0
	_preloaded_initial_spawn_activation_pending = not requests.is_empty()
	return requests


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_level_wall_rects = level_definition.wall_rects
	_wall_rects = _level_wall_rects.duplicate()
	_void_rects = level_definition.void_rects
	_playable_rects = _get_playable_rects(level_definition)
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
	if _spawner_layer != null:
		_spawner_layer.add_child(spawner)
	else:
		add_child(spawner)
	if spawner_birth_animation_seconds > 0.0 and spawner.has_method("play_birth_animation"):
		spawner.play_birth_animation(spawner_birth_animation_seconds)
	_spawners.append(spawner)


func _on_spawner_spawn_ready(_spawner, spawn_position: Vector2) -> void:
	if not enabled or _current_enemy_count >= max_active_enemies:
		return
	var profile = _spawner.enemy_profile if _spawner != null and _spawner.enemy_profile != null else default_enemy_profile
	var batch_count := _get_spawner_spawn_batch_count(_spawner)
	var projected_enemy_count := _current_enemy_count
	for spawn_index in range(batch_count):
		if projected_enemy_count >= max_active_enemies:
			return
		var batch_position := _get_spawn_position_around_spawner(_spawner, spawn_index, batch_count)
		spawn_requested.emit(batch_position, profile)
		projected_enemy_count += 1


func _begin_initial_spawn_sequence() -> void:
	if initial_spawn_batch_multiplier <= 0:
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
	if initial_spawn_batch_multiplier <= 0:
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
			spawn_requested.emit(spawn_position, profile)
			projected_enemy_count += 1


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


func get_nearby_spawners(origin: Vector2, radius: float, excluded: Array[Node]) -> Array:
	var candidates: Array = []
	var radius_squared := radius * radius
	for spawner in _spawners:
		if not is_instance_valid(spawner) or excluded.has(spawner):
			continue
		if spawner.global_position.distance_squared_to(origin) <= radius_squared:
			candidates.append(spawner)
	return candidates


func get_spawner_count() -> int:
	return _spawners.size()


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
	return _get_spawner_spawn_batch_count(spawner) * max(initial_spawn_batch_multiplier, 1)


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
			var sign: float = -1.0 if attempt % 2 == 1 else 1.0
			side_step = sign * floor(float(attempt + 1) * 0.5) * 0.24
		var distance: float = max(base_distance + radial_stagger + floor(float(attempt) / 4.0) * 18.0, float(spawner.body_radius) + 28.0)
		var angle: float = bias_direction.angle() + fan_offset + side_step
		var candidate: Vector2 = _constrain_spawn_position(spawner.global_position + Vector2.RIGHT.rotated(angle) * distance, 24.0)
		if _position_is_clear_of_walls(candidate):
			return candidate
	return spawner.global_position


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


func _position_is_clear_of_walls(position: Vector2) -> bool:
	if _level_definition == null:
		return true
	for wall_rect in _level_definition.wall_rects:
		if wall_rect.grow(24.0).has_point(position):
			return false
	for void_rect in _level_definition.void_rects:
		if void_rect.grow(24.0).has_point(position):
			return false
	return true


func _constrain_spawn_position(position: Vector2, clearance: float) -> Vector2:
	var blockers: Array[Rect2] = []
	blockers.append_array(_wall_rects)
	blockers.append_array(_void_rects)
	return ArenaGeometry.constrain_point_to_playable_regions(position, _arena_bounds, _arena_shape, _playable_rects, blockers, clearance)


func _get_playable_rects(level_definition) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if level_definition == null or not level_definition.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level_definition.arena_bounds, level_definition.get_meta("footprint_cells")))
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
