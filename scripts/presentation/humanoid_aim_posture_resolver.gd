class_name HumanoidAimPostureResolver
extends RefCounted

enum Phase {
	LOCOMOTION,
	MOVING_AIM,
	BRACE_GRACE,
	BRACE_TURN,
	BRACE_HELD,
}

const DIRECTION_COUNT := 8
const DIRECTION_STEP_RADIANS := PI * 0.25
const IDEAL_BRACE_ANGLE_RADIANS := PI * 0.25

var shot_pose_hold_seconds: float = 0.4
var brace_entry_delay_seconds: float = 0.15
var brace_aim_grace_degrees: float = 30.0
var brace_turn_step_seconds: float = 0.1
var brace_speed_enter_threshold: float = 0.15
var movement_speed_resume_threshold: float = 0.25

var _movement_direction: int = 0
var _movement_strength: float = 0.0
var _hips_direction: int = 0
var _torso_direction: int = 0
var _head_direction: int = 0
var _arms_direction: int = 0
var _last_shot_direction: int = 0
var _last_shot_vector: Vector2 = Vector2.ZERO
var _brace_target_direction: int = 0
var _shot_hold_remaining: float = 0.0
var _brace_entry_remaining: float = 0.0
var _turn_step_remaining: float = 0.0
var _moving: bool = false
var _aim_active: bool = false
var _twist_sign: int = 1
var _phase: int = Phase.LOCOMOTION


func reset(initial_direction: int = 0) -> void:
	var direction := wrapi(initial_direction, 0, DIRECTION_COUNT)
	_movement_direction = direction
	_hips_direction = direction
	_torso_direction = direction
	_head_direction = direction
	_arms_direction = direction
	_last_shot_direction = direction
	_brace_target_direction = direction
	_movement_strength = 0.0
	_last_shot_vector = Vector2.ZERO
	_shot_hold_remaining = 0.0
	_brace_entry_remaining = 0.0
	_turn_step_remaining = 0.0
	_moving = false
	_aim_active = false
	_twist_sign = 1
	_phase = Phase.LOCOMOTION


func set_locomotion(direction: int, movement_strength: float) -> void:
	_movement_direction = wrapi(direction, 0, DIRECTION_COUNT)
	_movement_strength = clampf(movement_strength, 0.0, 1.0)
	var was_moving := _moving
	if _moving:
		_moving = _movement_strength > brace_speed_enter_threshold
	else:
		_moving = _movement_strength >= movement_speed_resume_threshold
	if _moving:
		_brace_entry_remaining = 0.0
		_turn_step_remaining = 0.0
		_resolve_moving_pose()
	elif was_moving:
		if _aim_active:
			_request_stationary_brace()
		else:
			_set_aligned_body(_movement_direction)
			_phase = Phase.LOCOMOTION


func register_shot(shot_vector: Vector2) -> void:
	if shot_vector.length_squared() <= 0.0001:
		return
	_last_shot_vector = shot_vector.normalized()
	_last_shot_direction = _direction_from_vector(_last_shot_vector)
	_shot_hold_remaining = maxf(shot_pose_hold_seconds, 0.0)
	_aim_active = true
	_update_twist_sign(_hips_direction, _last_shot_direction)
	if _moving:
		_resolve_moving_pose()
	else:
		_request_stationary_brace()


func clear_active_aim() -> void:
	_shot_hold_remaining = 0.0
	_aim_active = false
	if _moving:
		_resolve_moving_pose()


