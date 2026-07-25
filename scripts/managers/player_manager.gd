extends Node
class_name PlayerManager

signal player_spawned(player)
signal player_health_changed(old_value: int, new_value: int)
signal player_invulnerability_changed(remaining: float, duration: float)
signal player_defeated(player)
signal shoot_requested(origin: Vector2, direction: Vector2)
signal parry_requested(origin: Vector2, effect_radius: float, perfect_radius: float, enemy_knockback: float)
signal parry_cooldown_changed(remaining: float, duration: float)
signal parry_chain_changed(current_chain: int, longest_chain: int, grace_remaining: float, grace_duration: float)
signal super_meter_changed(current: float, maximum: float, is_charging: bool, charge_ratio: float)
signal super_shot_requested(origin: Vector2, direction: Vector2, charge_ratio: float)

@export var player_scene: PackedScene = preload("res://scenes/entities/player_entity.tscn")
@export var spawn_position: Vector2 = Vector2.ZERO
@export var base_fire_cooldown: float = 0.09
@export var damage_invulnerability_seconds: float = 0.6
@export var parry_cooldown_seconds: float = 8.0
@export var parry_chain_cooldown_seconds: float = 0.5
@export var parry_chain_grace_seconds: float = 4.0
@export var parry_effect_radius: float = 154.0
@export var parry_perfect_radius: float = 42.0
@export var parry_enemy_knockback: float = 430.0
@export var super_meter_max: float = 100.0
@export var super_meter_enemy_kill_gain: float = 6.0
@export var super_meter_parried_bullet_gain: float = 3.0
@export var super_meter_perfect_bullet_gain: float = 6.0
@export var super_charge_seconds: float = 1.15
@export var super_charge_speed_multiplier: float = 0.72

var player = null
var enabled: bool = false
var _player_layer: Node = null
var _fire_cooldown_remaining: float = 0.0
var _fire_cooldown_multiplier: float = 1.0
var _move_speed_multiplier: float = 1.0
var _context_speed_multiplier: float = 1.0
var _damage_cooldown_remaining: float = 0.0
var _last_invulnerability_remaining: float = -1.0
var _parry_cooldown_remaining: float = 0.0
var _active_parry_cooldown_duration: float = 8.0
var _last_parry_cooldown_remaining: float = -1.0
var _parry_chain_count: int = 0
var _longest_parry_chain: int = 0
var _parry_chain_grace_remaining: float = 0.0
var _last_parry_chain_count: int = -1
var _last_parry_chain_grace_remaining: float = -1.0
var _super_meter: float = 0.0
var _super_is_charging: bool = false
var _super_charge_elapsed: float = 0.0
var _last_super_ready: bool = false
var _defer_spawn_feedback: bool = false
var _spawn_feedback_queued: bool = false
var _arena_bounds: Rect2 = Rect2(Vector2(-600.0, -330.0), Vector2(1200.0, 660.0))
var _arena_shape: int = 0
var _wall_rects: Array[Rect2] = []
var _level_wall_rects: Array[Rect2] = []
var _void_rects: Array[Rect2] = []
var _playable_rects: Array[Rect2] = []


func initialize(context: Dictionary) -> void:
	_player_layer = context.get("player_layer", null)


func reset_run() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = player_scene.instantiate()
	player.global_position = spawn_position
	player.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)
	player.health_changed.connect(_on_player_health_changed)
	player.health_depleted.connect(_on_player_health_depleted)
	_add_child_safely(_get_player_parent(), player)
	_fire_cooldown_remaining = 0.0
	_damage_cooldown_remaining = 0.0
	_last_invulnerability_remaining = -1.0
	_parry_cooldown_remaining = 0.0
	_active_parry_cooldown_duration = parry_cooldown_seconds
	_last_parry_cooldown_remaining = -1.0
	_parry_chain_count = 0
	_longest_parry_chain = 0
	_parry_chain_grace_remaining = 0.0
	_last_parry_chain_count = -1
	_last_parry_chain_grace_remaining = -1.0
	_context_speed_multiplier = 1.0
	_super_meter = 0.0
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	_last_super_ready = false
	_sync_invulnerability_state()
	_sync_parry_state()
	_sync_parry_chain_state()
	_sync_player_speed()
	_sync_super_meter_state()
	player_spawned.emit(player)
	player_health_changed.emit(player.health, player.health)


func _get_player_parent() -> Node:
	return _player_layer if _player_layer != null else self


func _add_child_safely(parent: Node, child: Node) -> void:
	if parent == null or child == null or child.get_parent() != null:
		return
	if parent.is_inside_tree() and Engine.is_in_physics_frame():
		parent.call_deferred("add_child", child)
		return
	parent.add_child(child)


func clear_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = null
	_spawn_feedback_queued = false
	_fire_cooldown_remaining = 0.0
	_damage_cooldown_remaining = 0.0
	_parry_cooldown_remaining = 0.0
	_active_parry_cooldown_duration = parry_cooldown_seconds
	_parry_chain_count = 0
	_parry_chain_grace_remaining = 0.0
	_context_speed_multiplier = 1.0
	_super_meter = 0.0
	_super_is_charging = false
	_super_charge_elapsed = 0.0
	_last_super_ready = false
	player_health_changed.emit(0, 0)
	_sync_parry_state()
	_sync_parry_chain_state()
	_sync_super_meter_state()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_cancel_super_charge(true)
		if _has_player():
			player.stop_movement()


