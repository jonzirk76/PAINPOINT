extends Node
class_name SpawnerManager

signal spawn_requested(spawn_position: Vector2, profile)
signal spawner_count_changed(count: int)
signal spawner_destroyed(spawner, score_value: int)

@export var spawner_scene: PackedScene = preload("res://scenes/entities/enemy_spawner_entity.tscn")
@export var default_enemy_profile: Resource = preload("res://resources/enemies/basic_enemy.tres")
@export var max_active_enemies: int = 18
@export var default_spawner_health: int = 18
@export var default_spawn_interval: float = 2.8
@export var default_spawner_radius: float = 32.0

var enabled: bool = false
var _spawner_layer: Node = null
var _spawners: Array = []
var _current_enemy_count: int = 0
var _level_definition = null


func initialize(context: Dictionary) -> void:
	_spawner_layer = context.get("spawner_layer", null)


func reset_run(level_definition = null) -> void:
	_level_definition = level_definition
	clear_spawners()
	var positions: Array[Vector2] = _get_spawner_positions()
	max_active_enemies = _get_max_active_enemies()
	for index in range(positions.size()):
		_spawn_spawner(positions[index], 1.0 + float(index) * 0.55)
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


func _spawn_spawner(spawn_position: Vector2, warmup: float) -> void:
	var spawner = spawner_scene.instantiate()
	spawner.global_position = spawn_position
	spawner.warmup_seconds = warmup
	spawner.initialize(_get_spawner_health(), _get_spawn_interval(), _get_spawner_radius())
	spawner.spawn_ready.connect(_on_spawner_spawn_ready)
	spawner.health_depleted.connect(_on_spawner_health_depleted)
	if _spawner_layer != null:
		_spawner_layer.add_child(spawner)
	else:
		add_child(spawner)
	_spawners.append(spawner)


func _on_spawner_spawn_ready(_spawner, spawn_position: Vector2) -> void:
	if not enabled or _current_enemy_count >= max_active_enemies:
		return
	spawn_requested.emit(spawn_position, default_enemy_profile)


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
