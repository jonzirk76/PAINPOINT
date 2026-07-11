extends Control
class_name LoadingScreen

signal continue_requested

@export var background_texture_directory: String = "res://art/loading_screens"
@export var background_textures: Array[Texture2D] = []
@export var progress_fill_speed: float = 1.8
@export var progress: float = 0.0:
	set(value):
		progress = clamp(value, 0.0, 1.0)
		if visible:
			set_process(true)

@onready var title_label: Label = $TitleLabel
@onready var status_label: Label = $StatusLabel
@onready var continue_label: Label = $ContinueLabel
@onready var background_texture_rect: TextureRect = $Vignette/TextureRect
@onready var loading_bar_back: ColorRect = $LoadingBarOverlay/LoadingBarBack
@onready var loading_bar_fill: ColorRect = $LoadingBarOverlay/LoadingBarBack/LoadingBarFill

var _continue_enabled: bool = false
var _background_index: int = 0
var _displayed_progress: float = 0.0
var _resolved_background_textures: Array[Texture2D] = []
var _rng := RandomNumberGenerator.new()
var _backgrounds: Array[Dictionary] = [
	{"base": Color(0.01, 0.014, 0.02, 1.0), "accent": Color(0.05, 0.13, 0.18, 1.0)},
	{"base": Color(0.014, 0.01, 0.019, 1.0), "accent": Color(0.15, 0.07, 0.18, 1.0)},
	{"base": Color(0.012, 0.015, 0.011, 1.0), "accent": Color(0.08, 0.16, 0.09, 1.0)},
	{"base": Color(0.018, 0.013, 0.008, 1.0), "accent": Color(0.18, 0.11, 0.04, 1.0)}
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_rng.randomize()
	_resolve_background_textures()
	_select_random_background()
	visible = false
	set_process(false)
	_clear_title_text()
	_update_progress_bar()
	_update_continue_prompt()


func begin_loading(title: String = "LOADING", message: String = "", initial_progress: float = 0.0) -> void:
	var was_visible := visible
	_clear_title_text()
	status_label.text = message
	progress = initial_progress
	_continue_enabled = false
	if not was_visible:
		_displayed_progress = 0.0
		_select_random_background()
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
	_continue_enabled = true
	visible = true
	set_process(true)
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
		set_process(false)
		return
	var previous_progress := _displayed_progress
	_displayed_progress = move_toward(_displayed_progress, progress, progress_fill_speed * delta)
	if not is_equal_approx(previous_progress, _displayed_progress):
		_update_progress_bar()
	if is_equal_approx(_displayed_progress, progress):
		set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _continue_enabled:
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		accept_event()
		hide_loading()
		continue_requested.emit()
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		accept_event()
		hide_loading()
		continue_requested.emit()


func _draw() -> void:
	if background_texture_rect != null and background_texture_rect.texture != null:
		draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK, true)
		return
	var background: Dictionary = _backgrounds[_background_index]
	var base: Color = background["base"]
	var accent: Color = background["accent"]
	draw_rect(Rect2(Vector2.ZERO, size), base, true)
	var stripe_width: float = max(size.x / 9.0, 120.0)
	for index in range(10):
		var alpha: float = 0.12 if index % 2 == 0 else 0.06
		var stripe_color: Color = Color(accent.r, accent.g, accent.b, alpha)
		var x: float = float(index) * stripe_width - stripe_width * 0.4
		draw_rect(Rect2(Vector2(x, 0.0), Vector2(stripe_width * 0.42, size.y)), stripe_color, true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.18), true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_progress_bar()


func _resolve_background_textures() -> void:
	_resolved_background_textures.clear()
	_add_unique_background_textures(background_textures)
	if background_texture_rect != null and background_texture_rect.texture != null:
		_add_unique_background_texture(background_texture_rect.texture)
	var directory: DirAccess = DirAccess.open(background_texture_directory)
	if directory == null:
		return
	for file_name in directory.get_files():
		var extension := file_name.get_extension().to_lower()
		if extension != "png" and extension != "jpg" and extension != "jpeg" and extension != "webp":
			continue
		var texture = load(background_texture_directory.path_join(file_name))
		if texture is Texture2D:
			_add_unique_background_texture(texture)


func _add_unique_background_textures(textures: Array[Texture2D]) -> void:
	for texture in textures:
		_add_unique_background_texture(texture)


func _add_unique_background_texture(texture: Texture2D) -> void:
	if texture == null:
		return
	var path: String = texture.resource_path
	for existing in _resolved_background_textures:
		if existing == texture or (not path.is_empty() and existing.resource_path == path):
			return
	_resolved_background_textures.append(texture)


func _select_random_background() -> void:
	if _resolved_background_textures.is_empty():
		return
	var next_index: int = _rng.randi_range(0, _resolved_background_textures.size() - 1)
	if _resolved_background_textures.size() > 1 and next_index == _background_index:
		next_index = (next_index + 1) % _resolved_background_textures.size()
	_background_index = next_index
	if background_texture_rect != null:
		background_texture_rect.texture = _resolved_background_textures[_background_index]


func _update_progress_bar() -> void:
	if loading_bar_fill == null or loading_bar_back == null:
		return
	var width: float = max(loading_bar_back.size.x * _displayed_progress, 0.0)
	loading_bar_fill.size = Vector2(width, loading_bar_back.size.y)


func _update_continue_prompt() -> void:
	if continue_label != null:
		continue_label.visible = _continue_enabled


func _clear_title_text() -> void:
	if title_label != null:
		title_label.text = ""
