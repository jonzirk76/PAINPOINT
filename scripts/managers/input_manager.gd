extends Node
class_name InputManager

signal move_changed(move_vector: Vector2)
signal aim_changed(direction: Vector2)
signal aim_hold_changed(is_held: bool)
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

const AIM_SOURCE_NONE := 0
const AIM_SOURCE_ANALOG := 1
const AIM_SOURCE_DIGITAL := 2
const AIM_SOURCE_MOUSE := 3

@export var stick_deadzone: float = 0.25
## Controls how much the aim direction must change before requesting another shot.
@export var aim_change_threshold: float = 0.18
## Fires once in the previous right-stick direction when analog aim returns to neutral.
@export var aim_release_fire_enabled: bool = true
## Expands the analog return-to-neutral radius as fire rate upgrades reduce weapon cooldown.
@export var aim_release_deadzone_fire_rate_bonus: float = 0.25
## Snaps right-stick aim to a cardinal axis when the off-axis component is this small relative to the dominant axis.
@export var aim_cardinal_snap_enter_ratio: float = 0.45
## Keeps right-stick aim snapped to a cardinal axis until the off-axis component drifts past this ratio.
@export var aim_cardinal_snap_exit_ratio: float = 0.65
@export var move_change_threshold: float = 0.03
@export var super_trigger_threshold: float = 0.55
@export var overdrive_trigger_threshold: float = 0.55

var enabled: bool = false
@export var extra_pause_button_indices: Array[int] = []
var _last_move: Vector2 = Vector2.ZERO
var _last_aim: Vector2 = Vector2.ZERO
var _last_cardinal_aim_snap: Vector2 = Vector2.ZERO
var _last_active_aim_source: int = AIM_SOURCE_NONE
var _last_read_aim_source: int = AIM_SOURCE_NONE
var _pending_aim_fire_direction: Vector2 = Vector2.ZERO
var _aim_release_fire_armed: bool = false
var _aim_release_neutral_latched: bool = false
var _super_held: bool = false
var _overdrive_held: bool = false
var _fire_cooldown_multiplier: float = 1.0
var _last_read_analog_aim_magnitude: float = 0.0
var _aim_origin_provider: Callable
var _aim_held: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func initialize(context: Dictionary) -> void:
	_aim_origin_provider = context.get("aim_origin_provider", Callable())


func reset_run() -> void:
	var was_aim_held := _aim_held
	_last_move = Vector2.ZERO
	_last_aim = Vector2.ZERO
	_last_cardinal_aim_snap = Vector2.ZERO
	_last_active_aim_source = AIM_SOURCE_NONE
	_last_read_aim_source = AIM_SOURCE_NONE
	_pending_aim_fire_direction = Vector2.ZERO
	_aim_release_fire_armed = false
	_aim_release_neutral_latched = false
	_super_held = false
	_overdrive_held = false
	_last_read_analog_aim_magnitude = 0.0
	_aim_held = false
	if was_aim_held:
		aim_hold_changed.emit(false)


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		_pending_aim_fire_direction = Vector2.ZERO
		_aim_release_fire_armed = false
		_aim_release_neutral_latched = false
		_last_read_aim_source = AIM_SOURCE_NONE
		if _aim_held:
			_aim_held = false
			aim_hold_changed.emit(false)
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
	if should_fire_for_aim_change(aim_vector, _last_read_aim_source, _last_read_analog_aim_magnitude):
		var fire_direction := _consume_pending_aim_fire_direction()
		aim_changed.emit(fire_direction)
		if not super_held and not was_super_held:
			aim_fire_requested.emit(fire_direction)
	var next_aim_held := _last_aim.length_squared() > 0.001
	if next_aim_held != _aim_held:
		_aim_held = next_aim_held
		aim_hold_changed.emit(_aim_held)
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


func set_fire_cooldown_multiplier(multiplier: float) -> void:
	_fire_cooldown_multiplier = maxf(multiplier, 0.01)


