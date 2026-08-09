extends RefCounted
class_name LegionTacticsController

const TACTICS_INDEPENDENT := "independent"
const TACTICS_FAN_OUT := "fan_out"
const TACTICS_CONCENTRATE := "concentrate"
const TACTICS_INTERCEPT := "intercept"
const TACTICS_SUPPORT_CORPS := "support_corps"

var legion_id: int = 0
var general_id: int = 0
var tactics_kind: String = TACTICS_INDEPENDENT
var _formation_phase: float = 0.0
var _spawn_cycle: int = 0
var _adaptive_tactics: bool = false
var _stationary_speed: float = 34.0
var _intercept_speed: float = 92.0
var _intercept_outward_dot: float = 0.45
var _intercept_edge_ratio: float = 0.48
var _tactic_hold_seconds: float = 0.85
var _tactic_hold_remaining: float = 0.0


func initialize(general: EnemyEntity, selected_tactics_kind: String) -> void:
	if general == null:
		return
	legion_id = general.legion_id
	general_id = general.general_id
	tactics_kind = selected_tactics_kind
	var spawn_profile: EnemySpawnProfile = general.spawn_profile
	if spawn_profile != null:
		_adaptive_tactics = spawn_profile.adaptive_tactics
		_stationary_speed = max(spawn_profile.adaptive_stationary_speed, 0.0)
		_intercept_speed = max(spawn_profile.adaptive_intercept_speed, 0.0)
		_intercept_outward_dot = clamp(spawn_profile.adaptive_intercept_outward_dot, -1.0, 1.0)
		_intercept_edge_ratio = clamp(spawn_profile.adaptive_intercept_edge_ratio, 0.0, 1.0)
		_tactic_hold_seconds = max(spawn_profile.adaptive_tactic_hold_seconds, 0.0)
	_formation_phase = float(posmod(legion_id * 37, 360)) * PI / 180.0


func notify_spawn_ready() -> void:
	_spawn_cycle += 1
	_formation_phase = fmod(_formation_phase + PI * 0.17, TAU)


func build_orders(context: Dictionary) -> Dictionary:
	var orders: Dictionary = {}
	_update_adaptive_tactics(context)
	if tactics_kind == TACTICS_INDEPENDENT:
		return orders
	var members: Array = context.get("members", [])
	if members.is_empty():
		return orders
	members.sort_custom(func(a, b) -> bool:
		return int(a.get_instance_id()) < int(b.get_instance_id())
	)
	var player_position: Vector2 = context.get("player_position", Vector2.ZERO)
	var arena_center: Vector2 = context.get("arena_center", Vector2.ZERO)
	var general_position: Vector2 = context.get("general_position", arena_center)
	var legion_index: int = max(int(context.get("legion_index", 0)), 0)
	var legion_count: int = max(int(context.get("legion_count", 1)), 1)
	match tactics_kind:
		TACTICS_FAN_OUT:
			_build_fan_out_orders(orders, members, player_position, legion_index, legion_count)
		TACTICS_CONCENTRATE:
			_build_concentrate_orders(orders, members, player_position, legion_index, legion_count)
		TACTICS_INTERCEPT:
			_build_intercept_orders(orders, members, player_position, arena_center, legion_index, legion_count)
		TACTICS_SUPPORT_CORPS:
			_build_support_corps_orders(orders, members, general_position)
	return orders


func _update_adaptive_tactics(context: Dictionary) -> void:
	if not _adaptive_tactics:
		return
	var delta: float = max(float(context.get("delta", 0.0)), 0.0)
	_tactic_hold_remaining = max(_tactic_hold_remaining - delta, 0.0)
	var player_position: Vector2 = context.get("player_position", Vector2.ZERO)
	var player_velocity: Vector2 = context.get("player_velocity", Vector2.ZERO)
	var arena_center: Vector2 = context.get("arena_center", Vector2.ZERO)
	var arena_half_size: Vector2 = context.get("arena_half_size", Vector2.ONE)
	var desired_tactics := _select_adaptive_tactics(
		player_position,
		player_velocity,
		arena_center,
		arena_half_size
	)
	if desired_tactics == tactics_kind or _tactic_hold_remaining > 0.0:
		return
	tactics_kind = desired_tactics
	_tactic_hold_remaining = _tactic_hold_seconds
	_formation_phase = fmod(_formation_phase + PI * 0.13, TAU)


