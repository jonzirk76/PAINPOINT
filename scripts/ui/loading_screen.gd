extends Control
class_name LoadingScreen

signal continue_requested

@export var background_texture_directory: String = "res://art/loading_screens"
@export var background_textures: Array[Texture2D] = []
@export var progress_fill_speed: float = 1.8
@export var ready_glow_speed: float = 1.8
@export var ready_glow_base_color: Color = Color(0.72, 0.9, 0.95, 1.0)
@export var ready_glow_peak_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var ready_glow_min_mix: float = 0.32
@export_range(0.0, 1.0, 0.01) var ready_glow_max_mix: float = 0.8
@export var ready_glow_shadow_color: Color = Color(0.2, 0.9, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var ready_glow_shadow_min_alpha: float = 0.22
@export_range(0.0, 1.0, 0.01) var ready_glow_shadow_max_alpha: float = 0.78
@export_range(0, 32, 1) var ready_glow_shadow_min_outline: int = 6
@export_range(0, 32, 1) var ready_glow_shadow_max_outline: int = 14
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
var _glow_time: float = 0.0
var _crackle_remaining: float = 0.0
var _crackle_interval_remaining: float = 0.0
var _status_base_label_settings: LabelSettings = null
var _continue_base_label_settings: LabelSettings = null
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
	_prepare_runtime_label_settings()
	_clear_title_text()
	_update_progress_bar()
	_update_continue_prompt()


func begin_loading(title: String = "LOADING", message: String = "", initial_progress: float = 0.0) -> void:
	var was_visible := visible
	_clear_title_text()
	status_label.text = message
	progress = initial_progress
	_continue_enabled = false
	_glow_time = 0.0
	_clear_ready_glow()
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
	_glow_time = 0.0
	visible = true
	set_process(true)
	_update_continue_prompt()


func show_continue(message: String = "PRESS A TO CONTINUE") -> void:
	progress = 1.0
	status_label.text = "READY"
	continue_label.text = message
	_continue_enabled = true
	_glow_time = 0.0
	visible = true
	set_process(true)
	_update_continue_prompt()


func hide_loading() -> void:
	_continue_enabled = false
	visible = false
	_clear_loading_crackle()
	_clear_ready_glow()
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
	_update_loading_crackle(delta)
	if _continue_enabled:
		_glow_time += delta
		_update_ready_glow()
	if is_equal_approx(_displayed_progress, progress) and not _continue_enabled:
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


func _update_loading_crackle(delta: float) -> void:
	if loading_bar_back == null or loading_bar_fill == null or _displayed_progress <= 0.02:
		_clear_loading_crackle()
		return
	_crackle_interval_remaining -= delta
	if _crackle_interval_remaining <= 0.0:
		_crackle_remaining = 0.12
		_crackle_interval_remaining = _rng.randf_range(0.08, 0.2)
	if _crackle_remaining <= 0.0:
		_clear_loading_crackle()
		return
	_crackle_remaining = max(_crackle_remaining - delta, 0.0)
	var crackle: Line2D = loading_bar_back.get_node_or_null("LoadingCrackle") as Line2D
	if crackle == null:
		crackle = Line2D.new()
		crackle.name = "LoadingCrackle"
		crackle.antialiased = true
		loading_bar_back.add_child(crackle)
	var alpha: float = clamp(_crackle_remaining / 0.12, 0.0, 1.0)
	crackle.default_color = Color(1.0, 1.0, 1.0, 0.35 + alpha * 0.65)
	crackle.width = 1.2 + alpha * 1.8
	crackle.points = _build_loading_crackle_points(Rect2(loading_bar_fill.position, loading_bar_fill.size))


func _build_loading_crackle_points(fill_rect: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var point_count := 7
	var start_x: float = fill_rect.position.x + 2.0
	var end_x: float = fill_rect.position.x + max(fill_rect.size.x - 2.0, 2.0)
	var center_y: float = fill_rect.position.y + fill_rect.size.y * 0.5
	var amplitude: float = max(fill_rect.size.y * 0.38, 2.0)
	for index in range(point_count):
		var ratio: float = float(index) / float(point_count - 1)
		var x: float = lerp(start_x, end_x, ratio)
		var y: float = center_y
		if index > 0 and index < point_count - 1:
			y += _rng.randf_range(-amplitude, amplitude)
		points.append(Vector2(x, y))
	return points


func _clear_loading_crackle() -> void:
	if loading_bar_back == null:
		return
	var crackle := loading_bar_back.get_node_or_null("LoadingCrackle")
	if crackle != null:
		crackle.queue_free()


func _update_ready_glow() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_glow_time * TAU * ready_glow_speed)
	var glow_mix: float = lerp(ready_glow_min_mix, ready_glow_max_mix, pulse)
	var font_color := ready_glow_base_color.lerp(ready_glow_peak_color, glow_mix)
	var shadow_alpha: float = lerp(ready_glow_shadow_min_alpha, ready_glow_shadow_max_alpha, pulse)
	var shadow_color := Color(ready_glow_shadow_color.r, ready_glow_shadow_color.g, ready_glow_shadow_color.b, shadow_alpha)
	var outline_size: int = roundi(lerp(float(ready_glow_shadow_min_outline), float(ready_glow_shadow_max_outline), pulse))
	for label in [status_label, continue_label]:
		if label == null:
			continue
		if label.label_settings != null:
			label.label_settings.font_color = font_color
			label.label_settings.shadow_color = shadow_color
			label.label_settings.shadow_size = outline_size
			label.label_settings.shadow_offset = Vector2.ZERO
		label.add_theme_color_override("font_color", font_color)
		label.add_theme_color_override("font_shadow_color", shadow_color)
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 0)
		label.add_theme_constant_override("shadow_outline_size", outline_size)


func _clear_ready_glow() -> void:
	_restore_label_settings(status_label, _status_base_label_settings)
	_restore_label_settings(continue_label, _continue_base_label_settings)
	for label in [status_label, continue_label]:
		if label == null:
			continue
		label.remove_theme_color_override("font_color")
		label.remove_theme_color_override("font_shadow_color")
		label.remove_theme_constant_override("shadow_offset_x")
		label.remove_theme_constant_override("shadow_offset_y")
		label.remove_theme_constant_override("shadow_outline_size")


func _prepare_runtime_label_settings() -> void:
	_status_base_label_settings = _duplicate_label_settings(status_label)
	_continue_base_label_settings = _duplicate_label_settings(continue_label)


func _duplicate_label_settings(label: Label) -> LabelSettings:
	if label == null or label.label_settings == null:
		return null
	var settings: LabelSettings = label.label_settings.duplicate(true)
	label.label_settings = settings
	return settings.duplicate(true)


func _restore_label_settings(label: Label, base_settings: LabelSettings) -> void:
	if label == null or base_settings == null:
		return
	var settings: LabelSettings = base_settings.duplicate(true)
	label.label_settings = settings


func _update_continue_prompt() -> void:
	if continue_label != null:
		continue_label.visible = _continue_enabled


func _clear_title_text() -> void:
	if title_label != null:
		title_label.text = ""