func advance(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	if _aim_active:
		_shot_hold_remaining = maxf(_shot_hold_remaining - safe_delta, 0.0)
		if is_zero_approx(_shot_hold_remaining):
			_aim_active = false
			if _moving:
				_resolve_moving_pose()
	if _moving:
		return
	match _phase:
		Phase.BRACE_GRACE:
			_brace_entry_remaining = maxf(_brace_entry_remaining - safe_delta, 0.0)
			if is_zero_approx(_brace_entry_remaining):
				_phase = Phase.BRACE_TURN
				_turn_step_remaining = 0.0
		Phase.BRACE_TURN:
			_turn_step_remaining = maxf(_turn_step_remaining - safe_delta, 0.0)
			if is_zero_approx(_turn_step_remaining):
				_advance_brace_step()


func get_pose() -> Dictionary:
	return {
		"hips_direction": _hips_direction,
		"torso_direction": _torso_direction,
		"head_direction": _head_direction,
		"arms_direction": _arms_direction,
		"walking": _moving,
		"aim_active": _aim_active,
		"aim_vector": _last_shot_vector,
		"phase": _phase,
	}


func is_aim_active() -> bool:
	return _aim_active


func get_phase_name() -> String:
	return String([
		"locomotion",
		"moving aim",
		"brace grace",
		"brace turn",
		"brace held",
	][_phase])


func _resolve_moving_pose() -> void:
	_hips_direction = _movement_direction
	if not _aim_active:
		_set_aligned_body(_movement_direction)
		_phase = Phase.LOCOMOTION
		return
	_torso_direction = _step_toward(_hips_direction, _last_shot_direction, 1)
	_head_direction = _step_toward(_torso_direction, _last_shot_direction, 2)
	_arms_direction = _torso_direction
	_phase = Phase.MOVING_AIM


func _request_stationary_brace() -> void:
	var current_brace_is_valid := _is_brace_valid(_hips_direction, _last_shot_vector)
	_brace_target_direction = (
		_hips_direction
		if current_brace_is_valid
		else _choose_brace_target(_last_shot_direction)
	)
	_head_direction = _step_toward(_torso_direction, _last_shot_direction, 2)
	var body_needs_settling := (
		_hips_direction != _brace_target_direction
		or _torso_direction != _hips_direction
		or _arms_direction != _torso_direction
	)
	if not body_needs_settling:
		_phase = Phase.BRACE_HELD
		return
	if _phase != Phase.BRACE_GRACE and _phase != Phase.BRACE_TURN:
		_brace_entry_remaining = maxf(brace_entry_delay_seconds, 0.0)
		_phase = Phase.BRACE_GRACE


func _advance_brace_step() -> void:
	if _hips_direction != _brace_target_direction:
		_hips_direction = _step_toward(_hips_direction, _brace_target_direction, 1)
	_torso_direction = _hips_direction
	_arms_direction = _torso_direction
	_head_direction = _step_toward(_torso_direction, _last_shot_direction, 2)
	if _hips_direction == _brace_target_direction:
		_phase = Phase.BRACE_HELD
		_turn_step_remaining = 0.0
	else:
		_turn_step_remaining = maxf(brace_turn_step_seconds, 0.001)


func _set_aligned_body(direction: int) -> void:
	_hips_direction = direction
	_torso_direction = direction
	_head_direction = direction
	_arms_direction = direction


func _is_brace_valid(body_direction: int, shot_vector: Vector2) -> bool:
	if shot_vector.length_squared() <= 0.0001:
		return false
	var body_angle := _vector_from_direction(body_direction).angle()
	var relative_angle := absf(wrapf(shot_vector.angle() - body_angle, -PI, PI))
	var grace_radians := deg_to_rad(clampf(brace_aim_grace_degrees, 0.0, 44.0))
	return absf(relative_angle - IDEAL_BRACE_ANGLE_RADIANS) <= grace_radians


func _choose_brace_target(shot_direction: int) -> int:
	var counterclockwise_candidate := wrapi(shot_direction - 1, 0, DIRECTION_COUNT)
	var clockwise_candidate := wrapi(shot_direction + 1, 0, DIRECTION_COUNT)
	var counterclockwise_delta := _signed_direction_delta(
		_hips_direction,
		counterclockwise_candidate
	)
	var clockwise_delta := _signed_direction_delta(_hips_direction, clockwise_candidate)
	var target := counterclockwise_candidate
	if abs(clockwise_delta) < abs(counterclockwise_delta):
		target = clockwise_candidate
	elif abs(clockwise_delta) == abs(counterclockwise_delta):
		target = clockwise_candidate if _twist_sign > 0 else counterclockwise_candidate
	_update_twist_sign(_hips_direction, target)
	return target


func _step_toward(source: int, target: int, maximum_steps: int) -> int:
	var delta := _signed_direction_delta(source, target)
	return wrapi(source + clampi(delta, -maximum_steps, maximum_steps), 0, DIRECTION_COUNT)


func _signed_direction_delta(source: int, target: int) -> int:
	var clockwise_steps := wrapi(target - source, 0, DIRECTION_COUNT)
	if clockwise_steps == 4:
		return 4 * _twist_sign
	return clockwise_steps if clockwise_steps < 4 else clockwise_steps - DIRECTION_COUNT


func _update_twist_sign(source: int, target: int) -> void:
	var clockwise_steps := wrapi(target - source, 0, DIRECTION_COUNT)
	if clockwise_steps == 0 or clockwise_steps == 4:
		return
	_twist_sign = 1 if clockwise_steps < 4 else -1


func _direction_from_vector(value: Vector2) -> int:
	var octant := roundi((value.angle() - PI * 0.5) / DIRECTION_STEP_RADIANS)
	return wrapi(octant, 0, DIRECTION_COUNT)


func _vector_from_direction(direction: int) -> Vector2:
	var angle := PI * 0.5 + wrapi(direction, 0, DIRECTION_COUNT) * DIRECTION_STEP_RADIANS
	return Vector2.from_angle(angle)