func _select_adaptive_tactics(
	player_position: Vector2,
	player_velocity: Vector2,
	arena_center: Vector2,
	arena_half_size: Vector2
) -> String:
	var player_speed: float = player_velocity.length()
	if player_speed <= _stationary_speed:
		return TACTICS_FAN_OUT
	var from_center: Vector2 = player_position - arena_center
	var safe_half_size := Vector2(max(arena_half_size.x, 1.0), max(arena_half_size.y, 1.0))
	var normalized_offset := Vector2(from_center.x / safe_half_size.x, from_center.y / safe_half_size.y)
	var edge_ratio: float = normalized_offset.length()
	var moving_outward := false
	if from_center.length_squared() > 1.0 and player_speed >= _intercept_speed:
		moving_outward = player_velocity.normalized().dot(from_center.normalized()) >= _intercept_outward_dot
	if edge_ratio >= _intercept_edge_ratio and moving_outward:
		return TACTICS_INTERCEPT
	return TACTICS_CONCENTRATE


func _build_fan_out_orders(
	orders: Dictionary,
	members: Array,
	player_position: Vector2,
	legion_index: int,
	legion_count: int
) -> void:
	var shared_phase: float = TAU * float(legion_index) / float(legion_count)
	var count: int = max(members.size(), 1)
	for index in range(members.size()):
		var angle: float = shared_phase + _formation_phase + TAU * float(index) / float(count)
		var radius: float = 150.0 + float((index + _spawn_cycle) % 3) * 24.0
		orders[int(members[index].get_instance_id())] = player_position + Vector2.RIGHT.rotated(angle) * radius


func _build_concentrate_orders(
	orders: Dictionary,
	members: Array,
	player_position: Vector2,
	legion_index: int,
	legion_count: int
) -> void:
	var attack_angle: float = TAU * float(legion_index) / float(legion_count) + _formation_phase * 0.35
	var attack_direction := Vector2.RIGHT.rotated(attack_angle)
	var side := attack_direction.orthogonal()
	var center := player_position + attack_direction * 76.0
	for index in range(members.size()):
		var centered_index: float = float(index) - float(members.size() - 1) * 0.5
		orders[int(members[index].get_instance_id())] = center + side * centered_index * 28.0


func _build_intercept_orders(
	orders: Dictionary,
	members: Array,
	player_position: Vector2,
	arena_center: Vector2,
	legion_index: int,
	legion_count: int
) -> void:
	var escape_direction: Vector2 = player_position - arena_center
	if escape_direction.length_squared() <= 4.0:
		escape_direction = Vector2.RIGHT.rotated(TAU * float(legion_index) / float(legion_count))
	else:
		escape_direction = escape_direction.normalized()
	var side := escape_direction.orthogonal()
	var intercept_center := player_position + escape_direction * 118.0
	for index in range(members.size()):
		var centered_index: float = float(index) - float(members.size() - 1) * 0.5
		orders[int(members[index].get_instance_id())] = intercept_center + side * centered_index * 34.0


func _build_support_corps_orders(orders: Dictionary, members: Array, general_position: Vector2) -> void:
	var count: int = max(members.size(), 1)
	for index in range(members.size()):
		var angle: float = _formation_phase + TAU * float(index) / float(count)
		var radius: float = 104.0 + float((index + _spawn_cycle) % 2) * 24.0
		orders[int(members[index].get_instance_id())] = general_position + Vector2.RIGHT.rotated(angle) * radius
