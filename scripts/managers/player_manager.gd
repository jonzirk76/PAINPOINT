extends Node
class_name PlayerManager

signal player_spawned(player)
signal player_health_changed(old_value: int, new_value: int)
signal player_invulnerability_changed(remaining: float, duration: float)
signal player_defeated(player)
signal shoot_requested(origin: Vector2, direction: Vector2)
signal parry_requested(origin: Vector2, effect_radius: float, perfect_radius: float, enemy_knockback: float)
signal parry_cooldown_changed(remaining: float, duration: float)
signal super_meter_changed(current: float, maximum: float, is_charging: bool, charge_ratio: float)
signal super_shot_requested(origin: Vector2, direction: Vector2, charge_ratio: float)

@export var player_scene: PackedScene = preload("res://scenes/entities/player_entity.tscn")
@export var spawn_position: Vector2 = Vector2.ZERO
@export var base_fire_cooldown: float = 0.09
@export var damage_invulnerability_seconds: float = 0.6
@export var parry_cooldown_seconds: float = 8.0
@export var parry_effect_radius: float = 154.0
@export var parry_perfect_radius: float = 42.0
@export var parry_enemy_knockback: float = 430.0
@export var super_meter_max: float = 100.0
@export var super_meter_enemy_kill_gain: float = 6.0
@export var super_meter_parried_bullet_gain: float = 3.0
@export var super_meter_perfect_bullet_gain: float = 18.0
@export var super_charge_seconds: float = 1.15
@export var super_charge_speed_multiplier: float = 0.72

var player = null
var enabled: bool = false
var _player_layer: Node = null
var _fire_cooldown_remaining: float = 0.0
var _fire_cooldown_multiplier: float = 1.0
var _move_speed_multiplier: float = 1.0
var _damage_cooldown_remaining: float = 0.0
var _last_invulnerability_remaining: float = -1.0
var _parry_cooldown_remaining: float = 0.0
var _last_parry_cooldown_remaining: float = -1.0
var _super_meter: float = 0.0
var _super_is_charging: bool = false
var _super_charge_elapsed: float = 0.0
var _last_super_ready: bool = false
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0


func initialize(context: Dictionary) -> void:
	_player_layer = context.get("player_layer", null)


func reset_run() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = player_scene.instantiate()
	player.global_position = spawn_position
	player.set_arena_definition(_arena_bounds, _arena_shape)
	if _player_layer != null:
		_player_layer.add_child(player)
	else:
		add_child(player)
	player.health_changed.connect(_on_player_health_changed)
	player.health_depleted.connect(_on_player_health_depleted)
	_fire_cooldown_remaining = 0.0
	_damage_cooldown_remaining = 0.0
	_last_invulnerability_remaining = -1.0
	_parry_cooldown_remaining = 0.0
	_last_parry_cooldown_remaining = -1.0
	_super_meter = 0.0
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	_last_super_ready = false
	_sync_invulnerability_state()
	_sync_parry_state()
	_sync_player_speed()
	_sync_super_meter_state()
	player_spawned.emit(player)
	player_health_changed.emit(player.health, player.health)


func clear_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	_fire_cooldown_remaining = 0.0
	_damage_cooldown_remaining = 0.0
	_parry_cooldown_remaining = 0.0
	_super_meter = 0.0
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	_last_super_ready = false
	player_health_changed.emit(0, 0)
	_sync_parry_state()
	_sync_super_meter_state()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_cancel_super_charge(true)
		if _has_player():
			player.stop_movement()


