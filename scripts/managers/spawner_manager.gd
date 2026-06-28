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

const SPAWNER_PLACEMENT_SCRIPT := preload("res://scripts/resources/spawner_placement.gd")

var enabled: bool = false
var _spawner_layer: Node = null
var _spawners: Array = []
var _current_enemy_count: int = 0
var _level_definition = null
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _player_provider: Callable


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
	spawner_count_changed.emit(_spawners.size())


func clear_spawners() -> void:
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	_spawners.clear()
	spawner_count_changed.emit(0)


func set_enabled(value: bool) -> void:
	enabled = value
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.set_enabled(value)


func set_enemy_count(count: int) -> void:
	_current_enemy_count = count


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)


func _process(_delta: float) -> void:
	var player_position := _get_player_position()
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.set_target_position(player_position)


func _spawn_spawner(placement, index: int) -> void:
	var profile = default_spawner_profile
	var spawn_position := Vector2.ZERO
	var warmup := 1.0 + float(index) * 0.55
	if placement != null:
		profile = placement.profile if placement.profile != null else default_spawner_profile
		spawn_position = placement.position
		warmup = placement.warmup_seconds
	var spawner = spawner_scene.instantiate()
	spawner.global_position = ArenaGeometry.constrain_point(spawn_position, _arena_bounds, _arena_shape)
	spawner.warmup_seconds = warmup
	if profile != null and spawner.has_method("initialize_from_profile"):
		spawner.initialize_from_profile(profile)
	else:
		spawner.initialize(_get_spawner_health(), _get_spawn_interval(), _get_spawner_radius())
	spawner.spawn_ready.connect(_on_spawner_spawn_ready)
	spawner.health_depleted.connect(_on_spawner_health_depleted)
	spawner.shot_ready.connect(_on_spawner_shot_ready)
	if _spawner_layer != null:
		_spawner_layer.add_child(spawner)
	else:
		add_child(spawner)
	_spawners.append(spawner)


func _on_spawner_spawn_ready(_spawner, spawn_position: Vector2) -> void:
	if not enabled or _current_enemy_count >= max_active_enemies:
		return
	var profile = _spawner.enemy_profile if _spawner != null and _spawner.enemy_profile != null else default_enemy_profile
	spawn_requested.emit(spawn_position, profile)


func apply_damage(target: Node, packet) -> void:
	if target == null or packet == null or not is_instance_valid(target):
		return
	if not target.is_in_group("spawners") or not target.has_method("take_damage"):
		return
	if not _spawners.has(target):
		return
	target.take_damage(packet)


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
	if _level_definition != null:
		return _level_definition.spawn_interval
	return default_spawn_interval


func _get_spawner_radius() -> float:
	if _level_definition != null:
		return _level_definition.spawner_radius
	return default_spawner_radius


func _get_player_position() -> Vector2:
	if _player_provider.is_valid():
		return _player_provider.call()
	return Vector2.ZERO
