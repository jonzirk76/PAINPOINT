extends RefCounted
class_name LegionTacticsController

const TACTICS_INDEPENDENT := "independent"
const TACTICS_FAN_OUT := "fan_out"
const TACTICS_CONCENTRATE := "concentrate"
const TACTICS_INTERCEPT := "intercept"

var legion_id: int = 0
var general_id: int = 0
var tactics_kind: String = TACTICS_INDEPENDENT
var _formation_phase: float = 0.0
var _spawn_cycle: int = 0


func initialize(general: EnemyEntity, selected_tactics_kind: String) -> void:
	if general == null:
		return
	legion_id = general.legion_id
	general_id = general.general_id
	tactics_kind = selected_tactics_kind
	_formation_phase = float(posmod(legion_id * 37, 360)) * PI / 180.0


func notify_spawn_ready() -> void:
	_spawn_cycle += 1
	_formation_phase = fmod(_formation_phase + PI * 0.17, TAU)


func build_orders(context: Dictionary) -> Dictionary:
	var orders: Dictionary = {}
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
	var legion_index: int = max(int(context.get("legion_index", 0)), 0)
	var legion_count: int = max(int(context.get("legion_count", 1)), 1)
	match tactics_kind:
		TACTICS_FAN_OUT:
			_build_fan_out_orders(orders, members, player_position, legion_index, legion_count)
		TACTICS_CONCENTRATE:
			_build_concentrate_orders(orders, members, player_position, legion_index, legion_count)
		TACTICS_INTERCEPT:
			_build_intercept_orders(orders, members, player_position, arena_center, legion_index, legion_count)
	return orders


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