func _process(delta: float) -> void:
	if _fire_cooldown_remaining > 0.0:
		_fire_cooldown_remaining = max(_fire_cooldown_remaining - delta, 0.0)
	if _damage_cooldown_remaining > 0.0:
		_damage_cooldown_remaining = max(_damage_cooldown_remaining - delta, 0.0)
	if _damage_cooldown_remaining > 0.0 or _last_invulnerability_remaining > 0.0:
		_sync_invulnerability_state()
	if _parry_cooldown_remaining > 0.0:
		_parry_cooldown_remaining = max(_parry_cooldown_remaining - delta, 0.0)
	if _parry_cooldown_remaining > 0.0 or _last_parry_cooldown_remaining > 0.0:
		_sync_parry_state()
	if _super_is_charging:
		_super_charge_elapsed = min(_super_charge_elapsed + delta, max(super_charge_seconds, 0.01))
		if _has_player() and player.has_method("set_super_charge_state"):
			player.set_super_charge_state(true, get_super_charge_ratio())
		_sync_super_meter_state()


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
	if _super_is_charging:
		return
	if direction.length_squared() <= 0.001 or _fire_cooldown_remaining > 0.0:
		return
	if player.has_method("play_shoot_pose"):
		player.play_shoot_pose(direction)
	else:
		player.set_aim_direction(direction)
	_fire_cooldown_remaining = base_fire_cooldown * _fire_cooldown_multiplier
	shoot_requested.emit(player.get_fire_origin(), direction.normalized())


func request_parry() -> void:
	if not enabled or not _has_player() or _parry_cooldown_remaining > 0.0:
		return
	_parry_cooldown_remaining = parry_cooldown_seconds
	if player.has_method("play_parry_response"):
		player.play_parry_response(parry_effect_radius, parry_perfect_radius)
	_sync_parry_state()
	parry_requested.emit(player.global_position, parry_effect_radius, parry_perfect_radius, parry_enemy_knockback)


func request_super_charge_start() -> void:
	if not enabled or not _has_player() or _super_is_charging:
		return
	if not is_super_ready():
		return
	_super_is_charging = true
	_super_charge_elapsed = 0.0
	if player.has_method("set_super_charge_state"):
		player.set_super_charge_state(true, 0.0)
	_sync_player_speed()
	_sync_super_meter_state()


func request_super_charge_release(direction: Vector2) -> void:
	if not _super_is_charging or not _has_player():
		return
	var charge_ratio: float = clamp(get_super_charge_ratio(), 0.08, 1.0)
	var shot_direction := direction
	if shot_direction.length_squared() <= 0.001:
		shot_direction = player.aim_direction
	if shot_direction.length_squared() <= 0.001:
		shot_direction = Vector2.RIGHT
	shot_direction = shot_direction.normalized()
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	_super_meter = 0.0
	if player.has_method("set_super_charge_state"):
		player.set_super_charge_state(false, 0.0)
	if player.has_method("play_shoot_pose"):
		player.play_shoot_pose(shot_direction)
	_sync_player_speed()
	_sync_super_meter_state()
	super_shot_requested.emit(player.get_fire_origin(), shot_direction, charge_ratio)


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


func apply_pushback(push_direction: Vector2, force: float) -> void:
	if not enabled or not _has_player() or force <= 0.0:
		return
	if player.has_method("apply_pushback"):
		player.apply_pushback(push_direction, force)


func apply_healing(amount: int) -> void:
	if not enabled or not _has_player() or amount <= 0:
		return
	player.heal(amount)


func set_weapon_modifiers(modifiers: Dictionary) -> void:
	_fire_cooldown_multiplier = float(modifiers.get("fire_cooldown_multiplier", 1.0))
	_move_speed_multiplier = float(modifiers.get("move_speed_multiplier", 1.0))
	_sync_player_speed()


func play_perfect_parry_response(effect_radius: float, perfect_radius: float) -> void:
	if _has_player() and player.has_method("play_perfect_parry_response"):
		player.play_perfect_parry_response(effect_radius, perfect_radius)


func set_arena_bounds(bounds: Rect2) -> void:
	_arena_bounds = bounds
	if _has_player():
		player.set_arena_definition(_arena_bounds, _arena_shape)


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	if _has_player():
		player.set_arena_definition(_arena_bounds, _arena_shape)


