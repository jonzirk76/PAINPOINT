extends Node
class_name PlayerManager

signal player_spawned(player)
signal player_health_changed(old_value: int, new_value: int)
signal player_invulnerability_changed(remaining: float, duration: float)
signal player_defeated(player)
signal shoot_requested(origin: Vector2, direction: Vector2)

@export var player_scene: PackedScene = preload("res://scenes/entities/player_entity.tscn")
@export var spawn_position: Vector2 = Vector2.ZERO
@export var base_fire_cooldown: float = 0.09
@export var damage_invulnerability_seconds: float = 0.6

var player = null
var enabled: bool = false
var _player_layer: Node = null
var _fire_cooldown_remaining: float = 0.0
var _fire_cooldown_multiplier: float = 1.0
var _damage_cooldown_remaining: float = 0.0
var _last_invulnerability_remaining: float = -1.0
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))


func initialize(context: Dictionary) -> void:
	_player_layer = context.get("player_layer", null)


func reset_run() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = player_scene.instantiate()
	player.global_position = spawn_position
	player.arena_bounds = _arena_bounds
	if _player_layer != null:
		_player_layer.add_child(player)
	else:
		add_child(player)
	player.health_changed.connect(_on_player_health_changed)
	player.health_depleted.connect(_on_player_health_depleted)
	_fire_cooldown_remaining = 0.0
	_damage_cooldown_remaining = 0.0
	_last_invulnerability_remaining = -1.0
	_sync_invulnerability_state()
	player_spawned.emit(player)
	player_health_changed.emit(player.health, player.health)


func clear_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	_fire_cooldown_remaining = 0.0
	_damage_cooldown_remaining = 0.0
	player_health_changed.emit(0, 0)


func set_enabled(value: bool) -> void:
	enabled = value


func _process(delta: float) -> void:
	if _fire_cooldown_remaining > 0.0:
		_fire_cooldown_remaining = max(_fire_cooldown_remaining - delta, 0.0)
	if _damage_cooldown_remaining > 0.0:
		_damage_cooldown_remaining = max(_damage_cooldown_remaining - delta, 0.0)
	if _damage_cooldown_remaining > 0.0 or _last_invulnerability_remaining > 0.0:
		_sync_invulnerability_state()


func set_move_vector(vector: Vector2) -> void:
	if not _has_player():
		return
	player.set_move_vector(vector if enabled else Vector2.ZERO)


func set_aim_direction(direction: Vector2) -> void:
	if not _has_player():
		return
	player.set_aim_direction(direction)


func request_fire(direction: Vector2) -> void:
	if not enabled or not _has_player():
		return
	if direction.length_squared() <= 0.001 or _fire_cooldown_remaining > 0.0:
		return
	player.set_aim_direction(direction)
	_fire_cooldown_remaining = base_fire_cooldown * _fire_cooldown_multiplier
	shoot_requested.emit(player.get_fire_origin(), direction.normalized())


func apply_damage(amount: int) -> void:
	if not enabled or not _has_player() or _damage_cooldown_remaining > 0.0:
		return
	var old_health: int = player.health
	player.take_damage(amount)
	if player.health < old_health:
		player.play_hit_response()
	if player.health > 0:
		_damage_cooldown_remaining = damage_invulnerability_seconds
		_sync_invulnerability_state()


func set_weapon_modifiers(modifiers: Dictionary) -> void:
	_fire_cooldown_multiplier = float(modifiers.get("fire_cooldown_multiplier", 1.0))
	if _has_player():
		player.set_speed_multiplier(float(modifiers.get("move_speed_multiplier", 1.0)))


func set_arena_bounds(bounds: Rect2) -> void:
	_arena_bounds = bounds
	if _has_player():
		player.set_arena_bounds(bounds)


func get_player_position() -> Vector2:
	if _has_player():
		return player.global_position
	return spawn_position


func get_player_health() -> int:
	if _has_player():
		return player.health
	return 0


func get_player_max_health() -> int:
	if _has_player():
		return player.max_health
	return 0


func get_invulnerability_remaining() -> float:
	return _damage_cooldown_remaining


func get_invulnerability_duration() -> float:
	return damage_invulnerability_seconds


func _has_player() -> bool:
	return player != null and is_instance_valid(player)


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	player_health_changed.emit(old_value, new_value)


func _on_player_health_depleted(entity) -> void:
	enabled = false
	_damage_cooldown_remaining = 0.0
	_sync_invulnerability_state()
	if _has_player():
		player.play_death_animation()
	player_defeated.emit(entity)


func _sync_invulnerability_state() -> void:
	_last_invulnerability_remaining = _damage_cooldown_remaining
	if _has_player():
		player.set_invulnerability_state(_damage_cooldown_remaining, damage_invulnerability_seconds)
	player_invulnerability_changed.emit(_damage_cooldown_remaining, damage_invulnerability_seconds)
