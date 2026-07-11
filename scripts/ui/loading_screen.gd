extends Control
class_name LoadingScreen

signal continue_requested

@export var background_cycle_seconds: float = 1.8
@export var progress: float = 0.0:
	set(value):
		progress = clamp(value, 0.0, 1.0)
		_update_progress_bar()

@onready var title_label: Label = $TitleLabel
@onready var status_label: Label = $StatusLabel
@onready var continue_label: Label = $ContinueLabel
@onready var loading_bar_back: ColorRect = $LoadingBarOverlay/LoadingBarBack
@onready var loading_bar_fill: ColorRect = $LoadingBarOverlay/LoadingBarBack/LoadingBarFill

var _continue_enabled: bool = false
var _cycle_remaining: float = 0.0
var _background_index: int = 0
var _backgrounds: Array[Dictionary] = [
	{"base": Color(0.01, 0.014, 0.02, 1.0), "accent": Color(0.05, 0.13, 0.18, 1.0)},
	{"base": Color(0.014, 0.01, 0.019, 1.0), "accent": Color(0.15, 0.07, 0.18, 1.0)},
	{"base": Color(0.012, 0.015, 0.011, 1.0), "accent": Color(0.08, 0.16, 0.09, 1.0)},
	{"base": Color(0.018, 0.013, 0.008, 1.0), "accent": Color(0.18, 0.11, 0.04, 1.0)}
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)
	_update_progress_bar()
	_update_continue_prompt()


func begin_loading(title: String = "LOADING", message: String = "", initial_progress: float = 0.0) -> void:
	title_label.text = title
	status_label.text = message
	progress = initial_progress
	_continue_enabled = false
	_cycle_remaining = 0.0
	visible = true
	set_process(true)
	_update_continue_prompt()
	queue_redraw()


func set_progress(value: float, message: String = "") -> void:
	progress = value
	if not message.is_empty():
		status_label.text = message


func finish_loading(message: String = "READY", wait_for_continue: bool = false) -> void:
	progress = 1.0
	status_label.text = message
	_continue_enabled = wait_for_continue
	if not wait_for_continue:
		visible = false
		set_process(false)
	_update_continue_prompt()


func show_continue(message: String = "PRESS A TO CONTINUE") -> void:
	progress = 1.0
	status_label.text = "READY"
	continue_label.text = message
	_continue_enabled = true
	visible = true
	set_process(true)
	_update_continue_prompt()


func hide_loading() -> void:
	_continue_enabled = false
	visible = false
	set_process(false)
	_update_continue_prompt()


func _process(delta: float) -> void:
	if not visible:
		return
	_cycle_remaining -= delta
	if _cycle_remaining <= 0.0:
		_cycle_remaining = max(background_cycle_seconds, 0.1)
		_background_index = (_background_index + 1) % _backgrounds.size()
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _continue_enabled:
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		accept_event()
		continue_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		accept_event()
		continue_requested.emit()


func _draw() -> void:
	var background: Dictionary = _backgrounds[_background_index]
	var base: Color = background["base"]
	var accent: Color = background["accent"]
	draw_rect(Rect2(Vector2.ZERO, size), base, true)
	var stripe_width: float = max(size.x / 9.0, 120.0)
	for index in range(10):
		var alpha: float = 0.12 if index % 2 == 0 else 0.06
		var stripe_color := Color(accent.r, accent.g, accent.b, alpha)
		var x: float = float(index) * stripe_width - stripe_width * 0.4
		draw_rect(Rect2(Vector2(x, 0.0), Vector2(stripe_width * 0.42, size.y)), stripe_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.18), true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_progress_bar()


func _update_progress_bar() -> void:
	if loading_bar_fill == null or loading_bar_back == null:
		return
	var width: float = max(loading_bar_back.size.x * progress, 0.0)
	loading_bar_fill.size = Vector2(width, loading_bar_back.size.y)


func _update_continue_prompt() -> void:
	if continue_label != null:
		continue_label.visible = _continue_enabled