func set_player_position(position: Vector2) -> void:
	if not _has_player():
		return
	player.global_position = ArenaGeometry.constrain_point(position, _arena_bounds, _arena_shape)
	player.set_move_vector(Vector2.ZERO)


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


func get_parry_cooldown_remaining() -> float:
	return _parry_cooldown_remaining


func get_parry_cooldown_duration() -> float:
	return parry_cooldown_seconds


func add_super_meter(amount: float) -> void:
	if amount <= 0.0 or super_meter_max <= 0.0:
		return
	if _super_is_charging:
		return
	_super_meter = clamp(_super_meter + amount, 0.0, super_meter_max)
	_sync_super_meter_state()


func is_super_ready() -> bool:
	return super_meter_max > 0.0 and _super_meter >= super_meter_max


func get_super_meter() -> float:
	return _super_meter


func get_super_meter_max() -> float:
	return max(super_meter_max, 1.0)


func get_super_charge_ratio() -> float:
	if not _super_is_charging:
		return 0.0
	return clamp(_super_charge_elapsed / max(super_charge_seconds, 0.01), 0.0, 1.0)


func _has_player() -> bool:
	return player != null and is_instance_valid(player)


func _on_player_health_changed(old_value: int, new_value: int) -> void:
	player_health_changed.emit(old_value, new_value)


func _on_player_health_depleted(entity) -> void:
	enabled = false
	_damage_cooldown_remaining = 0.0
	_parry_cooldown_remaining = 0.0
	_super_meter = 0.0
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	_sync_invulnerability_state()
	_sync_parry_state()
	_sync_super_meter_state()
	if _has_player():
		if player.has_method("set_super_charge_state"):
			player.set_super_charge_state(false, 0.0)
		player.play_death_animation()
	player_defeated.emit(entity)


func _sync_invulnerability_state() -> void:
	_last_invulnerability_remaining = _damage_cooldown_remaining
	if _has_player():
		player.set_invulnerability_state(_damage_cooldown_remaining, damage_invulnerability_seconds)
	player_invulnerability_changed.emit(_damage_cooldown_remaining, damage_invulnerability_seconds)


func _sync_parry_state() -> void:
	var previous_remaining := _last_parry_cooldown_remaining
	_last_parry_cooldown_remaining = _parry_cooldown_remaining
	if _has_player():
		var is_ready := _parry_cooldown_remaining <= 0.0
		if player.has_method("set_parry_ready_state"):
			player.set_parry_ready_state(is_ready)
		if is_ready and (previous_remaining > 0.0 or previous_remaining < 0.0) and player.has_method("play_parry_ready_response"):
			player.play_parry_ready_response(parry_effect_radius, parry_perfect_radius)
	parry_cooldown_changed.emit(_parry_cooldown_remaining, parry_cooldown_seconds)


func _cancel_super_charge(refund_meter: bool) -> void:
	if not _super_is_charging:
		return
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	if not refund_meter:
		_super_meter = 0.0
	if _has_player() and player.has_method("set_super_charge_state"):
		player.set_super_charge_state(false, 0.0)
	_sync_player_speed()
	_sync_super_meter_state()


func _sync_player_speed() -> void:
	if not _has_player():
		return
	var charge_multiplier := super_charge_speed_multiplier if _super_is_charging else 1.0
	player.set_speed_multiplier(_move_speed_multiplier * clamp(charge_multiplier, 0.1, 1.0))


func _sync_super_meter_state() -> void:
	var charge_ratio := get_super_charge_ratio()
	var is_ready := is_super_ready() and not _super_is_charging
	if _has_player():
		if player.has_method("set_super_ready_state"):
			player.set_super_ready_state(is_ready)
		if player.has_method("set_super_charge_state"):
			player.set_super_charge_state(_super_is_charging, charge_ratio)
		if is_ready and not _last_super_ready and player.has_method("play_super_ready_response"):
			player.play_super_ready_response()
	_last_super_ready = is_ready
	super_meter_changed.emit(_super_meter, get_super_meter_max(), _super_is_charging, charge_ratio)
