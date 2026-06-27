extends Node
class_name InputManager

signal move_changed(move_vector: Vector2)
signal aim_changed(direction: Vector2)
signal aim_fire_requested(direction: Vector2)
signal restart_requested

@export var stick_deadzone: float = 0.25
@export var aim_change_threshold: float = 0.18
@export var move_change_threshold: float = 0.03

var enabled: bool = false
var _last_move: Vector2 = Vector2.ZERO
var _last_aim: Vector2 = Vector2.ZERO
var _aim_origin_provider: Callable


func initialize(context: Dictionary) -> void:
	_aim_origin_provider = context.get("aim_origin_provider", Callable())


func reset_run() -> void:
	_last_move = Vector2.ZERO
	_last_aim = Vector2.ZERO


func set_enabled(value: bool) -> void:
	enabled = value


func _process(_delta: float) -> void:
	if not enabled:
		return
	var move_vector := _read_move_vector()
	if move_vector.distance_to(_last_move) >= move_change_threshold:
		_last_move = move_vector
		move_changed.emit(move_vector)

	var aim_vector := _read_aim_vector()
	if should_fire_for_aim_change(aim_vector):
		aim_changed.emit(_last_aim)
		aim_fire_requested.emit(_last_aim)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_R or event.keycode == KEY_R):
		restart_requested.emit()
	elif event is InputEventJoypadButton and event.pressed and _is_restart_controller_button(event.button_index):
		restart_requested.emit()


func _is_restart_controller_button(button_index: int) -> bool:
	return button_index == JOY_BUTTON_START or button_index == JOY_BUTTON_A


func should_fire_for_aim_change(raw_direction: Vector2) -> bool:
	var direction := _apply_deadzone(raw_direction)
	if direction.length_squared() <= 0.001:
		_last_aim = Vector2.ZERO
		return false
	if _last_aim.length_squared() <= 0.001 or direction.distance_to(_last_aim) >= aim_change_threshold:
		_last_aim = direction
		return true
	return false


func _read_move_vector() -> Vector2:
	var joy_vector := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	)
	if joy_vector.length() >= stick_deadzone:
		return joy_vector.limit_length(1.0)

	var keyboard_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		keyboard_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		keyboard_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		keyboard_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		keyboard_vector.y += 1.0
	return keyboard_vector.limit_length(1.0)


func _read_aim_vector() -> Vector2:
	var joy_vector := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	if joy_vector.length() >= stick_deadzone:
		return joy_vector.limit_length(1.0)

	var digital_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT):
		digital_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT):
		digital_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP):
		digital_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN):
		digital_vector.y += 1.0
	if digital_vector.length_squared() > 0.001:
		return digital_vector.limit_length(1.0)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _aim_origin_provider.is_valid():
		var origin: Vector2 = _aim_origin_provider.call()
		var mouse_world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		return (mouse_world - origin).limit_length(1.0)

	return Vector2.ZERO


func _apply_deadzone(vector: Vector2) -> Vector2:
	if vector.length() < stick_deadzone:
		return Vector2.ZERO
	return vector.normalized()
