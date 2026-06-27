extends Node
class_name SpawnerManager

signal spawn_requested(spawn_position: Vector2, profile)
signal spawner_count_changed(count: int)

@export var spawner_scene: PackedScene = preload("res://scenes/entities/enemy_spawner_entity.tscn")
@export var default_enemy_profile: Resource = preload("res://resources/enemies/basic_enemy.tres")
@export var max_active_enemies: int = 18

var enabled: bool = false
var _spawner_layer: Node = null
var _spawners: Array = []
var _current_enemy_count: int = 0


func initialize(context: Dictionary) -> void:
	_spawner_layer = context.get("spawner_layer", null)


func reset_run() -> void:
	for spawner in _spawners:
		if is_instance_valid(spawner):
			spawner.queue_free()
	_spawners.clear()
	var positions := [
		Vector2(-520.0, -260.0),
		Vector2(520.0, -260.0),
		Vector2(-520.0, 260.0),
		Vector2(520.0, 260.0)
	]
	for index in range(positions.size()):
		_spawn_spawner(positions[index], 1.0 + float(index) * 0.55)
	spawner_count_changed.emit(_spawners.size())


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
	spawner.spawn_ready.connect(_on_spawner_spawn_ready)
	if _spawner_layer != null:
		_spawner_layer.add_child(spawner)
	else:
		add_child(spawner)
	_spawners.append(spawner)


func _on_spawner_spawn_ready(_spawner, spawn_position: Vector2) -> void:
	if not enabled or _current_enemy_count >= max_active_enemies:
		return
	spawn_requested.emit(spawn_position, default_enemy_profile)