func should_fire_for_aim_change(raw_direction: Vector2, aim_source: int = AIM_SOURCE_ANALOG, raw_analog_magnitude: float = -1.0) -> bool:
	_pending_aim_fire_direction = Vector2.ZERO
	var analog_magnitude := raw_analog_magnitude
	if analog_magnitude < 0.0:
		analog_magnitude = raw_direction.length()
	var release_deadzone := _get_aim_release_deadzone()
	var should_hold_release_neutral := aim_source == AIM_SOURCE_ANALOG and _aim_release_neutral_latched and analog_magnitude < release_deadzone
	var should_release_to_neutral := aim_source == AIM_SOURCE_ANALOG and _aim_release_fire_armed and _last_active_aim_source == AIM_SOURCE_ANALOG and analog_magnitude < release_deadzone
	if aim_source == AIM_SOURCE_ANALOG and analog_magnitude >= release_deadzone:
		_aim_release_neutral_latched = false
	elif aim_source == AIM_SOURCE_DIGITAL or aim_source == AIM_SOURCE_MOUSE:
		_aim_release_neutral_latched = false
	var direction := Vector2.ZERO if should_hold_release_neutral or should_release_to_neutral else _apply_deadzone(raw_direction)
	if direction.length_squared() <= 0.001:
		var release_direction := _last_aim
		var should_fire_on_release := aim_release_fire_enabled and _aim_release_fire_armed and _last_active_aim_source == AIM_SOURCE_ANALOG and release_direction.length_squared() > 0.001
		_last_aim = Vector2.ZERO
		_last_cardinal_aim_snap = Vector2.ZERO
		_last_active_aim_source = AIM_SOURCE_NONE
		_aim_release_fire_armed = false
		if should_fire_on_release:
			_aim_release_neutral_latched = true
			_pending_aim_fire_direction = release_direction.normalized()
			return true
		return false
	_last_active_aim_source = aim_source
	_aim_release_fire_armed = aim_source == AIM_SOURCE_ANALOG
	if _last_aim.length_squared() <= 0.001 or direction.distance_to(_last_aim) >= aim_change_threshold:
		_last_aim = direction
		_pending_aim_fire_direction = direction
		return true
	return false


func _consume_pending_aim_fire_direction() -> Vector2:
	var direction := _pending_aim_fire_direction
	_pending_aim_fire_direction = Vector2.ZERO
	if direction.length_squared() > 0.001:
		return direction.normalized()
	return _last_aim


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
	_last_read_analog_aim_magnitude = joy_vector.length()
	if _last_read_analog_aim_magnitude >= stick_deadzone:
		_last_read_aim_source = AIM_SOURCE_ANALOG
		return _snap_analog_aim_to_cardinal(joy_vector)

	var digital_vector := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_KP_4) or Input.is_physical_key_pressed(KEY_KP_7) or Input.is_physical_key_pressed(KEY_KP_1):
		digital_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_KP_6) or Input.is_physical_key_pressed(KEY_KP_9) or Input.is_physical_key_pressed(KEY_KP_3):
		digital_vector.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_KP_8) or Input.is_physical_key_pressed(KEY_KP_7) or Input.is_physical_key_pressed(KEY_KP_9):
		digital_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_KP_2) or Input.is_physical_key_pressed(KEY_KP_1) or Input.is_physical_key_pressed(KEY_KP_3):
		digital_vector.y += 1.0
	if digital_vector.length_squared() > 0.001:
		_last_cardinal_aim_snap = Vector2.ZERO
		_last_read_aim_source = AIM_SOURCE_DIGITAL
		return digital_vector.limit_length(1.0)

	if (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)) and _aim_origin_provider.is_valid():
		_last_cardinal_aim_snap = Vector2.ZERO
		_last_read_aim_source = AIM_SOURCE_MOUSE
		var origin: Vector2 = _aim_origin_provider.call()
		var mouse_world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_mouse_position()
		return (mouse_world - origin).limit_length(1.0)

	_last_cardinal_aim_snap = Vector2.ZERO
	_last_read_aim_source = AIM_SOURCE_NONE
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


func _get_aim_release_deadzone() -> float:
	var fire_rate_ratio: float = clampf(1.0 - _fire_cooldown_multiplier, 0.0, 1.0)
	var release_deadzone: float = stick_deadzone + maxf(aim_release_deadzone_fire_rate_bonus, 0.0) * fire_rate_ratio
	return clampf(release_deadzone, stick_deadzone, 0.85)


func _snap_analog_aim_to_cardinal(vector: Vector2) -> Vector2:
	var direction := _apply_deadzone(vector)
	if direction.length_squared() <= 0.001:
		_last_cardinal_aim_snap = Vector2.ZERO
		return Vector2.ZERO

	var abs_x: float = absf(direction.x)
	var abs_y: float = absf(direction.y)
	var cardinal := Vector2.RIGHT
	var off_axis_ratio := 0.0
	if abs_x >= abs_y:
		cardinal = Vector2(1.0 if direction.x >= 0.0 else -1.0, 0.0)
		off_axis_ratio = abs_y / maxf(abs_x, 0.001)
	else:
		cardinal = Vector2(0.0, 1.0 if direction.y >= 0.0 else -1.0)
		off_axis_ratio = abs_x / maxf(abs_y, 0.001)

	var enter_ratio: float = clampf(aim_cardinal_snap_enter_ratio, 0.0, 1.0)
	var exit_ratio: float = clampf(maxf(aim_cardinal_snap_exit_ratio, enter_ratio), 0.0, 1.0)
	var snap_ratio: float = exit_ratio if _last_cardinal_aim_snap == cardinal else enter_ratio
	if off_axis_ratio <= snap_ratio:
		_last_cardinal_aim_snap = cardinal
		return cardinal

	_last_cardinal_aim_snap = Vector2.ZERO
	return direction