func set_spawn_feedback_deferred(value: bool) -> void:
	_defer_spawn_feedback = value
	if not _defer_spawn_feedback:
		_spawn_feedback_queued = false


func play_queued_spawn_feedback() -> void:
	_defer_spawn_feedback = false
	if not _spawn_feedback_queued:
		return
	_spawn_feedback_queued = false
	if _has_player() and player.has_method("play_parry_ready_response") and _parry_cooldown_remaining <= 0.0:
		player.play_parry_ready_response(parry_effect_radius, parry_perfect_radius)


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
	if _parry_chain_grace_remaining > 0.0:
		_parry_chain_grace_remaining = max(_parry_chain_grace_remaining - delta, 0.0)
		if _parry_chain_grace_remaining <= 0.0:
			_end_parry_chain()
			_set_parry_cooldown(parry_cooldown_seconds)
			_sync_parry_state()
		_sync_parry_chain_state()
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
	_set_parry_cooldown(parry_cooldown_seconds)
	if player.has_method("play_parry_response"):
		player.play_parry_response(parry_effect_radius, parry_perfect_radius)
	_sync_parry_state()
	parry_requested.emit(player.global_position, parry_effect_radius, parry_perfect_radius, parry_enemy_knockback)


func resolve_parry_result(was_perfect: bool) -> void:
	if was_perfect:
		_parry_chain_count += 1
		_longest_parry_chain = max(_longest_parry_chain, _parry_chain_count)
		_parry_chain_grace_remaining = max(parry_chain_grace_seconds, 0.0)
		_set_parry_cooldown(parry_chain_cooldown_seconds)
	else:
		_end_parry_chain()
		_set_parry_cooldown(parry_cooldown_seconds)
	_sync_parry_state()
	_sync_parry_chain_state()


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


func set_context_speed_multiplier(multiplier: float) -> void:
	_context_speed_multiplier = max(multiplier, 0.1)
	_sync_player_speed()


func play_perfect_parry_response(effect_radius: float, perfect_radius: float) -> void:
	if _has_player() and player.has_method("play_perfect_parry_response"):
		player.play_perfect_parry_response(effect_radius, perfect_radius)


func set_arena_bounds(bounds: Rect2) -> void:
	_arena_bounds = bounds
	_playable_rects.clear()
	if _has_player():
		player.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_arena_definition(level_definition) -> void:
	if level_definition == null:
		return
	_arena_bounds = level_definition.arena_bounds
	_arena_shape = int(level_definition.arena_shape)
	_level_wall_rects = level_definition.wall_rects
	_wall_rects = _level_wall_rects.duplicate()
	_void_rects = level_definition.void_rects
	_playable_rects = _get_playable_rects(level_definition)
	if _has_player():
		player.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_dynamic_wall_rects(extra_wall_rects: Array[Rect2]) -> void:
	_wall_rects = _level_wall_rects.duplicate()
	_wall_rects.append_array(extra_wall_rects)
	if _has_player():
		player.set_arena_definition(_arena_bounds, _arena_shape, _wall_rects, _void_rects, _playable_rects)


func set_player_position(position: Vector2) -> void:
	if not _has_player():
		return
	var blockers: Array[Rect2] = []
	blockers.append_array(_wall_rects)
	blockers.append_array(_void_rects)
	player.global_position = ArenaGeometry.constrain_point_to_playable_regions(position, _arena_bounds, _arena_shape, _playable_rects, blockers, float(player.body_radius))
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
	return _active_parry_cooldown_duration


func get_parry_chain_count() -> int:
	return _parry_chain_count


func get_longest_parry_chain() -> int:
	return _longest_parry_chain


func get_parry_chain_grace_remaining() -> float:
	return _parry_chain_grace_remaining


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
	if not level_definition.has_meta("footprint_cells"):
		return rects
	rects.append_array(ArenaGeometry.get_footprint_cell_rects(level_definition.arena_bounds, level_definition.get_meta("footprint_cells")))
	return rects


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
			if _defer_spawn_feedback and previous_remaining < 0.0:
				_spawn_feedback_queued = true
			else:
				player.play_parry_ready_response(parry_effect_radius, parry_perfect_radius)
	parry_cooldown_changed.emit(_parry_cooldown_remaining, _active_parry_cooldown_duration)


func _set_parry_cooldown(duration: float) -> void:
	_active_parry_cooldown_duration = max(duration, 0.0)
	_parry_cooldown_remaining = _active_parry_cooldown_duration


func _end_parry_chain() -> void:
	_parry_chain_count = 0
	_parry_chain_grace_remaining = 0.0


func _sync_parry_chain_state() -> void:
	if _has_player() and player.has_method("set_parry_chain_state"):
		player.set_parry_chain_state(_parry_chain_grace_remaining, parry_chain_grace_seconds, _parry_chain_count)
	if _last_parry_chain_count != _parry_chain_count or abs(_last_parry_chain_grace_remaining - _parry_chain_grace_remaining) > 0.02:
		_last_parry_chain_count = _parry_chain_count
		_last_parry_chain_grace_remaining = _parry_chain_grace_remaining
		parry_chain_changed.emit(_parry_chain_count, _longest_parry_chain, _parry_chain_grace_remaining, parry_chain_grace_seconds)


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
	player.set_speed_multiplier(_move_speed_multiplier * _context_speed_multiplier * clamp(charge_multiplier, 0.1, 1.0))


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
