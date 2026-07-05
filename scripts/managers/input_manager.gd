extends Node
class_name InputManager

signal move_changed(move_vector: Vector2)
signal aim_changed(direction: Vector2)
signal aim_fire_requested(direction: Vector2)
signal restart_requested
signal menu_up_requested
signal menu_down_requested
signal menu_confirm_requested
signal menu_back_requested
signal parry_requested
signal pause_requested
signal super_charge_pressed
signal super_charge_released(direction: Vector2)
signal overdrive_changed(is_held: bool)

@export var stick_deadzone: float = 0.25
@export var aim_change_threshold: float = 0.18
@export var move_change_threshold: float = 0.03
@export var super_trigger_threshold: float = 0.55
@export var overdrive_trigger_threshold: float = 0.55

var enabled: bool = false
@export var extra_pause_button_indices: Array[int] = []
var _last_move: Vector2 = Vector2.ZERO
var _last_aim: Vector2 = Vector2.ZERO
var _super_held: bool = false
var _overdrive_held: bool = false
var _aim_origin_provider: Callable


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func initialize(context: Dictionary) -> void:
	_aim_origin_provider = context.get("aim_origin_provider", Callable())


func reset_run() -> void:
	_last_move = Vector2.ZERO
	_last_aim = Vector2.ZERO
	_super_held = false
	_overdrive_held = false


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled and _overdrive_held:
		_overdrive_held = false
		overdrive_changed.emit(false)


func _process(_delta: float) -> void:
	if not enabled:
		return
	var move_vector := _read_move_vector()
	if move_vector.distance_to(_last_move) >= move_change_threshold:
		_last_move = move_vector
		move_changed.emit(move_vector)

	var was_super_held := _super_held
	var super_held := _read_super_held()
	var overdrive_held := _read_overdrive_held()
	if overdrive_held != _overdrive_held:
		_overdrive_held = overdrive_held
		overdrive_changed.emit(_overdrive_held)
	var aim_vector := _read_aim_vector()
	if should_fire_for_aim_change(aim_vector):
		aim_changed.emit(_last_aim)
		if not super_held and not was_super_held:
			aim_fire_requested.emit(_last_aim)
	if super_held and not was_super_held:
		super_charge_pressed.emit()
	elif was_super_held and not super_held:
		super_charge_released.emit(_last_aim)
	_super_held = super_held


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_R or event.keycode == KEY_R):
		restart_requested.emit()
		menu_back_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE):
		pause_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_UP or event.keycode == KEY_UP or event.physical_keycode == KEY_W or event.keycode == KEY_W):
		menu_up_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_DOWN or event.keycode == KEY_DOWN or event.physical_keycode == KEY_S or event.keycode == KEY_S):
		menu_down_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_ENTER or event.keycode == KEY_ENTER or event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE):
		menu_confirm_requested      .emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_Q or event.keycode == KEY_Q):
		parry_requested.emit()
	elif event is InputEventJoypadButton and event.pressed and _is_pause_controller_button(event.button_index):
		pause_requested.emit()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		restart_requested.emit()
		menu_confirm_requested.emit()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		parry_requested.emit()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_UP:
		menu_up_requested.emit()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_DPAD_DOWN:
		menu_down_requested.emit()


func _is_restart_controller_button(button_index: int) -> bool:
	return button_index == JOY_BUTTON_A


func _is_pause_controller_button(button_index: int) -> bool:
	if button_index == JOY_BUTTON_START:
		return true
	for extra_index in extra_pause_button_indices:
		if button_index == int(extra_index):
			return true
	return false


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

	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) and _aim_origin_provider.is_valid():
		var origin: Vector2 = _aim_origin_provider.call()
		var mouse_world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		return (mouse_world - origin).limit_length(1.0)

	return Vector2.ZERO


func _read_super_held() -> bool:
	if Input.is_physical_key_pressed(KEY_E) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return true
	return Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT) >= super_trigger_threshold


func _read_overdrive_held() -> bool:
	if Input.is_physical_key_pressed(KEY_SHIFT):
		return true
	return Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) >= overdrive_trigger_threshold


func _apply_deadzone(vector: Vector2) -> Vector2:
	if vector.length() < stick_deadzone:
		return Vector2.ZERO
	return vector.normalized()
