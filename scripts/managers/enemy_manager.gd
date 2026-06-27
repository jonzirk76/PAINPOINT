extends Node
class_name EnemyManager

signal enemy_defeated(enemy, score_value: int)
signal enemy_count_changed(count: int)
signal player_contact_requested(enemy, player, damage: int)

@export var enemy_scene: PackedScene = preload("res://scenes/entities/enemy_entity.tscn")
@export var default_enemy_profile: Resource = preload("res://resources/enemies/basic_enemy.tres")

var enabled: bool = false
var _enemy_layer: Node = null
var _player_provider: Callable
var _player_ref_provider: Callable
var _enemies: Array = []
var _contact_timers: Dictionary = {}
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0


func initialize(context: Dictionary) -> void:
	_enemy_layer = context.get("enemy_layer", null)
	_player_provider = context.get("player_position_provider", Callable())
	_player_ref_provider = context.get("player_ref_provider", Callable())


func reset_run() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	_contact_timers.clear()
	enemy_count_changed.emit(0)


func set_enabled(value: bool) -> void:
	enabled = value


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.set_arena_definition(_arena_bounds, _arena_shape)


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	var player_position := _get_player_position()
	var player = _get_player_ref()
	for enemy in _enemies.duplicate():
		if not is_instance_valid(enemy):
			_enemies.erase(enemy)
			continue
		enemy.set_target_position(player_position)
		var id: int = enemy.get_instance_id()
		_contact_timers[id] = max(float(_contact_timers.get(id, 0.0)) - delta, 0.0)
		if player != null and is_instance_valid(player):
			var contact_range: float = enemy.contact_radius
			if enemy.global_position.distance_squared_to(player.global_position) <= contact_range * contact_range and float(_contact_timers[id]) <= 0.0:
				_contact_timers[id] = enemy.contact_cooldown
				player_contact_requested.emit(enemy, player, enemy.contact_damage)


func spawn_enemy(profile, spawn_position: Vector2):
	if not enabled:
		return null
	var enemy = enemy_scene.instantiate()
	var selected_profile = profile if profile != null else default_enemy_profile
	enemy.initialize(selected_profile)
	enemy.global_position = ArenaGeometry.constrain_point(spawn_position, _arena_bounds, _arena_shape)
	enemy.set_arena_definition(_arena_bounds, _arena_shape)
	if _enemy_layer != null:
		_enemy_layer.add_child(enemy)
	else:
		add_child(enemy)
	enemy.health_depleted.connect(_on_enemy_health_depleted)
	_enemies.append(enemy)
	enemy_count_changed.emit(_enemies.size())
	return enemy


func apply_damage(target: Node, packet) -> void:
	if target == null or packet == null or not is_instance_valid(target):
		return
	if not target.is_in_group("enemies") or not target.has_method("take_damage"):
		return
	var enemy = target
	if not _enemies.has(enemy):
		return
	enemy.take_damage(packet)


func get_nearby_enemies(origin: Vector2, radius: float, excluded: Array[Node]) -> Array:
	var candidates: Array = []
	var radius_squared := radius * radius
	for enemy in _enemies:
		if not is_instance_valid(enemy) or excluded.has(enemy):
			continue
		if enemy.global_position.distance_squared_to(origin) <= radius_squared:
			candidates.append(enemy)
	candidates.sort_custom(func(a, b) -> bool:
		return a.global_position.distance_squared_to(origin) < b.global_position.distance_squared_to(origin)
	)
	return candidates


func get_enemy_count() -> int:
	return _enemies.size()


func _on_enemy_health_depleted(enemy) -> void:
	if not _enemies.has(enemy):
		return
	_enemies.erase(enemy)
	_contact_timers.erase(enemy.get_instance_id())
	enemy_defeated.emit(enemy, enemy.score_value)
	enemy_count_changed.emit(_enemies.size())


func _get_player_position() -> Vector2:
	if _player_provider.is_valid():
		return _player_provider.call()
	return Vector2.ZERO


func _get_player_ref():
	if _player_ref_provider.is_valid():
		var player = _player_ref_provider.call()
		if player != null and is_instance_valid(player) and player.is_in_group("player"):
			return player
	return null
